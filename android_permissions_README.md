# Permissões necessárias para GPS

## Android — android/app/src/main/AndroidManifest.xml

Adicione ANTES de <application>:

```xml
<!-- GPS preciso (obrigatório) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<!-- GPS aproximado (fallback) -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Para localização em background (não necessário neste app):
```xml
<!-- Apenas se precisar de localização com app fechado -->
<!-- <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" /> -->
```

## iOS — ios/Runner/Info.plist

Adicione dentro de <dict>:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>O Voz Animal usa sua localização para registrar o local exato
da ocorrência de maus-tratos.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>O Voz Animal usa sua localização para registrar o local exato
da ocorrência de maus-tratos.</string>
```

## Android — android/app/build.gradle

Confirme que compileSdk >= 33:

```gradle
android {
    compileSdk = 34
    defaultConfig {
        minSdk = 21
    }
}
```
