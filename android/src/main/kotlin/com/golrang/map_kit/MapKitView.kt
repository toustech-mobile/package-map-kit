@file:Suppress("DEPRECATION")

package com.golrang.map_kit

import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import androidx.core.view.doOnLayout
import com.golrang.map_kit.helpers.*
import com.golrang.map_kit.models.MyCircle
import com.golrang.map_kit.models.MyPolyline
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.maplibre.android.MapLibre
import org.maplibre.android.annotations.Marker
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style
import java.util.ArrayDeque

internal class MapKitView(
    private val context: Context,
    private val viewId: Int,
    params: Map<*, *>?,
    savedState: Bundle?,
    private val sendEvent: (Map<String, Any?>) -> Unit,
    private val onDisposed: (MapKitView) -> Unit,
) : PlatformView {
    private data class MarkerEntry(val spec: Map<*, *>, val marker: Marker)
    private data class CircleEntry(val spec: Map<*, *>, val circle: MyCircle)
    private data class LineEntry(val spec: Map<*, *>, val line: MyPolyline)

    private val creation = params ?: emptyMap<String, Any?>()
    private val layout: FrameLayout
    private val mapView: MapView
    private var map: MapLibreMap? = null
    private var ready = false
    private var disposed = false
    private var started = false
    private var resumed = false
    private var initialized = false
    private var styleFailed = false
    private var activeStyleResult: MethodChannel.Result? = null
    private val pending = ArrayDeque<Pair<MethodCall, MethodChannel.Result>>()
    private val markers = mutableListOf<MarkerEntry>()
    private val circles = mutableListOf<CircleEntry>()
    private val lines = mutableListOf<LineEntry>()
    private var userSpec: Map<*, *>? = null
    private var userMarker: Marker? = null
    private var userAccuracy: MyCircle? = null

    init {
        // Validate creation inputs synchronously so Flutter receives a view-creation
        // error rather than an exception escaping an asynchronous SDK callback.
        val center = (creation["initialCenter"] as? Map<*, *>)?.coordinate()
            ?: LatLng(35.6892, 51.3890)
        val zoom = creation.number("zoom", 13.0)
        val metadata = context.packageManager.getApplicationInfo(
            context.packageName, PackageManager.GET_META_DATA).metaData
        require(!metadata?.getString("org.maplibre.android.API_KEY").isNullOrBlank()) {
            "Set org.maplibre.android.API_KEY in the host AndroidManifest.xml. " +
                "The legacy neshan.license is not used by MapLibre."
        }
        MapLibre.getInstance(context)
        layout = LayoutInflater.from(context).inflate(R.layout.my_activity, null) as FrameLayout
        mapView = layout.findViewById(R.id.map)
        mapView.onCreate(savedState)
        mapView.addOnDidFailLoadingMapListener {
            if (!disposed && !ready) {
                styleFailed = true
                activeStyleResult?.error("STYLE_LOAD_FAILED",
                    "Could not load Neshan style; check the API key and network", null)
                activeStyleResult = null
                failPending("STYLE_LOAD_FAILED", "Could not load Neshan style")
            }
        }
        mapView.getMapAsync { nativeMap ->
            if (!disposed) {
                map = nativeMap
                if (savedState == null) nativeMap.moveCamera(CameraUpdateFactory.newLatLngZoom(
                    center, zoom))
                installCallbacks(nativeMap)
                loadStyle(creation["isDarkMode"] as? Boolean ?: false)
            }
        }
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method !in METHODS) {
            result.notImplemented()
        } else if (disposed) {
            result.error("MAP_DISPOSED", "The map has been disposed", null)
        } else if (styleFailed && call.method == "setMapStyle" && map != null) {
            execute(call, result)
        } else if (styleFailed) {
            result.error("STYLE_LOAD_FAILED", "Retry setMapStyle after checking API key/network", null)
        } else if (!ready) {
            pending.add(call to result)
        } else {
            execute(call, result)
        }
    }

    private fun execute(call: MethodCall, result: MethodChannel.Result) {
        val nativeMap = map ?: return result.error("MAP_NOT_READY", "Map is not ready", null)
        try {
            when (call.method) {
                "getCamera" -> {
                    val camera = nativeMap.cameraPosition
                    val target = camera.target ?: LatLng(35.6892, 51.3890)
                    result.success(mapOf("zoom" to camera.zoom,
                        "latitude" to target.latitude, "longitude" to target.longitude))
                    return
                }
                "addMarkers" -> addMarkers(call.arguments.mapList())
                "removeMarkers" -> call.arguments.mapList().forEach { spec ->
                    markers.firstOrNull { it.marker.position == spec.coordinate() }?.let {
                        nativeMap.removeMarker(it.marker)
                        markers.remove(it)
                    }
                }
                "removeAllMarkers" -> {
                    markers.forEach { nativeMap.removeMarker(it.marker) }
                    markers.clear()
                }
                "addCircles" -> addCircles(call.arguments.mapList())
                "removeCircles" -> call.arguments.mapList().forEach { spec ->
                    circles.firstOrNull { it.circle.center == spec.coordinate() }?.let {
                        CircleHelper.remove(nativeMap, it.circle)
                        circles.remove(it)
                    }
                }
                "removeAllCircles" -> {
                    circles.forEach { CircleHelper.remove(nativeMap, it.circle) }
                    circles.clear()
                }
                "addPolyLines" -> addLines(call.arguments.mapList())
                "removePolyLines" -> call.arguments.mapList().forEach { spec ->
                    val point = spec["points"].mapList().firstOrNull()?.coordinate()
                    lines.firstOrNull { it.line.polyline.points.firstOrNull() == point }?.let {
                        PolyLineHelper.remove(nativeMap, it.line)
                        lines.remove(it)
                    }
                }
                "removeAllPolyLines" -> {
                    lines.forEach { PolyLineHelper.remove(nativeMap, it.line) }
                    lines.clear()
                }
                "setUserMarker" -> {
                    val spec = requireNotNull(call.arguments as? Map<*, *>)
                    spec.coordinate()
                    require(spec.number("accuracy") >= 0) { "accuracy must be non-negative" }
                    userSpec = spec
                    renderUser()
                }
                "moveCamera" -> {
                    val spec = requireNotNull(call.arguments as? Map<*, *>)
                    nativeMap.animateCamera(CameraUpdateFactory.newLatLngZoom(
                        spec.coordinate(), spec.number("zoom", nativeMap.cameraPosition.zoom)), 500)
                }
                "fitBounds" -> {
                    fitBounds(requireNotNull(call.arguments as? Map<*, *>), result)
                    return
                }
                "setMapStyle" -> {
                    val spec = requireNotNull(call.arguments as? Map<*, *>)
                    loadStyle(requireNotNull(spec["isDarkMode"] as? Boolean), result)
                    return
                }
            }
            result.success(null)
        } catch (error: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", error.message, null)
        } catch (_: Exception) {
            result.error("MAP_OPERATION_FAILED", "Neshan map operation failed: " + call.method, null)
        }
    }

    private fun loadStyle(dark: Boolean, result: MethodChannel.Result? = null) {
        ready = false
        styleFailed = false
        activeStyleResult = result
        val url = if (dark) DARK_STYLE else LIGHT_STYLE
        map!!.setStyle(Style.Builder().fromUri(url)) {
            if (!disposed) {
                try {
                    if (!initialized) {
                        // First style load: creation data has not been rendered yet.
                        addCircles((creation["circles"] ?: emptyList<Any>()).mapList())
                        addLines((creation["polyLines"] ?: emptyList<Any>()).mapList())
                        addMarkers((creation["markers"] ?: emptyList<Any>()).mapList())
                        initialized = true
                    } else {
                        // Recreate owned annotations after a style replacement, exactly once.
                        val markerSpecs = markers.map { it.spec }
                        val circleSpecs = circles.map { it.spec }
                        val lineSpecs = lines.map { it.spec }
                        map!!.clear()
                        markers.clear()
                        circles.clear()
                        lines.clear()
                        userMarker = null
                        userAccuracy = null
                        addCircles(circleSpecs)
                        addLines(lineSpecs)
                        addMarkers(markerSpecs)
                    }
                    renderUser()
                    ready = true
                    activeStyleResult?.success(null)
                    activeStyleResult = null
                    while (ready && pending.isNotEmpty()) {
                        val (call, queuedResult) = pending.removeFirst()
                        execute(call, queuedResult)
                    }
                } catch (_: Exception) {
                    styleFailed = true
                    activeStyleResult?.error("MAP_INITIALIZATION_FAILED",
                        "Could not initialize map overlays; check creation parameters", null)
                    activeStyleResult = null
                    failPending("MAP_INITIALIZATION_FAILED", "Could not initialize map overlays")
                }
            }
        }
    }

    private fun addMarkers(specs: List<Map<*, *>>) {
        val nativeMap = map!!
        // Parse all options before changing native state.
        val options = specs.map { MarkerHelper.options(context, it) }
        val added = nativeMap.addMarkers(options)
        markers.addAll(specs.zip(added).map { (spec, marker) -> MarkerEntry(spec, marker) })
        if (userMarker != null) renderUser()
    }

    private fun addCircles(specs: List<Map<*, *>>) {
        specs.forEach { circles.add(CircleEntry(it, CircleHelper.add(map!!, it))) }
    }

    private fun addLines(specs: List<Map<*, *>>) {
        specs.forEach { lines.add(LineEntry(it, PolyLineHelper.add(map!!, it))) }
    }

    private fun renderUser() {
        val spec = userSpec ?: return
        val nativeMap = map!!
        userMarker?.let(nativeMap::removeMarker)
        userAccuracy?.let { CircleHelper.remove(nativeMap, it) }
        userAccuracy = CircleHelper.add(nativeMap, mapOf(
            "latitude" to spec.number("latitude"), "longitude" to spec.number("longitude"),
            "radius" to spec.number("accuracy"), "borderStroke" to 1.0,
            "color" to "#403399FF", "borderColor" to "#FF3399FF"))
        userMarker = nativeMap.addMarker(MarkerHelper.options(context, mapOf(
            "latitude" to spec.number("latitude"), "longitude" to spec.number("longitude"),
            "icon" to "current_location.svg", "iconSize" to 24)))
    }

    private fun fitBounds(spec: Map<*, *>, result: MethodChannel.Result) {
        val points = spec["points"].mapList().map { it.coordinate() }
        val padding = spec.number("padding", 24.0)
        require(padding >= 0) { "padding must be non-negative" }
        if (points.isEmpty()) { result.success(null); return }
        mapView.doOnLayout {
            if (disposed) result.error("MAP_DISPOSED", "The map has been disposed", null)
            else try {
                val update = if (points.distinct().size == 1) CameraUpdateFactory.newLatLngZoom(
                    points.first(), map!!.cameraPosition.zoom)
                else {
                    val maxPadding = (minOf(mapView.width, mapView.height) - 1).coerceAtLeast(0) / 2
                    val pixels = (padding * context.resources.displayMetrics.density)
                        .coerceAtMost(maxPadding.toDouble()).toInt()
                    CameraUpdateFactory.newLatLngBounds(
                        LatLngBounds.Builder().includes(points).build(), pixels)
                }
                map!!.animateCamera(update, 500)
                result.success(null)
            } catch (_: Exception) {
                result.error("BOUNDS_FAILED", "Could not fit the requested bounds", null)
            }
        }
    }

    private fun installCallbacks(nativeMap: MapLibreMap) {
        nativeMap.addOnMapLongClickListener { point ->
            emit("onMapLongPress", point)
            true
        }
        nativeMap.setOnMarkerClickListener { marker ->
            val entry = markers.firstOrNull { it.marker.id == marker.id }
            if (entry != null) {
                if (!marker.title.isNullOrEmpty() || !marker.snippet.isNullOrEmpty())
                    marker.showInfoWindow(nativeMap, mapView)
                emit("onMarkerTap", marker.position, entry.spec["data"]?.toString() ?: "")
            }
            true
        }
        nativeMap.addOnMapClickListener { point ->
            val circle = circles.firstOrNull {
                MapGeometry.distanceMeters(it.circle.center, point) <= it.circle.radius
            }?.circle
            if (circle != null) {
                emit("onCircleTap", circle.center, circle.data)
            } else {
                val projection = nativeMap.projection
                val tap = projection.toScreenLocation(point)
                val tolerance = 30 * context.resources.displayMetrics.density
                val line = lines.firstOrNull { entry ->
                    entry.line.polyline.points.zipWithNext().any { (a, b) ->
                        val from = projection.toScreenLocation(a)
                        val to = projection.toScreenLocation(b)
                        MapGeometry.segmentDistance(tap.x.toDouble(), tap.y.toDouble(),
                            from.x.toDouble(), from.y.toDouble(), to.x.toDouble(), to.y.toDouble()) <= tolerance
                    }
                }
                if (line != null) emit("onPolylineTap", null, line.line.data)
                else emit("onMapTap", point)
            }
            true
        }
    }

    private fun emit(event: String, point: LatLng?, data: String? = null) {
        if (disposed) return
        val payload = mutableMapOf<String, Any?>(
            "latitude" to point?.latitude, "longitude" to point?.longitude)
        if (data != null) payload["data"] = data
        sendEvent(mapOf("event" to event, "data" to payload))
    }

    private fun failPending(code: String, message: String) {
        while (pending.isNotEmpty()) pending.removeFirst().second.error(code, message, null)
    }

    fun onStart() {
        if (!disposed && !started) { mapView.onStart(); started = true }
    }
    fun onResume() {
        if (!disposed && !resumed) { onStart(); mapView.onResume(); resumed = true }
    }
    fun onPause() {
        if (!disposed && resumed) { mapView.onPause(); resumed = false }
    }
    fun onStop() {
        onPause()
        if (!disposed && started) { mapView.onStop(); started = false }
    }
    fun onLowMemory() { if (!disposed) mapView.onLowMemory() }
    fun saveState(state: Bundle) {
        if (!disposed) {
            val viewState = Bundle()
            mapView.onSaveInstanceState(viewState)
            state.putBundle("map_kit_view_$viewId", viewState)
        }
    }
    override fun getView(): View = layout
    override fun dispose() {
        if (disposed) return
        onStop()
        disposed = true
        ready = false
        failPending("MAP_DISPOSED", "The map has been disposed")
        activeStyleResult?.error("MAP_DISPOSED", "The map has been disposed", null)
        activeStyleResult = null
        mapView.onDestroy()
        markers.clear()
        circles.clear()
        lines.clear()
        map = null
        onDisposed(this)
    }

    companion object {
        private const val LIGHT_STYLE = "https://static.neshan.org/sdk/maplibre/styles/light.json"
        private const val DARK_STYLE = "https://static.neshan.org/sdk/maplibre/styles/dark.json"
        private val METHODS = setOf("addMarkers", "removeMarkers", "removeAllMarkers",
            "addCircles", "removeCircles", "removeAllCircles", "addPolyLines",
            "removePolyLines", "removeAllPolyLines", "setUserMarker", "moveCamera",
            "fitBounds", "setMapStyle", "getCamera")
    }
}
