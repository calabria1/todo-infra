# API Serverless de Gerenciamento de Tarefas (To-Do)

## Descrição

Esta API foi desenvolvida para permitir que advogados gerenciem suas tarefas diárias de forma eficiente e escalável. A solução utiliza uma arquitetura 100% Serverless na AWS, focando em baixo custo, alta disponibilidade e facilidade de manutenção.

## Arquitetura e Tecnologias

- **Linguagem:** Python 3.11
- **Compute:** AWS Lambda (Stateless)
- **API:** API Gateway HTTP
- **Banco de Dados:** DynamoDB (NoSQL)
- **Infraestrutura:** Terraform
- **CI/CD:** GitHub Actions (Deploy automatizado)

### Desenho da Solução

```
Usuário -> API Gateway -> Lambda -> DynamoDB
```

## Como realizar o Deploy

O deploy é automatizado. Ao realizar um push para a branch `main`, o GitHub Actions valida a infraestrutura e realiza o deploy.

### Pré-requisitos

- Conta AWS ativa.
- Bucket S3 criado manualmente para armazenar o `tfstate` do Terraform (ex: `meu-projeto-tfstate`).
- Configuração de OIDC ou Usuário IAM com permissões de Administrator para o GitHub Actions.

### Configuração de Secrets no GitHub

No seu repositório, vá em **Settings > Secrets and variables > Actions** e adicione:

- `AWS_ROLE_ARN`: ARN da Role que o GitHub irá assumir.
- `AWS_REGION`: Ex: `us-east-1`.
- `S3_BUCKET_ARTIFACTS`: Nome do bucket para armazenar os arquivos `.zip` da Lambda.

## Execução Local

Para testar a lógica da aplicação (handlers e validações) sem subir para a AWS:

### 1. Preparar o Ambiente

```bash
# Entrar na pasta do serviço
cd services/tasks/src

# Criar e ativar ambiente virtual
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt
```

### 2. Configurar Variáveis de Ambiente

```bash
# Linux/Mac
export TABLE_NAME=gestao-tarefas-dev-tarefas
export AWS_DEFAULT_REGION=us-east-1

# Windows (PowerShell)
$env:TABLE_NAME="gestao-tarefas-dev-tarefas"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### 3. Rodar Teste Local

Crie um arquivo `local_test.py` (ou use o existente) para simular uma chamada:

```python
from handler import lambda_handler

mock_event = {
    "requestContext": {"http": {"method": "GET"}},
    "rawPath": "/tarefas",
    "queryStringParameters": {"criado_por": "arthur"}
}

print(lambda_handler(mock_event, None))
```

Execute com:

```bash
python local_test.py
```

## Endpoints da API

| Método | Endpoint        | Descrição                                           |
| ------ | --------------- | --------------------------------------------------- |
| POST   | `/tarefas`      | Cria uma nova tarefa                                |
| GET    | `/tarefas`      | Lista todas as tarefas (suporta filtro por usuário) |
| GET    | `/tarefas/{id}` | Detalhes de uma tarefa específica                   |
| PUT    | `/tarefas/{id}` | Atualiza dados ou status de uma tarefa              |
| DELETE | `/tarefas/{id}` | Remove uma tarefa do sistema                        |

### Exemplo de Payload (POST)

```json
{
  "titulo": "Revisão de Defesa - Processo 123",
  "descricao": "Analisar novas evidências do caso.",
  "status": "Pendente",
  "criado_por": "Dr. Arthur"
}
```

## Estrutura do Repositório

- `services/tasks/src`: Código fonte da Lambda e `requirements.txt`.
- `todo-infra/infra`: Arquivos `.tf` para provisionamento do DynamoDB, Lambda e API Gateway.
- `.github/workflows`: Pipeline de CI/CD.

## Boas Práticas Implementadas

- **Tratamento de Erros:** Respostas padronizadas em JSON com códigos HTTP (200, 201, 400, 404, 500).
- **Segurança:** Variáveis sensíveis não expostas no código.
- **Escalabilidade:** Uso de DynamoDB para suportar grandes volumes de acessos sem gargalos de conexão.
