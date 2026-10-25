package com.golrang.map_kit.models

import org.maplibre.android.annotations.Polygon
import org.maplibre.android.annotations.Polyline
import org.maplibre.android.geometry.LatLng

internal data class MyCircle(
    val center: LatLng,
    val radius: Double,
    val polygon: Polygon,
    val border: Polyline?,
    val data: String,
)
