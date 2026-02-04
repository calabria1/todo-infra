"""
Inicialização do DynamoDB (boto3) e acesso à tabela.
Centralizar aqui evita repetição e facilita manutenção/testes.
"""

import os
import boto3

dynamodb = boto3.resource("dynamodb")

# Mantém default para não quebrar execução local se TABLE_NAME não estiver setado
TABLE_NAME = os.environ.get("TABLE_NAME", "todo-dev-tasks")

table = dynamodb.Table(TABLE_NAME)
