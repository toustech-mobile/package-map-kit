package com.golrang.map_kit.helpers

import android.content.Context
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat.getDrawable
import androidx.core.graphics.drawable.toBitmap
import com.carto.styles.MarkerStyleBuilder
import com.golrang.map_kit.R
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.internal.utils.BitmapUtils
import org.neshan.mapsdk.model.Marker


class MarkerHelper {

    companion object {
        fun toNeshanModel(context: Context, markers: List<*>): List<Marker> {
            return markers.mapNotNull { marker ->
                if (marker is Map<*, *>) {
                    val latitude = marker["latitude"] as Double
                    val longitude = marker["longitude"] as Double
                    val data = marker["data"]
                    val icon = marker["icon"] as? String ?: ""
                    val iconSize = marker["iconSize"] as? Int ?: 32
                    val snippetTitle = marker["snippetTitle"] as? String
                    val snippetDescription = marker["snippetDescription"] as? String

                    createMarker(
                        LatLng(latitude, longitude),
                        data,
                        icon,
                        iconSize,
                        snippetTitle,
                        snippetDescription,
                        context
                    )

                } else {
                    null
                }
            }
        }

        fun createMarker(
            loc: LatLng,
            data: Any?,
            icon: String,
            iconSize: Int,
            snippetTitle: String?,
            snippetDescription: String?,
            context: Context
        ): Marker {
            val markStCr = MarkerStyleBuilder()

            markStCr.size = iconSize.toFloat()

            markStCr.bitmap = BitmapUtils.createBitmapFromAndroidBitmap(
                getIconDrawableByReflection(context, icon)!!.toBitmap()
            )

            val markSt = markStCr.buildStyle()

            val marker = Marker(loc, markSt)
            marker.putMetadata("data", data.toString())
            marker.title = snippetTitle
            marker.description = snippetDescription

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