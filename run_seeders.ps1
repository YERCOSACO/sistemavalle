$ErrorActionPreference = 'Stop'

$env:APP_ENV = 'local'
$env:SEED_DEVELOPMENT_DATA = 'true'

Write-Host 'Sembrando datos de desarrollo...'
Set-Location $PSScriptRoot

dart run bin/seed.dart --confirm-development
