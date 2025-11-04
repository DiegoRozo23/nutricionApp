# 🚀 Guía de Instalación - NutricionApp

Esta guía te ayudará a configurar y ejecutar el proyecto NutricionApp desde cero.

---

## 📋 Requisitos Previos

### Software Necesario

1. **Flutter SDK**
   - Versión: 3.35.1 o superior
   - **Instalación con VS Code**: [https://docs.flutter.dev/install/with-vs-code](https://docs.flutter.dev/install/with-vs-code)
   - **Instalación Manual**: [https://docs.flutter.dev/install/manual](https://docs.flutter.dev/install/manual)
   - Verifica instalación: `flutter doctor`

2. **Dart SDK**
   - Versión: 3.9.0 o superior (incluido con Flutter)

3. **Android Studio** (para desarrollo Android o puedes ejecutar la app en tu propio android activando usb debugging)
   - Descarga: [https://developer.android.com/studio](https://developer.android.com/studio)
   - Instala Android SDK y emuladores

---

## 🔧 Configuración del Proyecto

### Paso 1: Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd nutricion_app
```

### Paso 2: Instalar Dependencias

```bash
flutter pub get
```

Esto instalará todas las dependencias listadas en `pubspec.yaml`.

### Paso 3: Verificar la Instalación de Flutter

```bash
flutter doctor
```

---


## 🚀 Ejecutar la Aplicación

### Opción 1: En Dispositivo Android Físico (USB Debugging)

#### Paso 1: Activar USB Debugging en tu Android

1. **Activar Opciones de Desarrollador**:
   - Ve a **Configuración** → **Acerca del teléfono**
   - Toca **Número de compilación** 7 veces
   - Verás el mensaje "Ahora eres desarrollador"

2. **Activar USB Debugging**:
   - Ve a **Configuración** → **Opciones de desarrollador** (o **Sistema** → **Opciones de desarrollador**)
   - Activa **Depuración USB**
   - Activa **Instalar vía USB** (para permitir instalación desde USB)

3. **Conectar el Dispositivo**:
   - Conecta tu Android al computador con un cable USB
   - En tu teléfono, aparecerá un diálogo preguntando si confías en este computador
   - Marca **Permitir siempre desde este computador** y toca **Permitir**

#### Paso 2: Verificar Conexión

```bash
# Verificar que el dispositivo esté conectado
adb devices
```

Deberías ver algo como:
```
List of devices attached
ABC123XYZ    device
```

Si aparece `unauthorized`, acepta el diálogo en tu teléfono.

#### Paso 3: Ejecutar la Aplicación

```bash
# Verificar dispositivos disponibles (incluyendo tu Android)
flutter devices
```

Esto mostrará todos los dispositivos disponibles, por ejemplo:
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
Samsung Galaxy S21 (mobile) • hmugylivaua6bm4l • android-arm64 • Android 13 (API 33)
```

Para ejecutar en un dispositivo específico, usa el **device ID**:

```bash
# Ejecutar en dispositivo específico (reemplaza con tu device ID)
flutter run -d hmugylivaua6bm4l

# O ejecutar en modo release (producción)
flutter run --release -d hmugylivaua6bm4l
```

Si solo tienes un dispositivo conectado, puedes usar simplemente:
```bash
flutter run
```

### Opción 2: En Emulador Android

1. **Crear Emulador**:
   - Abre Android Studio
   - Ve a **Tools** → **Device Manager**
   - Haz clic en **Create Device**
   - Selecciona un dispositivo y crea el emulador

2. **Iniciar Emulador**:
   - En Device Manager, haz clic en el botón Play (▶️) del emulador
   - Espera a que se inicie completamente

3. **Ejecutar la App**:
   ```bash
   flutter run
   ```

