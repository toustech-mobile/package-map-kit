@file:Suppress("DEPRECATION")

package com.golrang.map_kit.helpers

import android.graphics.Color
import com.golrang.map_kit.models.MyPolyline
import org.maplibre.android.annotations.PolylineOptions
import org.maplibre.android.maps.MapLibreMap

internal object PolyLineHelper {
    fun add(map: MapLibreMap, data: Map<*, *>): MyPolyline {
        val points = data["points"].mapList().map { it.coordinate() }
        require(points.size >= 2) { "A polyline requires at least two points" }
        val width = data.number("strokeWidth", 3.0)
        require(width > 0) { "strokeWidth must be positive" }
        val color = Color.parseColor(data["color"] as? String ?: "#FF0000FF")
        val strokeColor = Color.parseColor(data["strokeColor"] as? String ?: "#640000FF")
        fun options(value: Int, lineWidth: Double) = PolylineOptions().addAll(points)
            .color(value or (0xFF shl 24)).alpha(Color.alpha(value) / 255f)
            .width(lineWidth.toFloat())
        val outline = map.addPolyline(options(strokeColor, width + 4))
        val line = map.addPolyline(options(color, width))
        return MyPolyline(line, outline, data["data"]?.toString() ?: "{}")
    }

    fun remove(map: MapLibreMap, line: MyPolyline) {
        map.removePolyline(line.polyline)
        map.removePolyline(line.outline)
    }
}
