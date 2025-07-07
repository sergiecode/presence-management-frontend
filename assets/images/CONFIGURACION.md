# Logos de ABSTI - Configuración Actual

## Imágenes Disponibles:

### 📱 **logo-app.png**

- **Uso**: Logo principal de la aplicación
- **Ubicación**: Login, Registro (centro de pantalla)
- **Tamaño recomendado**: 512x512px o similar
- **Código**: `Image.asset('assets/images/logo-app.png')`

### 🔝 **logo-navbar.png**

- **Uso**: Logo pequeño para AppBar/NavBar
- **Ubicación**: Headers de todas las páginas
- **Tamaño recomendado**: 200x60px (horizontal)
- **Código**: `Image.asset('assets/images/logo-navbar.png')`

## Configuración en la App:

✅ **Título de la app**: "Absti Asistencia"
✅ **Color corporativo**: #E67D21 (naranja ABSTI)
✅ **Tema**: Moderno con blancos y grises
✅ **Fallback**: Si las imágenes fallan, muestra iconos con colores corporativos

## Páginas que usan los logos:

1. **LoginPage**: logo-app.png (centro) + logo-navbar.png (AppBar)
2. **RegisterPage**: logo-app.png (centro) + logo-navbar.png (AppBar)
3. **HomePage**: logo-navbar.png (AppBar)

## Estructura de Assets:

```
assets/
  images/
    logo-app.png      ← Logo principal
    logo-navbar.png   ← Logo del navbar
```

Los assets están configurados en `pubspec.yaml` y se cargan automáticamente.
