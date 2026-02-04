# API Serverless de Gerenciamento de Tarefas (To-Do)

Esta API foi desenvolvida para permitir que advogados gerenciem suas tarefas diárias de forma eficiente e escalável. A solução utiliza uma arquitetura 100% Serverless na AWS, focando em baixo custo, alta disponibilidade e facilidade de manutenção.

## 🏗️ Arquitetura e Tecnologias

- **Linguagem:** Python 3.11 (Produção) / Python Local (Windows Launcher)
- **Compute:** AWS Lambda (Stateless)
- **API:** API Gateway HTTP (Payload v2.0)
- **Banco de Dados:** DynamoDB (NoSQL)
- **Infraestrutura:** Terraform
- **CI/CD:** GitHub Actions (Deploy automatizado)

## 🚀 Como realizar o Deploy (AWS)

O deploy é automatizado via pipeline. Ao realizar um push para a branch `main`, o GitHub Actions valida a infraestrutura e realiza o deploy.

### Pré-requisitos

- Conta AWS ativa.
- Bucket S3 criado manualmente para armazenar o tfstate do Terraform.
- OIDC ou Usuário IAM com permissões adequadas.

### Secrets do GitHub

Em **Settings > Secrets and variables > Actions**, configure:

- `AWS_ROLE_ARN`
- `AWS_REGION`
- `S3_BUCKET_ARTIFACTS`

## 💻 Execução Local (Desenvolvimento)

Esta seção explica o fluxo para desenvolvimento local utilizando DynamoDB Local e um servidor Flask para emular o API Gateway, sem custos e sem alterar a produção.

> ⚠️ **Importante:** O modo local é ativado apenas quando a variável `DYNAMODB_ENDPOINT` está definida. Na AWS, essa variável não existe, garantindo o comportamento nativo.

### 1. Pré-requisitos Locais (Windows)

- Java (para rodar o DynamoDB Local)
- Python instalado via launcher `py`
- PowerShell

### 2. Rodar o DynamoDB Local

Baixe a versão executável na documentação oficial da AWS. Extraia e execute no terminal:

```powershell
cd C:\caminho\para\diretorio_extraido
java "-Djava.library.path=.\DynamoDBLocal_lib" -jar .\DynamoDBLocal.jar -sharedDb -port 8000
```

O banco estará disponível em: `http://localhost:8000`.

### 3. Subir a API Local

No diretório `services/tasks/src`, execute:

```powershell
# Criar e ativar ambiente virtual
py -m venv .venv
.\.venv\Scripts\Activate.ps1

# Instalar dependências locais (Flask, etc)
py -m pip install -r requirements-local.txt

# Configurar variáveis de ambiente
$env:DYNAMODB_ENDPOINT="http://localhost:8000"
$env:AWS_REGION="sa-east-1"
$env:AWS_ACCESS_KEY_ID="local"
$env:AWS_SECRET_ACCESS_KEY="local"
$env:PROJECT="gestao-tarefas"
$env:ENV="dev"
$env:PORT="3000"

# Rodar o servidor de emulação
py .\local_server.py
```

## 🛣️ Endpoints da API (Local: http://127.0.0.1:3000)

| Método | Endpoint        | Descrição                                |
| ------ | --------------- | ---------------------------------------- |
| POST   | `/tarefas`      | Cria uma nova tarefa via JSON.           |
| GET    | `/tarefas`      | Lista todas as tarefas locais.           |
| GET    | `/tarefas/{id}` | Busca uma tarefa específica por UUID.    |
| PUT    | `/tarefas/{id}` | Atualiza dados ou status da tarefa.      |
| DELETE | `/tarefas/{id}` | Remove a tarefa do DynamoDB Local.       |

## 📂 Estrutura do Repositório

- `services/tasks/src`: Código da Lambda, `local_server.py` e lógica de negócio.
- `todo-infra/infra`: Arquivos Terraform (IaC).
- `.github/workflows`: Definições do pipeline de CI/CD.
