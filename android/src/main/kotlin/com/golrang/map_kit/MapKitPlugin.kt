package com.golrang.map_kit

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import androidx.annotation.NonNull
import com.golrang.map_kit.MapKitPlugin.Companion.callBackChannel
import com.golrang.map_kit.MapKitPlugin.Companion.mapKitView
import com.golrang.map_kit.MarkerHelper.Companion.createMarker
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.MapView
import org.neshan.mapsdk.model.Marker
import org.neshan.mapsdk.style.NeshanMapStyle

class MapKitPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        lateinit var callBackChannel: MethodChannel
        lateinit var methodChannel: MethodChannel
        lateinit var mapKitView: MapKitView
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {

        callBackChannel =
            MethodChannel(binding.binaryMessenger, "com.golrang.map_kit/callback_channel")
        methodChannel = MethodChannel(binding.binaryMessenger, "com.golrang.map_kit/method_channel")

        callBackChannel.setMethodCallHandler(this)
        methodChannel.setMethodCallHandler(this)

        binding.platformViewRegistry.registerViewFactory(
            "com.golrang.map_kit/map_kit_view",
            MapKitViewFactory()
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        callBackChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addMarker" -> {
                handleAddMarker(call, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleAddMarker(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<String, Any>

        val latitude = (arguments?.get("latitude") as? Double) ?: 0.0
        val longitude = (arguments?.get("longitude") as? Double) ?: 0.0
        val data = arguments?.get("data") as? String ?: ""

        mapKitView.addMarker(
            LatLng(latitude, longitude),
            data
        )

        result.success("Marker added successfully")
    }
}

class MapKitViewFactory :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>

        mapKitView = MapKitView(context, params)
        return mapKitView
    }
}

class MapKitView(private val context: Context, params: Map<String, Any>?) :
    PlatformView {
    private lateinit var mapView: MapView

    private val layout: LinearLayout =
        LayoutInflater.from(context).inflate(R.layout.my_activity, null) as LinearLayout

    init {
        initLayoutReferences()

        setInitialCenter(params)
        setMapStyle(params)
        addMarkers(context, params)
    }

    private fun setInitialCenter(params: Map<String, Any>?) {
        val initialCenter = params?.get("initialCenter") as Map<*, *>
        Log.d("Native InitialCenter", initialCenter.toString())

        mapView.moveCamera(
            LatLng(
                initialCenter["latitude"] as Double,
                initialCenter["longitude"] as Double
            ), 0f
        )
        mapView.setZoom(14f, 0f)
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

    private fun addMarkers(context: Context, params: Map<String, Any>?) {
        val markers = params?.get("markers")
        Log.d("Native Markers", markers.toString())

        MarkerHelper.toNeshanModel(context, markers!!).forEach {
            mapView.addMarker(it)
        }
    }

    fun addMarker(point: LatLng, data: Any) {
        mapView.addMarker(createMarker(point, data, context))
    }

    private fun initLayoutReferences() {
        initViews()

//        // when long clicked on map, a marker is added in clicked location
//        mapView.setOnMapLongClickListener {
//            mapView.addMarker(createMarker(it, context))
//        }

        mapView.setOnMapClickListener { latLng ->
            sendOnMapClickCallbackToFlutter(latLng)
        }

        mapView.setOnMarkerClickListener { marker: Marker ->
            sendOnMarkerClickCallbackToFlutter(marker.getMetadata("data"))
        }
    }

    private fun initViews() {
        mapView = layout.findViewById(R.id.map)
    }

    private fun sendOnMapClickCallbackToFlutter(point: LatLng) {
        val pointMap = mapOf(
            "latitude" to point.latitude,
            "longitude" to point.longitude
        )

        Handler(Looper.getMainLooper()).post {
            callBackChannel?.invokeMethod("onMapTap", pointMap)
        }
    }

    private fun sendOnMarkerClickCallbackToFlutter(data: String) {
        Handler(Looper.getMainLooper()).post {
            callBackChannel?.invokeMethod("onMarkerTap", data)
        }
    }

    override fun getView(): View {
        return layout
    }

    override fun dispose() {
        // Clean-up resources if needed
    }
}
