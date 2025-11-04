# Reglas de ProGuard para mantener Supabase y dependencias funcionando
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Mantener todas las clases de Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Mantener todas las clases anotadas con @Keep
-keep @androidx.annotation.Keep class * { *; }

# No ofuscar clases de serialización JSON
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Mantener clases de Retrofit/OkHttp (usado por Supabase)
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*

# Mantener clases de Gson/JSON (si se usa)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

