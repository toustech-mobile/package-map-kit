package com.golrang.map_kit

import android.content.Context
import android.content.pm.PackageManager

internal object NeshanConfiguration {
    const val ERROR_CODE = "NESHAN_API_KEY_MISSING"
    const val ERROR_MESSAGE = "The package Neshan API key is missing. " +
        "Set map_kit_neshan_api_key in map_kit/android/src/main/res/values/neshan_configuration.xml. " +
        "The package manifest supplies org.maplibre.android.API_KEY automatically. " +
        "Stop the app and perform a full Android rebuild after updating the package."

    fun validate(context: Context) {
        val metadata = context.packageManager.getApplicationInfo(
            context.packageName, PackageManager.GET_META_DATA).metaData
        require(!metadata?.getString("org.maplibre.android.API_KEY").isNullOrBlank()) {
            ERROR_MESSAGE
        }
    }
}
