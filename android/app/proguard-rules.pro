# flutter_local_notifications keeps its scheduled notifications as Gson JSON
# and reads them back through TypeToken reflection. R8 strips the generic
# signatures it relies on, which throws "Missing type parameter." during
# startup in release builds (app then never reaches runApp).
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.flutterlocalnotifications.** { *; }
