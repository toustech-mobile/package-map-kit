@file:Suppress("DEPRECATION")

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
import com.golrang.map_kit.R
import org.maplibre.android.annotations.IconFactory
import org.maplibre.android.annotations.MarkerOptions

internal object MarkerHelper {
    fun options(context: Context, data: Map<*, *>): MarkerOptions {
        val size = data.number("iconSize", 32.0)
        require(size > 0 && size <= 512) { "iconSize must be between 0 and 512" }
        val pixels = (size * context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
        val drawable = optionalDrawable(context, data["icon"] as? String ?: "")
            ?: requireNotNull(getDrawable(context, R.drawable.end_point))
        val (width, height) = MarkerImageLayout.fit(
            drawable.intrinsicWidth, drawable.intrinsicHeight, pixels)
        val bitmap = drawable.toBitmap(width, height, Bitmap.Config.ARGB_8888)
            .copy(Bitmap.Config.ARGB_8888, true)
        val content = data["markerContent"] as? String
        if (!content.isNullOrEmpty()) drawContent(context, bitmap, content)
        bitmap.density = context.resources.displayMetrics.densityDpi
        return MarkerOptions().position(data.coordinate())
            .icon(IconFactory.getInstance(context).fromBitmap(bitmap))
            .title(data["snippetTitle"] as? String)
            .snippet(data["snippetDescription"] as? String)
    }

    private fun drawContent(context: Context, bitmap: Bitmap, content: String) {
        val canvas = Canvas(bitmap)
        val drawable = optionalDrawable(context, content)
        if (drawable != null) {
            val size = (minOf(bitmap.width, bitmap.height) * 0.6f).toInt().coerceAtLeast(1)
            val (width, height) = MarkerImageLayout.fit(
                drawable.intrinsicWidth, drawable.intrinsicHeight, size)
            val icon = drawable.toBitmap(width, height)
            canvas.drawBitmap(icon, (bitmap.width - width) / 2f,
                (bitmap.height - height) / 2f - 4 * context.resources.displayMetrics.density, null)
        } else {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.rgb(37, 37, 39)
                textSize = bitmap.height * 0.45f
                textAlign = Paint.Align.CENTER
                typeface = Typeface.createFromAsset(context.assets, "fonts/iransans.ttf")
            }
            canvas.drawText(content, bitmap.width / 2f, bitmap.height / 2f, paint)
        }
    }

    private fun optionalDrawable(context: Context, name: String): Drawable? = try {
        val id = R.drawable::class.java.getField(name.removeSuffix(".svg")).getInt(null)
        getDrawable(context, id)
    } catch (_: ReflectiveOperationException) {
        null
    }
}
