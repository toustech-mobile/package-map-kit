package com.golrang.map_kit

import android.content.Context
import android.location.Location
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import androidx.annotation.NonNull
import com.golrang.map_kit.MapKitPlugin.Companion.callBackChannel
import com.golrang.map_kit.MapKitPlugin.Companion.mapKitView
import com.golrang.map_kit.helpers.CircleHelper
import com.golrang.map_kit.helpers.MarkerHelper
import com.golrang.map_kit.helpers.PolyLineHelper
import com.golrang.map_kit.models.MyCircle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.MapView
import org.neshan.mapsdk.model.Marker
import org.neshan.mapsdk.model.Polyline
import org.neshan.mapsdk.style.NeshanMapStyle

class MapKitPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        lateinit var callBackChannel: MethodChannel
        lateinit var methodChannel: MethodChannel
        lateinit var mapKitView: MapKitView
    }

    lateinit var binding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {

        this.binding = binding

        callBackChannel =
            MethodChannel(binding.binaryMessenger, "com.example.example/callback_channel")
        methodChannel = MethodChannel(binding.binaryMessenger, "com.example.example/method_channel")

        callBackChannel.setMethodCallHandler(this)
        methodChannel.setMethodCallHandler(this)

        binding.platformViewRegistry.registerViewFactory(
            "com.example.example/map_kit_view", MapKitViewFactory()
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        callBackChannel.setMethodCallHandler(null)
        mapKitView.dispose()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addMarkers" -> {
                handleAddMarkers(call, result)
            }

            "removeMarkers" -> {
                handleRemoveMarkers(call, result)
            }

            "addCircles" -> {
                handleAddCircles(call, result)
            }

            "removeCircles" -> {
                handleRemoveCircles(call, result)
            }

            "addPolyLines" -> {
                handleAddPolyLines(call, result)
            }

//            "removePolyLines" -> {
//                handleRemovePolyLines(call, result)
//            }
            "setUserMarker" -> {
                handleSetUserMarker(call, result)
            }


            else -> {
                result.notImplemented()
            }
        }
    }


    private fun handleAddMarkers(call: MethodCall, result: MethodChannel.Result) {
        Log.d("Native Add Markers", "")
        mapKitView.addMarkers(call.arguments as List<*>)

        result.success("Marker added successfully")
    }

    private fun handleRemoveMarkers(call: MethodCall, result: MethodChannel.Result) {
        Log.d("Native Remove Markers", "")
        mapKitView.removeMarkers(call.arguments as List<*>)

        result.success("Marker removed successfully")
    }

    private fun handleAddCircles(call: MethodCall, result: MethodChannel.Result) {
        Log.d("Native Add Circles", "")
        mapKitView.addCircles(call.arguments as List<*>)

        result.success("Circles added successfully")
    }

    private fun handleRemoveCircles(call: MethodCall, result: MethodChannel.Result) {
        Log.d("Native Remove Circles", "")
        mapKitView.removeCircles(call.arguments as List<*>)

        result.success("Circles removed successfully")
    }

    private fun handleAddPolyLines(call: MethodCall, result: MethodChannel.Result) {
        Log.d("Native Add PolyLines", "")
        mapKitView.addPolyLines(call.arguments as List<*>)

        result.success("PolyLines added successfully")
    }

    private fun handleSetUserMarker(call: MethodCall, result: MethodChannel.Result) {
        Log.d("Native SetUserMarker", "")

        mapKitView.setUserMarker(call.arguments as Map<String, *>)
        result.success("SetUserMarker set successfully")
    }
//
//    private fun handleRemovePolyLines(call: MethodCall, result: MethodChannel.Result) {
//        Log.d("Native Remove PolyLines", "")
//        mapKitView.removeCircles(call.arguments as List<*>)
//
//        result.success("PolyLines removed successfully")
//    }

}

class MapKitViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>

        mapKitView = MapKitView(context, params)
        return mapKitView
    }
}

class MapKitView(private val context: Context, params: Map<String, Any>?) : PlatformView {
    private lateinit var mapView: MapView
    private var defaultZoom: Float = 12.0f
    private var markers: MutableList<Marker> = mutableListOf()
    private var circles: MutableList<MyCircle> = mutableListOf()
    private var polyLines: MutableList<Polyline> = mutableListOf()

    private val layout: LinearLayout =
        LayoutInflater.from(context).inflate(R.layout.my_activity, null) as LinearLayout

    init {
        initLayoutReferences()

        setInitialCenter(params)
        setDefaultZoom(params)
        setMapStyle(params)
        addMarkers(params!!["markers"] as List<*>)
        addCircles(params["circles"] as List<*>)
        addPolyLines(params["polyLines"] as List<*>)

    }

    private fun setInitialCenter(params: Map<String, Any>?) {
        val initialCenter = params?.get("initialCenter") as Map<*, *>
        Log.d("Native InitialCenter", initialCenter.toString())

        mapView.moveCamera(
            LatLng(
                initialCenter["latitude"] as Double, initialCenter["longitude"] as Double
            ), 0f
        )

        mapView.setZoom(defaultZoom, 0f)
    }

    private fun setDefaultZoom(params: Map<String, Any>?) {
        val zoom = params?.get("zoom") as Double
        Log.d("setDefaultZoom", zoom.toString())

        defaultZoom = zoom.toFloat()
        mapView.setZoom(defaultZoom, 0f)
    }


    private fun setMapStyle(params: Map<String, Any>?) {
        val isDarkMode: Boolean = params?.get("isDarkMode") as Boolean
        Log.d("Native isDarkMode", isDarkMode.toString())

        if (isDarkMode) {
            mapView.setMapStyle(NeshanMapStyle.NESHAN_NIGHT)
        } else {
            mapView.setMapStyle(NeshanMapStyle.STANDARD_DAY)
        }
    }


    fun addMarkers(rawData: List<*>) {
        val markers = MarkerHelper.toNeshanModel(context, rawData)
        Log.d("Native Markers", markers.toString())

        this.markers.addAll(markers)
        mapView.addMarkers(markers)

    }

    fun removeMarkers(rawData: List<*>) {
        rawData.forEach {
            val arguments = it as? Map<*, *>
            val latitude = (arguments?.get("latitude") as? Double) ?: 0.0
            val longitude = (arguments?.get("longitude") as? Double) ?: 0.0

            val marker = this.markers.find {
                it.latLng.latitude == latitude && it.latLng.longitude == longitude
            }
            if (marker != null) {
                this.markers.remove(marker)
                mapView.removeMarker(marker)
            }
        }
        mapView.setZoom(mapView.zoom, 0f)
    }

    fun addCircles(rawCircles: List<*>) {
        val circles = CircleHelper.toNeshanModel(rawCircles, context)
        Log.d("Native Circles", rawCircles.toString())

        this.circles.addAll(circles)
        circles.forEach {
            mapView.addCircle(it.circle)
            mapView.addMarker(it.centerMarker)
        }
    }

    fun removeCircles(rawData: List<*>) {
        rawData.forEach {
            val arguments = it as? Map<*, *>
            val latitude = (arguments?.get("latitude") as? Double) ?: 0.0
            val longitude = (arguments?.get("longitude") as? Double) ?: 0.0

            val circle = this.circles.find {
                it.latitude == latitude && it.longitude == longitude
            }

            if (circle != null) {
                this.circles.remove(circle)
                mapView.removeCircle(circle.circle)
            }
        }
        mapView.setZoom(mapView.zoom, 0f)
    }

    fun addPolyLines(rawPolyLines: List<*>) {
        val polyLines = PolyLineHelper.toNeshanModel(rawPolyLines)
        Log.d("Native PolyLines", rawPolyLines.toString())

        this.polyLines.addAll(polyLines)
        polyLines.forEach {
            mapView.addPolyline(it)
        }
    }

    fun setUserMarker(rawPolyLines: Map<String, *>) {
        val latitude = rawPolyLines["latitude"] as Double
        val longitude = rawPolyLines["longitude"] as Double
        val accuracy = rawPolyLines["accuracy"] as Double

        val location = Location("my_native_provider")
        location.latitude = latitude
        location.longitude = longitude
        location.altitude = 1200.0
        location.accuracy = accuracy.toFloat()
        location.time = System.currentTimeMillis()
        location.speed = 0.0f

        mapView.showAccuracyCircle(location)

        val marker = MarkerHelper.createMarker(
            LatLng(latitude, longitude), "", "current_location.svg", 24, "", "", context,
        )

        mapView.addMarker(
            marker
        )
    }


    private fun initLayoutReferences() {
        initViews()

        mapView.setOnMapLongClickListener { latLng ->
            sendOnMapLongClickCallbackToFlutter(latLng)
        }

        mapView.setOnMapClickListener { latLng ->
            sendOnMapClickCallbackToFlutter(latLng)
        }

        mapView.setOnMarkerClickListener { marker: Marker ->
            if (!marker.title.isNullOrEmpty() || !marker.description.isNullOrEmpty()) {
                marker.showInfoWindow()
            }

            val circleMarker = circles.find { myCircle ->
                myCircle.centerMarker == marker
            }

            if (circleMarker != null) {
                sendOnCircleClickCallbackToFlutter(marker.getMetadata("data"))
            } else {
                sendOnMarkerClickCallbackToFlutter(marker.getMetadata("data"))
            }
            mapView.setZoom(mapView.zoom, 0f)
        }
    }

    private fun initViews() {
        mapView = layout.findViewById(R.id.map)
    }

    private fun sendOnMapClickCallbackToFlutter(point: LatLng) {
        val pointMap = mapOf(
            "latitude" to point.latitude, "longitude" to point.longitude
        )

        Handler(Looper.getMainLooper()).post {
            callBackChannel?.invokeMethod("onMapTap", pointMap)
        }
    }

    private fun sendOnMapLongClickCallbackToFlutter(point: LatLng) {
        val pointMap = mapOf(
            "latitude" to point.latitude, "longitude" to point.longitude
        )

        Handler(Looper.getMainLooper()).post {
            callBackChannel?.invokeMethod("onMapLongPress", pointMap)
        }
    }

    private fun sendOnMarkerClickCallbackToFlutter(data: String) {
        Handler(Looper.getMainLooper()).post {
            callBackChannel?.invokeMethod("onMarkerTap", data)
        }
    }

    private fun sendOnCircleClickCallbackToFlutter(data: String) {
        Handler(Looper.getMainLooper()).post {
            callBackChannel?.invokeMethod("onCircleTap", data)
        }
    }

    override fun getView(): View {
        return layout
    }

    override fun dispose() {
        // Clean-up resources if needed
    }
}
