package com.golrang.map_kit.helpers

import kotlin.math.roundToInt

internal object MarkerImageLayout {
    /** Fit the longest side to [size] without stretching the artwork. */
    fun fit(width: Int, height: Int, size: Int): Pair<Int, Int> {
        require(size > 0)
        if (width <= 0 || height <= 0) return size to size
        val scale = size.toDouble() / maxOf(width, height)
        return (width * scale).roundToInt().coerceIn(1, size) to
            (height * scale).roundToInt().coerceIn(1, size)
    }
}
