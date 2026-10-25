package com.golrang.map_kit

import android.app.Activity
import android.app.Application
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Keeps the existing Flutter wire protocol while using Neshan's MapLibre SDK. */
class MapKitPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware, Application.ActivityLifecycleCallbacks,
    ComponentCallbacks2 {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var application: Application
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null
    private val views = linkedSetOf<MapKitView>()
    private var restoredState: Bundle? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        application = binding.applicationContext as Application
        application.registerActivityLifecycleCallbacks(this)
        application.registerComponentCallbacks(this)
        methodChannel = MethodChannel(binding.binaryMessenger, "com.example.example/method_channel")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.yourapp/event_channel")
        eventChannel.setStreamHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "com.example.example/map_kit_view",
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                    val view = MapKitView(context, viewId, args as? Map<*, *>,
                        restoredState?.getBundle("map_kit_view_$viewId"),
                        { event -> eventSink?.success(event) },
                        { disposed -> views.remove(disposed) })
                    views.add(view)
                    if (activity != null) {
                        view.onStart()
                        view.onResume()
                    }
                    return view
                }
            })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android " + android.os.Build.VERSION.RELEASE)
            return
        }
        // The legacy Dart channel is global. Keep its last-created-view routing.
        val view = views.lastOrNull()
        if (view == null) result.error("MAP_NOT_ATTACHED", "No Neshan map is attached", null)
        else view.handleMethodCall(call, result)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
    override fun onCancel(arguments: Any?) { eventSink = null }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        views.toList().forEach { it.dispose() }
        application.unregisterActivityLifecycleCallbacks(this)
        application.unregisterComponentCallbacks(this)
        activity = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        views.forEach { it.onStart(); it.onResume() }
    }

    override fun onDetachedFromActivity() {
        views.forEach { it.onPause(); it.onStop() }
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onActivityCreated(activity: Activity, state: Bundle?) {
        if (activity === this.activity) restoredState = state
    }
    override fun onActivityStarted(activity: Activity) {
        if (activity === this.activity) views.forEach { it.onStart() }
    }
    override fun onActivityResumed(activity: Activity) {
        if (activity === this.activity) views.forEach { it.onResume() }
    }
    override fun onActivityPaused(activity: Activity) {
        if (activity === this.activity) views.forEach { it.onPause() }
    }
    override fun onActivityStopped(activity: Activity) {
        if (activity === this.activity) views.forEach { it.onStop() }
    }
    override fun onActivitySaveInstanceState(activity: Activity, state: Bundle) {
        if (activity === this.activity) views.forEach { it.saveState(state) }
    }
    override fun onActivityDestroyed(activity: Activity) {
        if (activity === this.activity) {
            views.toList().forEach { it.dispose() }
            this.activity = null
        }
    }
    override fun onConfigurationChanged(configuration: Configuration) = Unit
    override fun onLowMemory() { views.forEach { it.onLowMemory() } }
    override fun onTrimMemory(level: Int) {
        if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) onLowMemory()
    }
}
