API Serverless de Gerenciamento de Tarefas (To-Do)Esta API foi desenvolvida para permitir que advogados gerenciem suas tarefas diárias de forma eficiente e escalável. A solução utiliza uma arquitetura 100% Serverless na AWS, focando em baixo custo, alta disponibilidade e facilidade de manutenção.🏗️ Arquitetura e TecnologiasA solução é composta pelos seguintes componentes:Linguagem: Python 3.10Compute: AWS Lambda (Stateless)API Layer: AWS API Gateway (REST/HTTP)Banco de Dados: Amazon DynamoDB (NoSQL)Infraestrutura como Código (IaC): TerraformCI/CD: GitHub Actions (Deploy automatizado)Desenho da SoluçãoUsuário -> API Gateway -> Lambda -> DynamoDB🚀 Como realizar o Deploy (AWS)O deploy é automatizado. Ao realizar um push para a branch main, o GitHub Actions valida a infraestrutura e realiza o deploy.Pré-requisitosConta AWS ativa.Bucket S3 criado manualmente para armazenar o tfstate do Terraform (ex: meu-projeto-tfstate).Configuração de OIDC ou Usuário IAM com permissões de Administrator para o GitHub Actions.Configuração de Secrets no GitHubNo seu repositório, vá em Settings > Secrets and variables > Actions e adicione:AWS_ROLE_ARN: ARN da Role que o GitHub irá assumir.AWS_REGION: Ex: us-east-1.S3_BUCKET_ARTIFACTS: Nome do bucket para armazenar os arquivos .zip da Lambda.💻 Execução LocalPara testar a lógica da aplicação (handlers e validações) sem subir para a AWS:1. Preparar o AmbienteBash# Entrar na pasta do serviço
cd services/tasks/src

# Criar e ativar ambiente virtual
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt
2. Configurar Variáveis de AmbienteBash# Linux/Mac
export TABLE_NAME=gestao-tarefas-dev-tarefas
export AWS_DEFAULT_REGION=us-east-1

# Windows (PowerShell)
$env:TABLE_NAME="gestao-tarefas-dev-tarefas"
$env:AWS_DEFAULT_REGION="us-east-1"
3. Rodar Teste de Integração Local crie um arquivo local_test.py (ou use o existente) para simular uma chamada:Pythonfrom handler import lambda_handler

mock_event = {
    "requestContext": {"http": {"method": "GET"}},
    "rawPath": "/tarefas",
    "queryStringParameters": {"criado_por": "arthur"}
}

print(lambda_handler(mock_event, None))
Execute com: python local_test.py🛣️ Endpoints da APIMétodoEndpointDescriçãoPOST/tarefasCria uma nova tarefa.GET/tarefasLista todas as tarefas (suporta filtro por criado_por).GET/tarefas/{id}Detalhes de uma tarefa específica.PUT/tarefas/{id}Atualiza dados ou status de uma tarefa.DELETE/tarefas/{id}Remove uma tarefa do sistema.Exemplo de Payload (POST)JSON{
    "titulo": "Revisão de Defesa - Processo 123",
    "descricao": "Analisar novas evidências do caso.",
    "status": "Pendente",
    "criado_por": "Dr. Arthur"
}
📂 Estrutura do Repositório/services/tasks/src: Código fonte da Lambda e requirements.txt./todo-infra/infra: Arquivos .tf para provisionamento do DynamoDB, Lambda e API Gateway./.github/workflows: Pipeline de CI/CD.✅ Boas Práticas ImplementadasTratamento de Erros: Respostas padronizadas em JSON com códigos HTTP (200, 201, 400, 404, 500).Segurança: Variáveis sensíveis não expostas no código.Escalabilidade: Uso de DynamoDB para suportar grandes volumes de acessos sem gargalos de conexão.