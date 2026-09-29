
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

-keep class org.tensorflow.lite.** { *; }

-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**