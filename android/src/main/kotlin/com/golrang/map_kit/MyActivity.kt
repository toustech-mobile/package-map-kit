package com.golrang.map_kit

import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.carto.styles.AnimationStyle
import com.carto.styles.AnimationStyleBuilder
import com.carto.styles.AnimationType
import com.carto.styles.MarkerStyleBuilder
import org.neshan.common.model.LatLng
import org.neshan.mapsdk.MapView
import org.neshan.mapsdk.internal.utils.BitmapUtils
import org.neshan.mapsdk.model.Marker

// map UI element
private lateinit var mapView: MapView

// marker animation style
private lateinit var animSt: AnimationStyle

class MyActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.my_activity)
        initLayoutReferences()
    }


    private fun initViews() {
        mapView = findViewById(R.id.map)


        mapView.addMarker(createMarker(LatLng(35.69975329373588, 51.34158699185747)))

    }

    private fun initLayoutReferences() {
        // Initializing views
        initViews()

        // when long clicked on map, a marker is added in clicked location
        mapView.setOnMapLongClickListener {
            mapView.addMarker(createMarker(it))
        }
        // when on marker clicked, change marker style to blue
        mapView.setOnMarkerClickListener { marker1: Marker ->
            changeMarkerToBlue(marker1)
        }

    }

    // This method gets a LatLng as input and adds a marker on that position
    private fun createMarker(loc: LatLng): Marker {
        // Creating animation for marker. We should use an object of type AnimationStyleBuilder, set
        // all animation features on it and then call buildStyle() method that returns an object of type
        // AnimationStyle
        val animStBl = AnimationStyleBuilder()
        animStBl.fadeAnimationType = AnimationType.ANIMATION_TYPE_SMOOTHSTEP
        animStBl.sizeAnimationType = AnimationType.ANIMATION_TYPE_SPRING
        animStBl.phaseInDuration = 0.5f
        animStBl.phaseOutDuration = 0.5f
        animSt = animStBl.buildStyle()

        // Creating marker style. We should use an object of type MarkerStyleCreator, set all features on it
        // and then call buildStyle method on it. This method returns an object of type MarkerStyle
        val markStCr = MarkerStyleBuilder()
        markStCr.size = 30f
        markStCr.bitmap = BitmapUtils.createBitmapFromAndroidBitmap(
            BitmapFactory.decodeResource(
                resources, R.drawable.ic_marker
            )
        )
        // AnimationStyle object - that was created before - is used here
        markStCr.animationStyle = animSt
        val markSt = markStCr.buildStyle()

        // Creating marker
        return Marker(loc, markSt)
    }

    private fun changeMarkerToBlue(redMarker: Marker) {
        // create new marker style
        val markStCr = MarkerStyleBuilder()
        markStCr.size = 30f
        // Setting a new bitmap as marker
        markStCr.bitmap = BitmapUtils.createBitmapFromAndroidBitmap(
            BitmapFactory.decodeResource(
                resources, R.drawable.ic_marker_blue
            )
        )
        markStCr.animationStyle = animSt
        val blueMarkSt = markStCr.buildStyle()

        // changing marker style using setStyle
        redMarker.setStyle(blueMarkSt)
    }
}