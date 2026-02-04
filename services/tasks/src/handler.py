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

# Inicializa cliente DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME', 'todo-dev-tasks'))


def lambda_handler(event, context):
    """Handler principal da Lambda"""
    http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path = event.get('rawPath', '/')
    path_params = event.get('pathParameters') or {}

    try:
        if path == '/tarefas' and http_method == 'POST':
            return create_task(event)

        elif path == '/tarefas' and http_method == 'GET':
            return list_tasks()

        elif '/tarefas/' in path and http_method == 'GET':
            return get_task(path_params.get('id'))

        elif '/tarefas/' in path and http_method == 'PUT':
            return update_task(path_params.get('id'), event)

        elif '/tarefas/' in path and http_method == 'DELETE':
            return delete_task(path_params.get('id'))

        else:
            return response(404, {'error': 'Não encontrado'})

    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})


def create_task(event):
    """Cria uma nova tarefa a partir do payload esperado em PT"""
    body = json.loads(event.get('body', '{}'))

    titulo = body.get('titulo', 'Sem título')
    descricao = body.get('descricao', '')
    status = body.get('status', 'Pendente')
    criado_por = body.get('criado_por', '')
    data_criacao = body.get('data_criacao') or datetime.utcnow().strftime('%d/%m/%Y')
    data_conclusao = body.get('data_conclusao', '')

    task = {
        'id': str(uuid.uuid4()),
        'titulo': titulo,
        'descricao': descricao,
        'status': status,
        'criado_por': criado_por,
        'data_criacao': data_criacao,
        'data_conclusao': data_conclusao,
    }

    table.put_item(Item=task)
    return response(201, task)


def list_tasks():
    """Lista todas as tarefas"""
    result = table.scan()
    tarefas = result.get('Items', [])

    return response(200, {
        'tarefas': tarefas,
        'total': len(tarefas)
    })


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
    """Atualiza uma tarefa a partir do payload em PT"""
    if not task_id:
        return response(400, {'error': 'ID da tarefa é obrigatório'})

    body = json.loads(event.get('body', '{}'))

    update_expr_parts = []
    expr_values = {}

    if 'titulo' in body:
        update_expr_parts.append('titulo = :titulo')
        expr_values[':titulo'] = body['titulo']

    if 'descricao' in body:
        update_expr_parts.append('descricao = :descricao')
        expr_values[':descricao'] = body['descricao']

    if 'status' in body:
        update_expr_parts.append('status = :status')
        expr_values[':status'] = body['status']

    if 'criado_por' in body:
        update_expr_parts.append('criado_por = :criado_por')
        expr_values[':criado_por'] = body['criado_por']

    if 'data_criacao' in body:
        update_expr_parts.append('data_criacao = :data_criacao')
        expr_values[':data_criacao'] = body['data_criacao']

    if 'data_conclusao' in body:
        update_expr_parts.append('data_conclusao = :data_conclusao')
        expr_values[':data_conclusao'] = body['data_conclusao']

    if not update_expr_parts:
        return response(400, {'error': 'Nenhum campo para atualizar'})

    update_expr = 'SET ' + ', '.join(update_expr_parts)

    result = table.update_item(
        Key={'id': task_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_values,
        ReturnValues='ALL_NEW'
    )

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
