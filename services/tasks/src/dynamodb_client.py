import os
import boto3
from botocore.exceptions import ClientError

# Região: pega do ambiente (AWS) ou cai num default seguro
REGION = os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION") or "sa-east-1"

# Tabela na AWS vem do Terraform via TABLE_NAME.
# Local: se não setar TABLE_NAME, usa o mesmo padrão do dev.
PROJECT = os.getenv("PROJECT", "gestao-tarefas")
ENV = os.getenv("ENV", "dev")
DEFAULT_TABLE_NAME = f"{PROJECT}-{ENV}-tarefas"

TABLE_NAME = os.getenv("TABLE_NAME", DEFAULT_TABLE_NAME)

# Se existir => modo local (DynamoDB Local)
DYNAMODB_ENDPOINT = os.getenv("DYNAMODB_ENDPOINT")  # ex: http://localhost:8000


def _dynamodb_resource():
    if DYNAMODB_ENDPOINT:
        return boto3.resource(
            "dynamodb",
            region_name=REGION,
            endpoint_url=DYNAMODB_ENDPOINT,
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "local"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "local"),
        )

    # AWS normal (Lambda/credenciais do ambiente)
    return boto3.resource("dynamodb", region_name=REGION)


dynamodb = _dynamodb_resource()
table = dynamodb.Table(TABLE_NAME)


def ensure_table_exists():
    """
    Só cria tabela no modo LOCAL.
    Em AWS não faz nada (zero impacto no deploy).
    """
    if not DYNAMODB_ENDPOINT:
        return

    client = dynamodb.meta.client
    try:
        client.describe_table(TableName=TABLE_NAME)
        return
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") != "ResourceNotFoundException":
            raise

    client.create_table(
        TableName=TABLE_NAME,
        BillingMode="PAY_PER_REQUEST",
        AttributeDefinitions=[
            {"AttributeName": "id", "AttributeType": "S"},
            {"AttributeName": "criado_por", "AttributeType": "S"},
            {"AttributeName": "data_criacao", "AttributeType": "S"},
        ],
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        GlobalSecondaryIndexes=[
            {
                "IndexName": "criado_por-index",
                "KeySchema": [
                    {"AttributeName": "criado_por", "KeyType": "HASH"},
                    {"AttributeName": "data_criacao", "KeyType": "RANGE"},
                ],
                "Projection": {"ProjectionType": "ALL"},
            }
        ],
    )

    waiter = client.get_waiter("table_exists")
    waiter.wait(TableName=TABLE_NAME)
