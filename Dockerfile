# Dockerfile para compilar Flutter web y servir con nginx
# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:latest AS build

# Establecer directorio de trabajo
WORKDIR /app

# Habilitar Flutter web
RUN flutter config --enable-web

# Copiar archivos de configuración
COPY pubspec.yaml pubspec.lock ./

# Instalar dependencias
RUN flutter pub get

# Copiar código fuente
COPY . .

# Habilitar Flutter web (por si acaso)
RUN flutter config --enable-web

# Compilar para web en modo release
RUN flutter build web --release

# Stage 2: Servir con nginx
FROM nginx:alpine

# Copiar archivos compilados desde el stage anterior
COPY --from=build /app/build/web /usr/share/nginx/html

# Copiar configuración personalizada de nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer puerto 80
EXPOSE 80

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]
