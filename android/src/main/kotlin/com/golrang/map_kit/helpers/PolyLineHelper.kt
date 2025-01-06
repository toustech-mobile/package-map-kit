package com.golrang.map_kit.helpers

import com.carto.styles.LineStyle
import com.carto.styles.LineStyleBuilder
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.model.Polyline
import android.graphics.Color as AndroidColor
import com.carto.graphics.Color as CartoColor


class PolyLineHelper {
    companion object {
        fun toNeshanModel(polyLines: List<*>): List<Polyline> {
            val result = mutableListOf<Polyline>()
            polyLines.forEach { polyLine ->
                if (polyLine is Map<*, *>) {
                    val points = polyLine["points"] as? List<Map<*, *>>
                    val color = polyLine["color"] as? String
                    val strokeWidth = polyLine["strokeWidth"] as? Double

                    if (points != null && color != null && strokeWidth != null) {
                        val polyLinePoints = points.mapNotNull { point ->
                            val latitude = point["latitude"] as? Double
                            val longitude = point["longitude"] as? Double
                            if (latitude != null && longitude != null) {
                                LatLng(latitude, longitude)
                            } else null
                        }

                        result.add(
                            createPolyLine(
                                ArrayList(polyLinePoints),
                                "#ffffff",
                                strokeWidth + 5
                            )
                        )
                        result.add(createPolyLine(ArrayList(polyLinePoints), color, strokeWidth))

                    }
                }
            }
            return result
        }

        fun createPolyLine(
            points: ArrayList<LatLng>,
            color: String,
            strokeWidth: Double
        ): Polyline {
            return Polyline(points, getLineStyle(color, strokeWidth))
        }

        private fun convertToCartoColor(androidColor: Int): CartoColor {
            val alpha: Short = AndroidColor.alpha(androidColor).toShort()
            val red: Short = AndroidColor.red(androidColor).toShort()
            val green: Short = AndroidColor.green(androidColor).toShort()
            val blue: Short = AndroidColor.blue(androidColor).toShort()
            return CartoColor(red, green, blue, alpha)
        }

        private fun getLineStyle(
            color: String,
            strokeWidth: Double
        ): LineStyle {
            val lineStyleBuilder = LineStyleBuilder()
            lineStyleBuilder.color = convertToCartoColor(AndroidColor.parseColor(color))
            lineStyleBuilder.width = strokeWidth.toFloat()
            return lineStyleBuilder.buildStyle()
        }

        private fun getLineStyle2(
            strokeWidth: Double
        ): LineStyle {
            val lineStyleBuilder = LineStyleBuilder()
            lineStyleBuilder.color = convertToCartoColor(AndroidColor.parseColor("#ffffff"))
            lineStyleBuilder.width = strokeWidth.toFloat() + 2
            return lineStyleBuilder.buildStyle()
        }
    }
}