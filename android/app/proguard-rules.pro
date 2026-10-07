# TensorFlow Lite — interpreter dipanggil lewat JNI, jadi R8 tidak melihat
# pemakaiannya dan bisa membuangnya. Gejalanya: model gagal dimuat di rilis
# tapi jalan di debug.
-keep class org.tensorflow.lite.** { *; }

# Delegasi GPU tidak dipakai (interpreter jalan di CPU), tapi kelasnya
# dirujuk dari dalam pustaka. Tanpa dontwarn, build rilis berhenti dengan
# peringatan soal kelas yang memang sengaja tidak ada.
-dontwarn org.tensorflow.lite.gpu.**

# ML Kit face detection — sama seperti TFLite, dipanggil lewat refleksi.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**