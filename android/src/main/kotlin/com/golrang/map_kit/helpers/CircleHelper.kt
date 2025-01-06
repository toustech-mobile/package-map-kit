package com.golrang.map_kit.helpers

import com.carto.graphics.Color
import com.carto.styles.LineStyle
import com.carto.styles.LineStyleBuilder
import com.golrang.map_kit.models.MyCircle
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.model.Circle


class CircleHelper {

    companion object {
        fun toNeshanModel(circles: List<*>): List<MyCircle> {
            return circles.mapNotNull { circle ->
                if (circle is Map<*, *>) {
                    val latitude = circle["latitude"] as? Double
                    val longitude = circle["longitude"] as? Double
                    val radius = circle["radius"] as? Double
                    val borderStroke = circle["borderStroke"] as? Double
                    val color = circle["color"] as? String
                    val borderColor = circle["borderColor"] as? String

                    if (latitude != null && longitude != null) {
                        createCircle(
                            LatLng(latitude, longitude),
                            radius!!,
                            borderStroke!!,
                            color!!,
                            borderColor!!,
                        )
                    } else {
                        null
                    }
                } else {
                    null
                }
            }
        }

        private fun createCircle(
            point: LatLng,
            radius: Double,
            borderStroke: Double,
            color: String,
            borderColor: String,
        ): MyCircle {
            return MyCircle(
                point.latitude, point.longitude, radius, Circle(
                    point,
                    radius,
                    convertToCartoColor(android.graphics.Color.parseColor(color)),
                    getLineStyle(borderColor, borderStroke)
                )
            )
        }

        private fun getLineStyle(
            color: String,
            strokeWidth: Double
        ): LineStyle {
            val lineStyleBuilder = LineStyleBuilder()
            lineStyleBuilder.color = convertToCartoColor(android.graphics.Color.parseColor(color))
            lineStyleBuilder.width = strokeWidth.toFloat()
            return lineStyleBuilder.buildStyle()
        }

        private fun convertToCartoColor(androidColor: Int): Color {
            val alpha: Short = android.graphics.Color.alpha(androidColor).toShort()
            val red: Short = android.graphics.Color.red(androidColor).toShort()
            val green: Short = android.graphics.Color.green(androidColor).toShort()
            val blue: Short = android.graphics.Color.blue(androidColor).toShort()
            return Color(red, green, blue, alpha)
        }
    }
}