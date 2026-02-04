"""
Lambda Handler para API de Tarefas
Exemplo simples de CRUD de tarefas com DynamoDB
"""

import json
import os
import uuid
from datetime import datetime

import boto3
from boto3.dynamodb.conditions import Key


def normalize_status(s):
    if not s:
        return None
    s_norm = str(s).strip().lower()
    mapping = {
        'pendente': 'Pendente', 'pending': 'Pendente', 'pend': 'Pendente',
        'em andamento': 'Em andamento', 'em-andamento': 'Em andamento', 'em_andamento': 'Em andamento', 'emandamento': 'Em andamento',
        'concluida': 'Concluída', 'concluída': 'Concluída', 'concluido': 'Concluída', 'concluído': 'Concluída', 'concl': 'Concluída', 'feito': 'Concluída'
    }
    return mapping.get(s_norm)


# Inicializa cliente DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME', 'todo-dev-tasks'))


def lambda_handler(event, context):
    http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path = event.get('rawPath', '/')
    path_params = event.get('pathParameters') or {}

    # Normalize trailing slash so '/tarefas/' resolves to listing (not to item-by-id)
    path = path.rstrip('/')

    try:
        if path == '/tarefas':
            if http_method == 'POST':
                return create_task(event)
            if http_method == 'GET':
                return list_tasks(event)
        elif path.startswith('/tarefas/'):
            task_id = path_params.get('id')
            if not task_id:
                return response(400, {'error': 'ID da tarefa é obrigatório'})
            if http_method == 'GET':
                return get_task(task_id)
            if http_method == 'PUT':
                return update_task(task_id, event)
            if http_method == 'DELETE':
                return delete_task(task_id)
        return response(404, {'error': 'Não encontrado'})

    except Exception as e:
        print(f"Error: {e}")
        return response(500, {'error': str(e)})


def create_task(event):
    body = json.loads(event.get('body', '{}'))
    titulo = body.get('titulo', 'Sem título')
    descricao = body.get('descricao', '')
    criado_por = body.get('criado_por', '')

    status = normalize_status(body.get('status')) or 'Pendente'
    hoje = datetime.utcnow().strftime('%d/%m/%Y')
    data_conclusao = hoje if status == 'Concluída' else ''

    task = {
        'id': str(uuid.uuid4()),
        'pk': 'TASK',
        'titulo': titulo,
        'descricao': descricao,
        'status': status,
        'criado_por': criado_por,
        'data_criacao': hoje,
        'data_conclusao': data_conclusao,
    }

    table.put_item(Item=task)
    return response(201, task)


def list_tasks(event):
    """Lista tarefas com suporte a filtros via GSI e paginação"""
    params = event.get('queryStringParameters') or {}
    # limit (default 100)
    try:
        limit = int(params.get('limit', '100')) if params.get('limit') else 100
    except ValueError:
        return response(400, {'error': 'limit inválido'})

    exclusive_start_key = None
    if 'exclusive_start_key' in params:
        try:
            exclusive_start_key = json.loads(params.get('exclusive_start_key'))
        except Exception:
            return response(400, {'error': 'exclusive_start_key inválido'})

    # Query by status
    if 'status' in params:
        status = params['status']
        result = table.query(
            IndexName='status-index',
            KeyConditionExpression=Key('status').eq(status),
            Limit=limit,
            ExclusiveStartKey=exclusive_start_key
        )
    elif 'criado_por' in params:
        criado_por = params['criado_por']
        result = table.query(
            IndexName='criado_por-index',
            KeyConditionExpression=Key('criado_por').eq(criado_por),
            Limit=limit,
            ExclusiveStartKey=exclusive_start_key,
            ScanIndexForward=False
        )
    else:
        # default: return recent tasks via all_tasks-index (avoid full table scan)
        result = table.query(
            IndexName='all_tasks-index',
            KeyConditionExpression=Key('pk').eq('TASK'),
            Limit=limit,
            ExclusiveStartKey=exclusive_start_key,
            ScanIndexForward=False
        )

    tarefas = result.get('Items', [])
    last_key = result.get('LastEvaluatedKey')
    body = {'tarefas': tarefas, 'total': len(tarefas)}
    if last_key:
        body['last_evaluated_key'] = last_key

    return response(200, body)


def get_task(task_id):
    """Busca uma task por ID"""
    if not task_id:
        return response(400, {'error': 'ID da tarefa é obrigatório'})

    result = table.get_item(Key={'id': task_id})
    task = result.get('Item')

    if not task:
        return response(404, {'error': 'Tarefa não encontrada'})

    return response(200, task)


def update_task(task_id, event):
    if not task_id:
        return response(400, {'error': 'ID da tarefa é obrigatório'})

    body = json.loads(event.get('body', '{}'))
    current = table.get_item(Key={'id': task_id}).get('Item')
    if not current:
        return response(404, {'error': 'Tarefa não encontrada'})

    parts = []
    values = {}
    names = {}

    if 'titulo' in body:
        parts.append('#titulo = :titulo')
        values[':titulo'] = body['titulo']
        names['#titulo'] = 'titulo'

    if 'descricao' in body:
        parts.append('#descricao = :descricao')
        values[':descricao'] = body['descricao']
        names['#descricao'] = 'descricao'

    if 'status' in body:
        new_status = normalize_status(body.get('status'))
        if new_status is None:
            return response(400, {'error': 'Status inválido'})
        old_status = current.get('status')
        parts.append('#status = :status')
        values[':status'] = new_status
        names['#status'] = 'status'

        hoje = datetime.utcnow().strftime('%d/%m/%Y')
        if old_status != 'Concluída' and new_status == 'Concluída':
            parts.append('#data_conclusao = :data_conclusao')
            values[':data_conclusao'] = hoje
            names['#data_conclusao'] = 'data_conclusao'
        if old_status == 'Concluída' and new_status != 'Concluída':
            parts.append('#data_conclusao = :data_conclusao')
            values[':data_conclusao'] = ''
            names['#data_conclusao'] = 'data_conclusao'

    if not parts:
        return response(400, {'error': 'Nenhum campo permitido para atualizar'})

    update_expr = 'SET ' + ', '.join(parts)
    params = {'Key': {'id': task_id}, 'UpdateExpression': update_expr, 'ExpressionAttributeValues': values, 'ReturnValues': 'ALL_NEW'}
    if names:
        params['ExpressionAttributeNames'] = names

    result = table.update_item(**params)
    return response(200, result.get('Attributes'))


def delete_task(task_id):
    """Deleta uma tarefa"""
    if not task_id:
        return response(400, {'error': 'ID da tarefa é obrigatório'})

    table.delete_item(Key={'id': task_id})
    return response(204, None)


def response(status_code, body):
    """Helper para criar response padronizado"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body) if body else ''
    }
