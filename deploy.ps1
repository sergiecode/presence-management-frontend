# Script de despliegue para Flutter Web en producción con Docker (PowerShell)

param(
    [switch]$Clean = $false,
    [switch]$Help = $false
)

if ($Help) {
    Write-Host "Uso: .\deploy.ps1 [opciones]"
    Write-Host "Opciones:"
    Write-Host "  -Clean    Limpiar todas las imágenes y contenedores antes del despliegue"
    Write-Host "  -Help     Mostrar esta ayuda"
    exit 0
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

Write-Host "🚀 Desplegando ABSistencia Web en producción..." -ForegroundColor Green

# Verificar Docker
try {
    docker --version | Out-Null
} catch {
    Write-Error "Docker no está instalado o no está en el PATH"
    exit 1
}

# Verificar archivo pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "No se encontró pubspec.yaml. Ejecutar desde el directorio raíz del proyecto."
    exit 1
}

# Limpiar si se solicita
if ($Clean) {
    Write-Info "Limpiando contenedores e imágenes..."
    docker stop absistencia-web 2>$null
    docker rm absistencia-web 2>$null
    docker rmi absistencia-web:latest 2>$null
}

Write-Info "Deteniendo contenedores existentes..."
docker stop absistencia-web 2>$null
docker rm absistencia-web 2>$null

Write-Info "Construyendo imagen de producción..."
docker build -t absistencia-web .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Error al construir la imagen Docker"
    exit 1
}

Write-Info "Iniciando contenedor en producción..."
docker run -d `
  --name absistencia-web `
  --restart unless-stopped `
  -p 8081:80 `
  absistencia-web

if ($LASTEXITCODE -ne 0) {
    Write-Error "Error al iniciar el contenedor"
    exit 1
}

# Esperar a que el contenedor esté listo
Write-Info "Esperando que el servicio esté listo..."
Start-Sleep -Seconds 5

# Verificar que el contenedor está corriendo
$containerStatus = docker ps --filter "name=absistencia-web" --format "table {{.Names}}"
if ($containerStatus -match "absistencia-web") {
    Write-Success "✅ Despliegue exitoso!"
    Write-Info "🌐 Aplicación disponible en: http://localhost:8081"
    Write-Info "🔍 Health check: http://localhost:8081/health"
    
    # Mostrar logs
    Write-Info "📋 Mostrando logs (Ctrl+C para salir):"
    docker logs -f absistencia-web
} else {
    Write-Error "❌ Error en el despliegue"
    docker logs absistencia-web
    exit 1
}
