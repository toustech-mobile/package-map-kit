package com.golrang.map_kit.models

import org.neshan.mapsdk.model.Circle
import org.neshan.mapsdk.model.Marker

data class MyCircle(
    var latitude: Double,
    var longitude: Double,
    var radius: Double,
    var snippetTitle: String?,
    var snippetDescription: String?,
    var circle: Circle,
    var centerMarker: Marker// it's invisible only for show snippets
)
