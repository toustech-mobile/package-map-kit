package com.golrang.map_kit.helpers

import org.maplibre.android.geometry.LatLng
import kotlin.math.*

internal object MapGeometry {
    private const val EARTH_RADIUS = 6378137.0

    fun circlePoints(center: LatLng, radius: Double, count: Int = 96): List<LatLng> {
        require(radius.isFinite() && radius >= 0) { "radius must be non-negative" }
        require(count >= 3)
        val latitude = Math.toRadians(center.latitude)
        val longitude = Math.toRadians(center.longitude)
        val distance = radius / EARTH_RADIUS
        val points = (0 until count).map { index ->
            val bearing = 2 * PI * index / count
            val lat = asin(sin(latitude) * cos(distance) +
                cos(latitude) * sin(distance) * cos(bearing))
            val lng = longitude + atan2(sin(bearing) * sin(distance) * cos(latitude),
                cos(distance) - sin(latitude) * sin(lat))
            LatLng(Math.toDegrees(lat), (Math.toDegrees(lng) + 540) % 360 - 180)
        }
        return points + points.first()
    }

    fun distanceMeters(a: LatLng, b: LatLng): Double {
        val lat1 = Math.toRadians(a.latitude)
        val lat2 = Math.toRadians(b.latitude)
        val dLat = lat2 - lat1
        val dLng = Math.toRadians(b.longitude - a.longitude)
        val h = sin(dLat / 2).pow(2) + cos(lat1) * cos(lat2) * sin(dLng / 2).pow(2)
        return 2 * EARTH_RADIUS * asin(sqrt(h.coerceIn(0.0, 1.0)))
    }

    fun segmentDistance(px: Double, py: Double, ax: Double, ay: Double,
                        bx: Double, by: Double): Double {
        val dx = bx - ax
        val dy = by - ay
        val length = dx * dx + dy * dy
        val t = if (length == 0.0) 0.0 else
            (((px - ax) * dx + (py - ay) * dy) / length).coerceIn(0.0, 1.0)
        return hypot(px - ax - t * dx, py - ay - t * dy)
    }
}
