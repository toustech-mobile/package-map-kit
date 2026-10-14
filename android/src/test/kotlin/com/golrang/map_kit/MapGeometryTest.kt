package com.golrang.map_kit

import com.golrang.map_kit.helpers.MapGeometry
import com.golrang.map_kit.helpers.coordinate
import com.golrang.map_kit.helpers.number
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import org.maplibre.android.geometry.LatLng

class MapGeometryTest {
    @Test
    fun codecNumbersAcceptIntegersAndDoubles() {
        assertEquals(2.0, mapOf("borderStroke" to 2).number("borderStroke"))
        assertEquals(2.5, mapOf("borderStroke" to 2.5).number("borderStroke"))
        assertEquals(2.0, emptyMap<String, Any>().number("borderStroke", 2.0))
        assertFailsWith<IllegalArgumentException> {
            mapOf("radius" to Double.NaN).number("radius")
        }
        assertFailsWith<IllegalArgumentException> {
            mapOf("latitude" to 91, "longitude" to 0).coordinate()
        }
    }

    @Test
    fun circlesAreClosedAndRetainMeterRadiusAcrossTheDateline() {
        val center = LatLng(36.3, 179.999)
        val points = MapGeometry.circlePoints(center, 700.0)
        assertEquals(97, points.size)
        assertEquals(points.first(), points.last())
        assertTrue(points.any { it.longitude < 0 })
        points.forEach {
            assertEquals(700.0, MapGeometry.distanceMeters(center, it), 0.01)
            assertTrue(it.longitude in -180.0..180.0)
        }
    }

    @Test
    fun hitTestingClampsToSegmentEndpointsAndHandlesRepeatedPoints() {
        assertEquals(3.0, MapGeometry.segmentDistance(5.0, 3.0, 0.0, 0.0, 10.0, 0.0))
        assertEquals(5.0, MapGeometry.segmentDistance(13.0, 4.0, 0.0, 0.0, 10.0, 0.0))
        assertEquals(5.0, MapGeometry.segmentDistance(3.0, 4.0, 0.0, 0.0, 0.0, 0.0))
    }
}
