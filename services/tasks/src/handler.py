"""
Lambda Handler para API de Tasks
Exemplo simples de CRUD com DynamoDB
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
            return response(404, {'error': 'Not Found'})

    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})


def create_task(event):
    """Cria uma nova task"""
    body = json.loads(event.get('body', '{}'))

    task = {
        'id': str(uuid.uuid4()),
        'title': body.get('title', 'Untitled'),
        'description': body.get('description', ''),
        'completed': False,
        'created_at': datetime.utcnow().isoformat(),
        'updated_at': datetime.utcnow().isoformat(),
    }

    table.put_item(Item=task)
    return response(201, task)


def list_tasks():
    """Lista todas as tasks"""
    result = table.scan()
    tasks = result.get('Items', [])

    return response(200, {
        'tasks': tasks,
        'count': len(tasks)
    })


def get_task(task_id):
    """Busca uma task por ID"""
    if not task_id:
        return response(400, {'error': 'Task ID is required'})

    result = table.get_item(Key={'id': task_id})
    task = result.get('Item')

    if not task:
        return response(404, {'error': 'Task not found'})

    return response(200, task)


def update_task(task_id, event):
    """Atualiza uma task"""
    if not task_id:
        return response(400, {'error': 'Task ID is required'})

    body = json.loads(event.get('body', '{}'))

    update_expr = 'SET updated_at = :updated_at'
    expr_values = {
        ':updated_at': datetime.utcnow().isoformat()
    }

    if 'title' in body:
        update_expr += ', title = :title'
        expr_values[':title'] = body['title']

    if 'description' in body:
        update_expr += ', description = :description'
        expr_values[':description'] = body['description']

    if 'completed' in body:
        update_expr += ', completed = :completed'
        expr_values[':completed'] = body['completed']

    result = table.update_item(
        Key={'id': task_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_values,
        ReturnValues='ALL_NEW'
    )

    return response(200, result.get('Attributes'))


def delete_task(task_id):
    """Deleta uma task"""
    if not task_id:
        return response(400, {'error': 'Task ID is required'})

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
