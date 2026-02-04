API Serverless de Gerenciamento de Tarefas (To-Do)Esta API foi desenvolvida para permitir que advogados gerenciem suas tarefas diárias de forma eficiente e escalável. A solução utiliza uma arquitetura 100% Serverless na AWS, focando em baixo custo, alta disponibilidade e facilidade de manutenção.🏗️ Arquitetura e TecnologiasLinguagem: Python 3.11 (Produção) / Python Local (Windows Launcher)Compute: AWS Lambda (Stateless)API: API Gateway HTTP (Payload v2.0)Banco de Dados: DynamoDB (NoSQL)Infraestrutura: TerraformCI/CD: GitHub Actions (Deploy automatizado)🚀 Como realizar o Deploy (AWS)O deploy é automatizado via pipeline. Ao realizar um push para a branch main, o GitHub Actions valida a infraestrutura e realiza o deploy.Pré-requisitosConta AWS ativa.Bucket S3 criado manualmente para armazenar o tfstate do Terraform.OIDC ou Usuário IAM com permissões adequadas.Secrets do GitHubEm Settings > Secrets and variables > Actions, configure:AWS_ROLE_ARN / AWS_REGION / S3_BUCKET_ARTIFACTS💻 Execução Local (Desenvolvimento)Esta seção explica o fluxo para desenvolvimento local utilizando DynamoDB Local e um servidor Flask para emular o API Gateway, sem custos e sem alterar a produção.⚠️ Importante: O modo local é ativado apenas quando a variável DYNAMODB_ENDPOINT está definida. Na AWS, essa variável não existe, garantindo o comportamento nativo.1. Pré-requisitos Locais (Windows)Java (para rodar o DynamoDB Local)Python instalado via launcher pyPowerShell2. Rodar o DynamoDB LocalBaixe a versão executável na documentação oficial da AWS.Extraia e execute no terminal:PowerShellcd C:\caminho\para\diretorio_extraido
java "-Djava.library.path=.\DynamoDBLocal_lib" -jar .\DynamoDBLocal.jar -sharedDb -port 8000
O banco estará disponível em: http://localhost:8000. Subir a API LocalNo diretório services/tasks/src, execute:PowerShell# Criar e ativar ambiente virtual
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
🛣️ Endpoints da API (Local: http://127.0.0.1:3000)MétodoEndpointDescriçãoPOST/tarefasCria uma nova tarefa via JSON.GET/tarefasLista todas as tarefas locais.GET/tarefas/{id}Busca uma tarefa específica por UUID.PUT/tarefas/{id}Atualiza dados ou status da tarefa.DELETE/tarefas/{id}Remove a tarefa do DynamoDB Local.📂 Estrutura do Repositórioservices/tasks/src: Código da Lambda, local_server.py e lógica de negócio.todo-infra/infra: Arquivos Terraform (Iac)..github/workflows: Definições do pipeline de CI/CD.