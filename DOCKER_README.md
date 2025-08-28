# ABSistencia - Despliegue Web con Docker

Esta documentación describe cómo desplegar la aplicación ABSistencia como una aplicación web usando Docker y nginx.

## 📋 Requisitos

- Docker
- Docker Compose
- Git (para clonar el repositorio)

## 🚀 Despliegue Rápido

### Opción 1: Usando Docker Compose (Recomendado)

```bash
# Construir y ejecutar en producción
docker-compose up -d absistencia-web

# Ver logs
docker-compose logs -f absistencia-web
```

### Opción 2: Usando los Scripts de Build

#### En Linux/macOS:
```bash
# Dar permisos de ejecución
chmod +x build.sh

# Ejecutar en producción
./build.sh

# Ejecutar en desarrollo
./build.sh --dev

# Forzar rebuild
./build.sh --rebuild
```

#### En Windows (PowerShell):
```powershell
# Ejecutar en producción
.\build.ps1

# Ejecutar en desarrollo
.\build.ps1 -Dev

# Forzar rebuild
.\build.ps1 -Rebuild
```

## 🔧 Configuración

### Puertos

- **Producción**: La aplicación estará disponible en `http://localhost:8080`
- **Desarrollo**: La aplicación estará disponible en `http://localhost:3000`
- **Health Check**: `http://localhost:8080/health`

### Variables de Entorno

Puedes configurar variables de entorno en el archivo `docker-compose.yml`:

```yaml
environment:
  - NGINX_HOST=localhost
  - NGINX_PORT=80
  - API_BASE_URL=https://tu-api.com
```

## 📁 Estructura de Archivos Docker

```
├── Dockerfile              # Build de producción
├── Dockerfile.dev          # Build de desarrollo
├── docker-compose.yml      # Configuración de servicios
├── nginx.conf              # Configuración de nginx
├── .dockerignore           # Archivos a ignorar en build
├── build.sh                # Script de build (Linux/macOS)
├── build.ps1               # Script de build (Windows)
└── DOCKER_README.md        # Esta documentación
```

## 🛠️ Comandos Útiles

### Docker Compose

```bash
# Construir sin cache
docker-compose build --no-cache absistencia-web

# Ver estado de servicios
docker-compose ps

# Parar servicios
docker-compose down

# Parar y eliminar volúmenes
docker-compose down -v

# Ver logs en tiempo real
docker-compose logs -f absistencia-web
```

### Docker Directo

```bash
# Construir imagen
docker build -t absistencia-web .

# Ejecutar contenedor
docker run -d -p 8080:80 --name absistencia absistencia-web

# Ver logs
docker logs -f absistencia

# Parar contenedor
docker stop absistencia

# Eliminar contenedor
docker rm absistencia
```

## 🔍 Troubleshooting

### Error: "Flutter not found"
Asegúrate de que el Dockerfile esté usando la imagen correcta de Flutter:
```dockerfile
FROM cirrusci/flutter:stable
```

### Error: "Web not enabled"
El Dockerfile automáticamente habilita Flutter web:
```dockerfile
RUN flutter config --enable-web
```

### Error de permisos en Linux
Da permisos de ejecución a los scripts:
```bash
chmod +x build.sh
```

### La aplicación no carga
1. Verifica que el contenedor esté ejecutándose:
   ```bash
   docker-compose ps
   ```

2. Revisa los logs:
   ```bash
   docker-compose logs absistencia-web
   ```

3. Verifica el health check:
   ```bash
   curl http://localhost:8080/health
   ```

## 📊 Monitoreo y Salud

### Health Check
La aplicación incluye un endpoint de health check en `/health` que retorna:
- Status: 200 OK
- Respuesta: "healthy"

### Logs
Los logs de nginx están configurados para incluir información detallada de acceso y errores.

## 🔒 Seguridad

La configuración de nginx incluye:
- Headers de seguridad (X-Frame-Options, X-Content-Type-Options, etc.)
- Compresión gzip
- Cache optimizado para assets estáticos
- Manejo seguro de CORS para Flutter web

## 🚀 Despliegue en Producción

Para un entorno de producción, considera:

1. **Usar HTTPS**: Configura un reverse proxy con SSL (nginx, Traefik, etc.)
2. **Variables de entorno**: Configura URLs de API apropiadas
3. **Recursos**: Ajusta límites de memoria y CPU en `docker-compose.yml`
4. **Backup**: Configura backups regulares si manejas datos persistentes
5. **Monitoreo**: Implementa monitoreo con herramientas como Prometheus

### Ejemplo de configuración para producción:

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  absistencia-web:
    build: .
    restart: always
    environment:
      - API_BASE_URL=https://api.tu-dominio.com
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.absistencia.rule=Host(\`tu-dominio.com\`)"
```

## 📞 Soporte

Para problemas relacionados con el despliegue Docker:
1. Revisa los logs del contenedor
2. Verifica la configuración de red
3. Asegúrate de que los puertos estén disponibles
4. Consulta la documentación de Docker y Flutter web
