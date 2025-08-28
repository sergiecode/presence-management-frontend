#!/bin/bash

# Script de despliegue para Flutter Web en producción con Docker

set -e

echo "🚀 Desplegando ABSistencia Web en producción..."

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    exit 1
fi

# Verificar archivo pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    print_error "No se encontró pubspec.yaml. Ejecutar desde el directorio raíz del proyecto."
    exit 1
fi

print_info "Deteniendo contenedores existentes..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

print_info "Limpiando imágenes anteriores..."
docker rmi absistencia-web:latest 2>/dev/null || true

print_info "Construyendo imagen de producción..."
docker build -t absistencia-web .

print_info "Iniciando contenedor en producción..."
docker run -d \
  --name absistencia-web \
  --restart unless-stopped \
  -p 8081:80 \
  absistencia-web

# Esperar a que el contenedor esté listo
print_info "Esperando que el servicio esté listo..."
sleep 5

# Verificar que el contenedor está corriendo
if docker ps | grep -q absistencia-web; then
    print_success "✅ Despliegue exitoso!"
    print_info "🌐 Aplicación disponible en: http://localhost:8081"
    print_info "🔍 Health check: http://localhost:8081/health"
    
    # Mostrar logs
    print_info "📋 Mostrando logs (Ctrl+C para salir):"
    docker logs -f absistencia-web
else
    print_error "❌ Error en el despliegue"
    docker logs absistencia-web
    exit 1
fi
