"""
Lambda Handler para API de Tarefas
Roteamento (API Gateway HTTP API) -> funções de negócio em tasks.py
"""

from tasks import create_task, list_tasks, get_task, update_task, delete_task
from utils import response


def lambda_handler(event, context):
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "/") or "/"
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
