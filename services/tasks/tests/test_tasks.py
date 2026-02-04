import json
import os
import re
import sys
from pathlib import Path

import boto3
import pytest
from moto import mock_dynamodb

SRC_PATH = Path(__file__).resolve().parents[1] / "src"
sys.path.insert(0, str(SRC_PATH))


@pytest.fixture()
def tasks_module(monkeypatch):
    with mock_dynamodb():
        monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
        monkeypatch.setenv("TABLE_NAME", "todo-dev-tasks")

        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb.create_table(
            TableName=os.environ["TABLE_NAME"],
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "id", "AttributeType": "S"},
                {"AttributeName": "criado_por", "AttributeType": "S"},
                {"AttributeName": "data_criacao", "AttributeType": "S"},
            ],
            BillingMode="PAY_PER_REQUEST",
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
        table.wait_until_exists()

        import dynamodb_client
        import tasks

        tasks.table = table

        yield tasks


def test_create_task(tasks_module):
    event = {
        "body": json.dumps(
            {
                "titulo": "Tarefa 1",
                "descricao": "Detalhes",
                "status": "pendente",
                "criado_por": "maria",
            }
        )
    }

    response = tasks_module.create_task(event)

    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert body["titulo"] == "Tarefa 1"
    assert body["descricao"] == "Detalhes"
    assert body["status"] == "Pendente"
    assert body["criado_por"] == "maria"


def test_create_task_default_values(tasks_module):
    event = {"body": json.dumps({"criado_por": "ana"})}

    response = tasks_module.create_task(event)

    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert body["titulo"] == "Sem título"
    assert body["descricao"] == ""
    assert body["status"] == "Pendente"
    assert body["data_conclusao"] == ""


def test_normalize_status():
    from utils import normalize_status

    assert normalize_status("pendente") == "Pendente"
    assert normalize_status("em andamento") == "Em andamento"
    assert normalize_status("feito") == "Concluída"


def test_normalize_status_invalido():
    from utils import normalize_status

    assert normalize_status("") is None
    assert normalize_status("desconhecido") is None


def test_response_helper():
    from utils import response

    resp = response(200, {"ok": True})

    assert resp["statusCode"] == 200
    assert resp["headers"]["Content-Type"] == "application/json"
    assert json.loads(resp["body"]) == {"ok": True}


def test_response_204_no_body():
    from utils import response

    resp = response(204, {"ok": True})

    assert resp["statusCode"] == 204
    assert resp["body"] == ""


def test_today_br_format():
    from utils import today_br

    assert re.match(r"^\d{2}/\d{2}/\d{4}$", today_br())


def test_now_iso_format():
    from utils import now_iso

    assert re.match(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$", now_iso())
