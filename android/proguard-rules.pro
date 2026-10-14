# Plugin classes and generated R classes are kept because marker icons
# are resolved reflectively (R.drawable::class.java.getField(name)).
-keep class com.golrang.map_kit.R$drawable {
    *;
}

-keep class com.golrang.map_kit.R {
    *;
}

-keep class com.golrang.map_kit.** {
    *;
}

# The MapLibre AAR supplies its own JNI/SDK consumer rules. Keep the reflected
# plugin resources above; the old Carto/Neshan packages are no longer used.
