package com.golrang.map_kit.helpers

import android.content.Context
import com.carto.styles.LineStyle
import com.carto.styles.LineStyleBuilder
import com.golrang.map_kit.models.PolyLinePointModel
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.model.Marker
import org.neshan.mapsdk.model.Polyline
import android.graphics.Color as AndroidColor
import com.carto.graphics.Color as CartoColor


class PolyLineHelper {
    companion object {
        fun toNeshanModel(
            polyLines: List<*>,
            context: Context
        ): Pair<List<Polyline>, List<Marker>> {

            val polylineList = mutableListOf<Polyline>()
            val markerList = mutableListOf<Marker>()

            polyLines.forEach { polyLine ->
                if (polyLine is Map<*, *>) {
                    @Suppress("UNCHECKED_CAST")
                    val points = polyLine["points"] as? List<Map<*, *>>
                    val color = polyLine["color"] as? String
                    val strokeWidth = polyLine["strokeWidth"] as? Double
                    val strokeColor = polyLine["strokeColor"] as? String
                    val showArrow = polyLine["showArrow"] as? Boolean

                    if (points != null && color != null && strokeWidth != null) {

                        val polyLinePoints = points.mapNotNull { point ->
                            val latitude = point["latitude"] as? Double
                            val longitude = point["longitude"] as? Double
                            val heading = point["heading"] as? Double
                                ?: 0.0

                            if (latitude != null && longitude != null) {
                                PolyLinePointModel(latitude, longitude, heading)
                            } else {
                                null
                            }
                        }

                        val latLngPoints = polyLinePoints.map {
                            LatLng(it.latitude, it.longitude)
                        }

                        polylineList.add(
                            createPolyLine(
                                ArrayList(latLngPoints),
                                strokeColor ?: "#000000",
                                strokeWidth + 4
                            )
                        )

                        polylineList.add(
                            createPolyLine(
                                ArrayList(latLngPoints),
                                color,
                                strokeWidth
                            )
                        )

                        if (showArrow == true && polyLinePoints.isNotEmpty()) {
                            polyLinePoints.forEachIndexed { index, pointModel ->
                                if (index % 2 == 0) {
                                    val marker = MarkerHelper.createMarker(
                                        LatLng(pointModel.latitude, pointModel.longitude),
                                        "",
                                        "arrow.svg",
                                        20,
                                        "",
                                        "",
                                        "",
                                        pointModel.heading,
                                        context = context
                                    )
                                    markerList.add(marker)
                                }
                            }

                        }
                    }
                }
            }

            return Pair(polylineList, markerList)
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