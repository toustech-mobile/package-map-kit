package com.golrang.map_kit

import android.content.Context
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat.getDrawable
import androidx.core.graphics.drawable.toBitmap
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
                    val icon = marker["icon"] as? String ?: ""

                    if (latitude != null && longitude != null) {
                        createMarker(LatLng(latitude, longitude), data, icon, context)
                    } else {
                        null
                    }
                } else {
                    null
                }
            }
        }

        fun createMarker(
            loc: LatLng, data: Any?, icon: String, context: Context
        ): Marker {
            val markStCr = MarkerStyleBuilder()

            markStCr.size = 50f

            markStCr.bitmap = BitmapUtils.createBitmapFromAndroidBitmap(
                getIconDrawableByReflection(context, icon)!!.toBitmap()
            )

            val markSt = markStCr.buildStyle()

            val marker = Marker(loc, markSt)
            marker.putMetadata("data", data.toString())
            return marker
        }

        private fun getIconDrawableByReflection(context: Context, iconName: String): Drawable? {
            return try {
                val resId =
                    R.drawable::class.java.getField(iconName.replace(".svg", "")).getInt(null)
                getDrawable(context, resId)
            } catch (e: Exception) {
                getDrawable(context, R.drawable.end_point)
            }
        }
    }
}