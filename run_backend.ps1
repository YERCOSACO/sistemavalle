$ErrorActionPreference = 'Stop'

Write-Host 'Iniciando backend Dart API en http://0.0.0.0:8080'
Set-Location $PSScriptRoot

dart run bin/server.dart
