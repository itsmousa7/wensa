# image_cropper / ucrop references okhttp3 for an optional remote-image code path
# that this app never uses. okhttp is not bundled, so suppress the R8 missing-class
# errors and keep the ucrop classes.
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**
