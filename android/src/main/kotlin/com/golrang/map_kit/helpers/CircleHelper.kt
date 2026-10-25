@file:Suppress("DEPRECATION")

package com.golrang.map_kit.helpers

import android.graphics.Color
import com.golrang.map_kit.models.MyCircle
import org.maplibre.android.annotations.PolygonOptions
import org.maplibre.android.annotations.PolylineOptions
import org.maplibre.android.maps.MapLibreMap

internal object CircleHelper {
    fun add(map: MapLibreMap, data: Map<*, *>): MyCircle {
        val center = data.coordinate()
        val radius = data.number("radius")
        val width = data.number("borderStroke", 2.0)
        require(width >= 0) { "borderStroke must be non-negative" }
        val points = MapGeometry.circlePoints(center, radius)
        val fill = Color.parseColor(data["color"] as? String ?: "#800000FF")
        val stroke = Color.parseColor(data["borderColor"] as? String ?: "#FF0000FF")
        // Polygon opacity is separate from its fill color in the annotation API.
        val polygon = map.addPolygon(PolygonOptions().addAll(points)
            .fillColor(fill or (0xFF shl 24)).alpha(Color.alpha(fill) / 255f)
            .strokeColor(Color.TRANSPARENT))
        val border = if (width > 0) map.addPolyline(PolylineOptions().addAll(points)
            .color(stroke or (0xFF shl 24)).alpha(Color.alpha(stroke) / 255f)
            .width(width.toFloat())) else null
        return MyCircle(center, radius, polygon, border, data["data"]?.toString() ?: "{}")
    }

    fun remove(map: MapLibreMap, circle: MyCircle) {
        map.removePolygon(circle.polygon)
        circle.border?.let(map::removePolyline)
    }
}
