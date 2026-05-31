import uuid
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

AGENT_CARD = {
    "name": "abox-a2a-agent",
    "description": "Simple A2A agent deployed on abox cluster",
    "url": "http://a2a-agent.kagent.svc.cluster.local",
    "version": "1.0.0",
    "capabilities": {
        "streaming": False,
        "pushNotifications": False,
    },
    "skills": [
        {
            "id": "echo",
            "name": "Echo",
            "description": "Echoes back the input message",
            "inputModes": ["text"],
            "outputModes": ["text"],
            "examples": ["say hello", "repeat after me: test"],
        }
    ],
}


@app.get("/.well-known/agent.json")
async def agent_card():
    return JSONResponse(content=AGENT_CARD)


@app.post("/")
async def send_message(request: Request):
    body = await request.json()

    params = body.get("params", {})
    message = params.get("message", {})
    parts = message.get("parts", [])
    text = parts[0].get("text", "") if parts else ""
    task_id = params.get("taskId", str(uuid.uuid4()))

    return {
        "jsonrpc": "2.0",
        "id": body.get("id"),
        "result": {
            "id": task_id,
            "status": {"state": "completed"},
            "artifacts": [
                {
                    "parts": [{"type": "text", "text": f"Echo: {text}"}]
                }
            ],
        },
    }
