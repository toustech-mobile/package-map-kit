package com.golrang.map_kit.helpers

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
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
                    val markerContent = marker["markerContent"] as? String

                    createMarker(
                        LatLng(latitude, longitude),
                        data,
                        icon,
                        iconSize,
                        snippetTitle,
                        snippetDescription,
                        markerContent,
                        0.0,
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
            markerContent: String?,
            angle: Double?,
            context: Context
        ): Marker {
            val markStCr = MarkerStyleBuilder()
            markStCr.size = iconSize.toFloat()

            // دریافت Bitmap از آیکون
            val iconBitmap =
                getIconDrawableByReflection(context, icon)?.toBitmap() ?: return Marker(
                    loc,
                    markStCr.buildStyle()
                )

            // اگر markerContent وجود داشت، روی آیکون بنویس
            val finalBitmap = if (!markerContent.isNullOrEmpty()) {
                addTextToBitmap(context, iconBitmap, markerContent)
            } else {
                iconBitmap
            }

            // اگر زاویه تعریف شده بود، بچرخون
            val rotatedBitmap =
                if (angle != null) BitmapUtils.rotate(finalBitmap, angle) else finalBitmap
            markStCr.bitmap = BitmapUtils.createBitmapFromAndroidBitmap(rotatedBitmap)

            val markSt = markStCr.buildStyle()
            markStCr.anchorPointX = 0f
            markStCr.anchorPointY = 0f

            val marker = Marker(loc, markSt)
            if (data != null) marker.putMetadata("data", data.toString())
            marker.title = snippetTitle
            marker.description = snippetDescription
            marker.setStyle(markStCr.buildStyle())

            return marker
        }


        private fun addTextToBitmap(context: Context, bitmap: Bitmap, text: String): Bitmap {
            val result = bitmap.copy(Bitmap.Config.ARGB_8888, true)
            val canvas = Canvas(result)
            val typeface = Typeface.createFromAsset(context.assets, "fonts/iransans.ttf")
            val paint = Paint().apply {
                color = Color.parseColor("#252527")
                textSize = 28f
                textAlign = Paint.Align.CENTER
                isAntiAlias = true
                this.typeface = typeface
            }
            val xPos = canvas.width / 2
            val yPos = canvas.height - 26 // پایین آیکون
            canvas.drawText(text, xPos.toFloat(), yPos.toFloat(), paint)
            return result
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