package com.golrang.map_kit.models

import org.maplibre.android.annotations.Polyline

internal data class MyPolyline(
    val polyline: Polyline,
    val outline: Polyline,
    val data: String,
)
