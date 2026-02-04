"""
Helpers:
- normalize_status
- datas (ISO e BR)
- response padronizado (JSON + CORS)
"""

import json
from datetime import datetime, timezone


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


def response(status_code, body):
    """Helper para criar response padronizado"""
    resp = {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    }

    # 204 deve retornar sem body
    if body is None or status_code == 204:
        resp["body"] = ""
    else:
        resp["body"] = json.dumps(body, ensure_ascii=False)

    return resp
