package com.golrang.map_kit

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Bundle
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import org.mockito.Mockito

internal class NeshanConfigurationTest {
    private fun contextWithKey(key: String?): Context {
        val context = Mockito.mock(Context::class.java)
        val manager = Mockito.mock(PackageManager::class.java)
        val info = Mockito.mock(ApplicationInfo::class.java)
        val metadata = Mockito.mock(Bundle::class.java)
        info.metaData = metadata
        Mockito.`when`(context.packageName).thenReturn("test.host")
        Mockito.`when`(context.packageManager).thenReturn(manager)
        Mockito.`when`(manager.getApplicationInfo("test.host", PackageManager.GET_META_DATA))
            .thenReturn(info)
        Mockito.`when`(metadata.getString("org.maplibre.android.API_KEY")).thenReturn(key)
        return context
    }

    @Test
    fun missingOrBlankKeyExplainsPackageConfiguration() {
        for (key in listOf(null, "", "   ")) {
            val error = assertFailsWith<IllegalArgumentException> {
                NeshanConfiguration.validate(contextWithKey(key))
            }
            assertEquals(NeshanConfiguration.ERROR_MESSAGE, error.message)
        }
    }

    @Test
    fun mergedPackageMapLibreKeyPassesValidation() {
        NeshanConfiguration.validate(contextWithKey("test-key"))
    }
}
