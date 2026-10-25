package com.golrang.map_kit

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class MapKitPluginTest {
  @Test
  fun mapCommandWithoutAttachedViewReturnsAnError() {
    val plugin = MapKitPlugin()
    val result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(MethodCall("addMarkers", emptyList<Any>()), result)
    Mockito.verify(result).error("MAP_NOT_ATTACHED", "No Neshan map is attached", null)
  }

  @Test
  fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
    val plugin = MapKitPlugin()

    val call = MethodCall("getPlatformVersion", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }
}
