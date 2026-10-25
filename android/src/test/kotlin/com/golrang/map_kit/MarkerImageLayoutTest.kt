package com.golrang.map_kit

import com.golrang.map_kit.helpers.MarkerImageLayout
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MarkerImageLayoutTest {
    @Test
    fun markerAndContentImagesRetainTheirAspectRatios() {
        // Portrait tour pin, landscape branch, and square location artwork.
        assertEquals(64 to 88, MarkerImageLayout.fit(32, 44, 88))
        assertEquals(66 to 44, MarkerImageLayout.fit(66, 44, 66))
        assertEquals(32 to 32, MarkerImageLayout.fit(16, 16, 32))
        assertEquals(18 to 12, MarkerImageLayout.fit(66, 44, 18))
        assertEquals(1 to 1, MarkerImageLayout.fit(32, 44, 1))
        assertEquals(32 to 32, MarkerImageLayout.fit(-1, -1, 32))
    }

    @Test
    fun vectorResourcesDoNotDistortTheirViewport() {
        val directory = File("src/main/res/drawable")
        val resources = directory.listFiles { file -> file.extension == "xml" }
        assertTrue(!resources.isNullOrEmpty(), "Marker drawable resources must be checked")
        val parser = DocumentBuilderFactory.newInstance().newDocumentBuilder()
        resources!!.forEach { file ->
            val vector = parser.parse(file).documentElement
            if (vector.tagName != "vector") return@forEach
            val width = vector.getAttribute("android:width").removeSuffix("dp").toDouble()
            val height = vector.getAttribute("android:height").removeSuffix("dp").toDouble()
            val viewportWidth = vector.getAttribute("android:viewportWidth").toDouble()
            val viewportHeight = vector.getAttribute("android:viewportHeight").toDouble()
            assertTrue(abs(width / height - viewportWidth / viewportHeight) < 0.0001,
                "${file.name} stretches its viewport and turns circles into ellipses")
        }
    }
}
