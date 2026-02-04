import os
from flask import Flask, request, Response

from handler import lambda_handler

app = Flask(__name__)


def _event_v2(path: str, method: str, body_text: str | None):
    query = request.args.to_dict(flat=True) if request.args else None
    headers = {k: v for k, v in request.headers.items()}

    # compatível com seu handler: ele usa pathParameters["id"] quando path começa com /tarefas/
    path_params = None
    if path.startswith("/tarefas/"):
        parts = path.split("/", 2)
        if len(parts) >= 3 and parts[2]:
            path_params = {"id": parts[2]}

    return {
        "version": "2.0",
        "rawPath": path,
        "rawQueryString": request.query_string.decode("utf-8") if request.query_string else "",
        "headers": headers,
        "queryStringParameters": query,
        "pathParameters": path_params,
        "requestContext": {"http": {"method": method, "path": path}},
        "isBase64Encoded": False,
        "body": body_text,
    }


@app.route("/tarefas", methods=["GET", "POST", "OPTIONS"])
@app.route("/tarefas/<task_id>", methods=["GET", "PUT", "DELETE", "OPTIONS"])
def tarefas(task_id=None):
    if request.method == "OPTIONS":
        return Response(
            "",
            status=204,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
                "Access-Control-Allow-Headers": "*",
            },
        )

    body_text = request.data.decode("utf-8") if request.data else None
    event = _event_v2(request.path, request.method, body_text)
    resp = lambda_handler(event, None)

    return Response(
        resp.get("body", ""),
        status=resp.get("statusCode", 200),
        headers=resp.get("headers") or {},
    )


if __name__ == "__main__":
    port = int(os.getenv("PORT", "3000"))
    app.run(host="0.0.0.0", port=port, debug=True)
