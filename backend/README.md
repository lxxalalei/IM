# Vibe IM Backend

本地后端 MVP，使用 FastAPI + SQLite。

数据库文件默认保存在：

```text
backend/data/vibe_im.sqlite3
```

## 运行

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## 接口

- `GET /health`
- `GET /api/conversations`
- `GET /api/conversations/{conversation_id}`
- `GET /api/conversations/{conversation_id}/messages`
- `POST /api/conversations/{conversation_id}/messages`
- `PATCH /api/conversations/{conversation_id}/read`
- `GET /api/contacts`
- `GET /api/contacts/{contact_id}`

## API 文档

启动后打开：

```text
http://127.0.0.1:8000/docs
```

## 验证

服务启动后运行：

```bash
.venv/bin/python scripts/smoke_test.py
```
