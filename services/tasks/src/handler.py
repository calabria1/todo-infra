"""
Lambda Handler para API de Tarefas
CRUD de tarefas com DynamoDB (PK id) + GSI (criado_por + data_criacao)
"""

import json
import os
import uuid
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key


def normalize_status(s):
    if not s:
        return None
    s_norm = str(s).strip().lower()
    mapping = {
        "pendente": "Pendente",
        "pending": "Pendente",
        "pend": "Pendente",
        "em andamento": "Em andamento",
        "em-andamento": "Em andamento",
        "em_andamento": "Em andamento",
        "emandamento": "Em andamento",
        "concluida": "Concluída",
        "concluída": "Concluída",
        "concluido": "Concluída",
        "concluído": "Concluída",
        "concl": "Concluída",
        "feito": "Concluída",
    }
    return mapping.get(s_norm)


def now_iso():
    """Formato ótimo para sort key (ordena corretamente como string)."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def today_br():
    """Formato legível para retornar ao front/usuário."""
    return datetime.now(timezone.utc).strftime("%d/%m/%Y")


# Inicializa cliente DynamoDB
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ.get("TABLE_NAME", "todo-dev-tasks"))


def lambda_handler(event, context):
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "/")
    path_params = event.get("pathParameters") or {}

    # Normalize trailing slash so '/tarefas/' resolves to listing (not item-by-id)
    path = path.rstrip("/")

    try:
        if path == "/tarefas":
            if http_method == "POST":
                return create_task(event)
            if http_method == "GET":
                return list_tasks(event)

        elif path.startswith("/tarefas/"):
            task_id = path_params.get("id")
            if not task_id:
                return response(400, {"error": "ID da tarefa é obrigatório"})

            if http_method == "GET":
                return get_task(task_id)
            if http_method == "PUT":
                return update_task(task_id, event)
            if http_method == "DELETE":
                return delete_task(task_id)

        return response(404, {"error": "Não encontrado"})

    except Exception as e:
        print(f"Error: {e}")
        return response(500, {"error": str(e)})


def create_task(event):
    body = json.loads(event.get("body", "{}") or "{}")

    titulo = body.get("titulo", "Sem título")
    descricao = body.get("descricao", "")
    criado_por = body.get("criado_por", "")

    status = normalize_status(body.get("status")) or "Pendente"

    created_iso = now_iso()
    created_display = today_br()

    data_conclusao = created_display if status == "Concluída" else ""

    task = {
        "id": str(uuid.uuid4()),
        "titulo": titulo,
        "descricao": descricao,
        "status": status,
        "criado_por": criado_por,

        # ✅ USADO PELO GSI (ordenação correta)
        "data_criacao": created_iso,

        # ✅ APENAS PARA EXIBIÇÃO (opcional, mas muito útil)
        "data_criacao_display": created_display,

        "data_conclusao": data_conclusao,
    }

    table.put_item(Item=task)
    return response(201, task)


def list_tasks(event):
    """
    Lista tarefas.
    - Se vier query param 'criado_por' => Query no GSI (criado_por-index) ordenado por data_criacao desc.
    - Se NÃO vier 'criado_por' => Scan na tabela (cumpre requisito "listar todas").
    Paginação: limit + exclusive_start_key (JSON).
    """
    params = event.get("queryStringParameters") or {}

    # limit (default 100)
    try:
        limit = int(params.get("limit", "100")) if params.get("limit") else 100
    except ValueError:
        return response(400, {"error": "limit inválido"})
    limit = max(1, min(limit, 1000))

    exclusive_start_key = None
    if "exclusive_start_key" in params:
        try:
            exclusive_start_key = json.loads(params.get("exclusive_start_key"))
        except Exception:
            return response(400, {"error": "exclusive_start_key inválido"})

    criado_por = params.get("criado_por")

    # ✅ Modo eficiente: Query por usuário (GSI)
    if criado_por:
        query_kwargs = {
            "IndexName": "criado_por-index",
            "KeyConditionExpression": Key("criado_por").eq(criado_por),
            "Limit": limit,
            "ScanIndexForward": False,  # desc por sort key (data_criacao ISO)
        }
        if exclusive_start_key is not None:
            query_kwargs["ExclusiveStartKey"] = exclusive_start_key

        result = table.query(**query_kwargs)
        tarefas = result.get("Items", [])
        last_key = result.get("LastEvaluatedKey")

        body = {"tarefas": tarefas, "total": len(tarefas)}
        if last_key:
            body["last_evaluated_key"] = last_key
        return response(200, body)

    # ✅ Modo requisito literal: Scan (listar todas)
    scan_kwargs = {"Limit": limit}
    if exclusive_start_key is not None:
        scan_kwargs["ExclusiveStartKey"] = exclusive_start_key

    result = table.scan(**scan_kwargs)
    tarefas = result.get("Items", [])
    last_key = result.get("LastEvaluatedKey")

    body = {"tarefas": tarefas, "total": len(tarefas)}
    if last_key:
        body["last_evaluated_key"] = last_key

    return response(200, body)


def get_task(task_id):
    """Busca uma task por ID"""
    result = table.get_item(Key={"id": task_id})
    task = result.get("Item")

    if not task:
        return response(404, {"error": "Tarefa não encontrada"})

    return response(200, task)


def update_task(task_id, event):
    body = json.loads(event.get("body", "{}") or "{}")

    current = table.get_item(Key={"id": task_id}).get("Item")
    if not current:
        return response(404, {"error": "Tarefa não encontrada"})

    parts = []
    values = {}
    names = {}

    if "titulo" in body:
        parts.append("#titulo = :titulo")
        values[":titulo"] = body["titulo"]
        names["#titulo"] = "titulo"

    if "descricao" in body:
        parts.append("#descricao = :descricao")
        values[":descricao"] = body["descricao"]
        names["#descricao"] = "descricao"

    if "status" in body:
        new_status = normalize_status(body.get("status"))
        if new_status is None:
            return response(400, {"error": "Status inválido"})

        old_status = current.get("status")

        parts.append("#status = :status")
        values[":status"] = new_status
        names["#status"] = "status"

        hoje_br = today_br()
        if old_status != "Concluída" and new_status == "Concluída":
            parts.append("#data_conclusao = :data_conclusao")
            values[":data_conclusao"] = hoje_br
            names["#data_conclusao"] = "data_conclusao"

        if old_status == "Concluída" and new_status != "Concluída":
            parts.append("#data_conclusao = :data_conclusao")
            values[":data_conclusao"] = ""
            names["#data_conclusao"] = "data_conclusao"

    if not parts:
        return response(400, {"error": "Nenhum campo permitido para atualizar"})

    update_expr = "SET " + ", ".join(parts)

    params = {
        "Key": {"id": task_id},
        "UpdateExpression": update_expr,
        "ExpressionAttributeValues": values,
        "ReturnValues": "ALL_NEW",
    }
    if names:
        params["ExpressionAttributeNames"] = names

    result = table.update_item(**params)
    return response(200, result.get("Attributes"))


def delete_task(task_id):
    """Deleta uma tarefa"""
    table.delete_item(Key={"id": task_id})
    return response(204, None)


def response(status_code, body):
    """Helper para criar response padronizado"""
    resp = {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    }
    if body is None or status_code == 204:
        resp["body"] = ""
    else:
        resp["body"] = json.dumps(body, ensure_ascii=False)
    return resp
