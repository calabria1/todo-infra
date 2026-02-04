param(
  [string]$DynamoDir = "C:\Users\arthu\Downloads\dynamodb_local_latest",
  [string]$ApiDir    = ".\services\tasks\src",
  [int]$DynamoPort   = 8000,
  [int]$ApiPort      = 3000
)

$ErrorActionPreference = "Stop"

Write-Host "==> Subindo DynamoDB Local..." -ForegroundColor Cyan

if (-not (Test-Path $DynamoDir)) { throw "Pasta do DynamoDB Local não encontrada: $DynamoDir" }
if (-not (Test-Path (Join-Path $DynamoDir "DynamoDBLocal.jar"))) { throw "DynamoDBLocal.jar não encontrado em: $DynamoDir" }
if (-not (Test-Path (Join-Path $DynamoDir "DynamoDBLocal_lib"))) { throw "Pasta DynamoDBLocal_lib não encontrada em: $DynamoDir" }

# Sobe DynamoDB Local em uma nova janela
Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-Command",
  "cd `"$DynamoDir`"; java `"--enable-native-access=ALL-UNNAMED`" `"-Djava.library.path=.\DynamoDBLocal_lib`" -jar .\DynamoDBLocal.jar -sharedDb -port $DynamoPort"
)

Start-Sleep -Seconds 1

Write-Host "==> Subindo API local (Lambda emulada)..." -ForegroundColor Cyan

if (-not (Test-Path $ApiDir)) { throw "Pasta da API não encontrada: $ApiDir" }

Push-Location $ApiDir

# venv
if (-not (Test-Path ".\.venv")) {
  python -m venv .venv
}

# ativar venv
& ".\.venv\Scripts\Activate.ps1"

# deps locais
pip install -r .\requirements-local.txt

# === Variáveis do modo LOCAL (não existem na AWS) ===
$env:DYNAMODB_ENDPOINT = "http://localhost:$DynamoPort"

# região igual ao seu dev
$env:AWS_REGION = "sa-east-1"

# credenciais fake (SDK exige)
$env:AWS_ACCESS_KEY_ID = "local"
$env:AWS_SECRET_ACCESS_KEY = "local"

# Para ficar exatamente igual ao dev: nome da tabela = gestao-tarefas-dev-tarefas
$env:PROJECT = "gestao-tarefas"
$env:ENV = "dev"
# (TABLE_NAME fica automaticamente "gestao-tarefas-dev-tarefas" pelo dynamodb_client.py)

$env:PORT = "$ApiPort"

Write-Host "==> API local: http://localhost:$ApiPort" -ForegroundColor Green
python .\local_server.py

Pop-Location
