# Script PowerShell para construir y desplegar la aplicación Flutter web con Docker

param(
    [string]$Environment = "production",
    [switch]$Rebuild = $false,
    [switch]$Dev = $false,
    [switch]$Help = $false
)

# Función para imprimir mensajes con colores
function Write-Message {
    param([string]$Message, [string]$Color = "Blue")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Mostrar ayuda
if ($Help) {
    Write-Host "Uso: .\build.ps1 [opciones]"
    Write-Host "Opciones:"
    Write-Host "  -Environment ENV    Entorno (production|development) - default: production"
    Write-Host "  -Rebuild           Forzar rebuild de la imagen"
    Write-Host "  -Dev              Ejecutar en modo desarrollo con hot reload"
    Write-Host "  -Help             Mostrar esta ayuda"
    exit 0
}

Write-Message "🚀 Iniciando build de ABSistencia Web..." "Green"

# Verificar si Docker está instalado
try {
    docker --version | Out-Null
} catch {
    Write-Error "Docker no está instalado o no está en el PATH"
    exit 1
}

# Verificar si Docker Compose está disponible
$dockerComposeCmd = "docker-compose"
try {
    docker-compose --version | Out-Null
} catch {
    Write-Warning "docker-compose no encontrado, intentando con 'docker compose'"
    $dockerComposeCmd = "docker compose"
}

Write-Message "Configuración:"
Write-Message "  - Entorno: $Environment"
Write-Message "  - Rebuild: $Rebuild"
Write-Message "  - Modo desarrollo: $Dev"

# Función para construir en modo desarrollo
function Build-Dev {
    Write-Message "Construyendo para desarrollo..."
    
    if ($Rebuild) {
        Write-Message "Eliminando contenedores existentes..."
        & $dockerComposeCmd --profile dev down --rmi all
    }
    
    Write-Message "Construyendo imagen de desarrollo..."
    & $dockerComposeCmd --profile dev build absistencia-dev
    
    Write-Message "Iniciando servidor de desarrollo..."
    & $dockerComposeCmd --profile dev up absistencia-dev
}

# Función para construir en modo producción
function Build-Prod {
    Write-Message "Construyendo para producción..."
    
    if ($Rebuild) {
        Write-Message "Eliminando contenedores existentes..."
        & $dockerComposeCmd down --rmi all
    }
    
    Write-Message "Construyendo imagen de producción..."
    & $dockerComposeCmd build absistencia-web
    
    Write-Message "Iniciando servidor web..."
    & $dockerComposeCmd up -d absistencia-web
    
    Write-Success "Aplicación desplegada exitosamente!"
    Write-Message "La aplicación está disponible en: http://localhost:8080"
    Write-Message "Health check disponible en: http://localhost:8080/health"
    
    # Mostrar logs
    Write-Message "Mostrando logs (Ctrl+C para salir)..."
    & $dockerComposeCmd logs -f absistencia-web
}

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "No se encontró pubspec.yaml. Asegúrese de estar en el directorio raíz del proyecto Flutter."
    exit 1
}

# Ejecutar según el modo
if ($Dev) {
    Build-Dev
} else {
    Build-Prod
}
