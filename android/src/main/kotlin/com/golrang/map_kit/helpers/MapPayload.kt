package com.golrang.map_kit.helpers

import org.maplibre.android.geometry.LatLng

/** StandardMessageCodec can deliver integer or floating-point numbers. */
internal fun Map<*, *>.number(key: String, default: Double? = null): Double {
    val value = this[key]
    val number = if (value == null) default else (value as? Number)?.toDouble()
    require(number != null && number.isFinite()) { "$key must be a finite number" }
    return number
}

internal fun Map<*, *>.coordinate(): LatLng {
    val latitude = number("latitude")
    val longitude = number("longitude")
    require(latitude in -90.0..90.0 && longitude in -180.0..180.0) {
        "Coordinates are outside latitude/longitude bounds"
    }
    return LatLng(latitude, longitude)
}

internal fun Any?.mapList(): List<Map<*, *>> {
    require(this is List<*>) { "Expected a list of map objects" }
    return map { requireNotNull(it as? Map<*, *>) { "Expected a map object" } }
}
