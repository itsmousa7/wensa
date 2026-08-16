# image_cropper / ucrop references okhttp3 for an optional remote-image code path
# that this app never uses. okhttp is not bundled, so suppress the R8 missing-class
# errors and keep the ucrop classes.
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# HyperPay mSDK + ipworks 3DS — reflection-heavy, keep everything
-keep class com.oppwa.** { *; }
-keep interface com.oppwa.** { *; }
-keep class ipworks3ds.** { *; }
-keep class inqooltech.** { *; }
-dontwarn com.oppwa.**
