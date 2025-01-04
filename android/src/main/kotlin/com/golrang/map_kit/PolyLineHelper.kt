package com.golrang.map_kit

import com.carto.styles.LineStyle
import com.carto.styles.LineStyleBuilder
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.model.Polyline
import android.graphics.Color as AndroidColor
import com.carto.graphics.Color as CartoColor


class PolyLineHelper {
    companion object {
        fun toNeshanModel(polyLines: Any): List<Polyline> {

            return (polyLines as List<*>).mapNotNull { polyLine ->
                if (polyLine is Map<*, *>) {
                    val points = polyLine["points"] as? List<Map<*, *>>
                    val color = polyLine["color"] as? String
                    val strokeWidth = polyLine["strokeWidth"] as? Double

                    val polyLinePoints = points!!.map { point ->
                        LatLng(
                            point["latitude"] as Double,
                            point["longitude"] as Double
                        )
                    }.toList()

                    createPolyLine(ArrayList(polyLinePoints), color!!, strokeWidth!!)
                } else {
                    null
                }
            }
        }

        private fun createPolyLine(
            points: ArrayList<LatLng>,
            color: String,
            strokeWidth: Double
        ): Polyline {
            return Polyline(points, getLineStyle(color, strokeWidth))
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

        private fun convertToCartoColor(androidColor: Int): CartoColor {
            val alpha: Short = AndroidColor.alpha(androidColor).toShort()
            val red: Short = AndroidColor.red(androidColor).toShort()
            val green: Short = AndroidColor.green(androidColor).toShort()
            val blue: Short = AndroidColor.blue(androidColor).toShort()
            return CartoColor(red, green, blue, alpha)
        }
    }
}