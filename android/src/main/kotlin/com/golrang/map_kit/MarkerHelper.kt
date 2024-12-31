package com.golrang.map_kit

import android.content.Context
import android.graphics.BitmapFactory
import com.carto.styles.MarkerStyleBuilder
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.internal.utils.BitmapUtils
import org.neshan.mapsdk.model.Marker

class MarkerHelper {

    companion object {
        fun toNeshanModel(context: Context, markers: Any): List<Marker> {
            return (markers as List<*>).mapNotNull { marker ->
                if (marker is Map<*, *>) {
                    val latitude = marker["latitude"] as? Double
                    val longitude = marker["longitude"] as? Double
                    val data = marker["data"]
                    if (latitude != null && longitude != null) {
                        createMarker(LatLng(latitude, longitude), data, context)
                    } else {
                        null
                    }
                } else {
                    null
                }
            }
        }

         fun createMarker(loc: LatLng, data: Any?, context: Context): Marker {
            val markStCr = MarkerStyleBuilder()
            markStCr.size = 30f
            markStCr.bitmap = BitmapUtils.createBitmapFromAndroidBitmap(
                BitmapFactory.decodeResource(
                    context.resources, R.drawable.ic_marker
                )
            )
            val markSt = markStCr.buildStyle()

            val marker = Marker(loc, markSt)
            marker.putMetadata("data", data.toString())
            return marker
        }

    }

}