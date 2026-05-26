from __future__ import annotations

from uuid import uuid4

from fastapi import FastAPI, HTTPException, Query, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .database import (
    contact_from_row,
    conversation_from_row,
    get_connection,
    init_db,
    isoformat,
    message_from_row,
    utc_now,
)

app = FastAPI(title="Vibe IM API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:8080",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://localhost:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class CreateMessageRequest(BaseModel):
    content: str = Field(min_length=1, max_length=4000)
    sender_id: str = "me"
    sender_name: str = "我"


@app.on_event("startup")
def on_startup() -> None:
    init_db()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/conversations")
def list_conversations(
    q: str | None = Query(default=None, max_length=120),
) -> dict[str, list[dict]]:
    query = q.strip() if q else ""
    with get_connection() as connection:
        if query:
            rows = connection.execute(
                """
                SELECT *
                FROM conversations
                WHERE title LIKE ?
                    OR last_message LIKE ?
                    OR tags_json LIKE ?
                ORDER BY is_pinned DESC, last_message_at DESC
                """,
                (f"%{query}%", f"%{query}%", f"%{query}%"),
            ).fetchall()
        else:
            rows = connection.execute(
                """
                SELECT *
                FROM conversations
                ORDER BY is_pinned DESC, last_message_at DESC
                """
            ).fetchall()

    return {"items": [conversation_from_row(row) for row in rows]}


@app.get("/api/conversations/{conversation_id}")
def get_conversation(conversation_id: str) -> dict:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM conversations WHERE id = ?",
            (conversation_id,),
        ).fetchone()

    if row is None:
        raise HTTPException(status_code=404, detail="Conversation not found")

    return conversation_from_row(row)


@app.get("/api/contacts")
def list_contacts(
    q: str | None = Query(default=None, max_length=120),
) -> dict[str, list[dict]]:
    query = q.strip() if q else ""
    with get_connection() as connection:
        if query:
            rows = connection.execute(
                """
                SELECT *
                FROM contacts
                WHERE name LIKE ?
                    OR department LIKE ?
                    OR title LIKE ?
                    OR email LIKE ?
                ORDER BY is_favorite DESC, name ASC
                """,
                (f"%{query}%", f"%{query}%", f"%{query}%", f"%{query}%"),
            ).fetchall()
        else:
            rows = connection.execute(
                """
                SELECT *
                FROM contacts
                ORDER BY is_favorite DESC, name ASC
                """
            ).fetchall()

    return {"items": [contact_from_row(row) for row in rows]}


@app.get("/api/contacts/{contact_id}")
def get_contact(contact_id: str) -> dict:
    with get_connection() as connection:
        row = connection.execute(
            "SELECT * FROM contacts WHERE id = ?",
            (contact_id,),
        ).fetchone()

    if row is None:
        raise HTTPException(status_code=404, detail="Contact not found")

    return contact_from_row(row)


@app.get("/api/conversations/{conversation_id}/messages")
def list_messages(conversation_id: str) -> dict[str, list[dict]]:
    ensure_conversation_exists(conversation_id)
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT *
            FROM messages
            WHERE conversation_id = ?
            ORDER BY created_at ASC
            """,
            (conversation_id,),
        ).fetchall()

    return {"items": [message_from_row(row) for row in rows]}


@app.post(
    "/api/conversations/{conversation_id}/messages",
    status_code=status.HTTP_201_CREATED,
)
def create_message(conversation_id: str, payload: CreateMessageRequest) -> dict:
    ensure_conversation_exists(conversation_id)
    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Message content is required")

    message_id = f"msg_{uuid4().hex}"
    created_at = isoformat(utc_now())

    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO messages (
                id, conversation_id, sender_id, sender_name, type,
                content, created_at, status, is_mine
            )
            VALUES (?, ?, ?, ?, 'text', ?, ?, 'sent', ?)
            """,
            (
                message_id,
                conversation_id,
                payload.sender_id,
                payload.sender_name,
                content,
                created_at,
                1 if payload.sender_id == "me" else 0,
            ),
        )
        connection.execute(
            """
            UPDATE conversations
            SET last_message = ?, last_message_at = ?
            WHERE id = ?
            """,
            (content, created_at, conversation_id),
        )
        row = connection.execute(
            "SELECT * FROM messages WHERE id = ?",
            (message_id,),
        ).fetchone()

    return message_from_row(row)


@app.patch(
    "/api/conversations/{conversation_id}/read",
    status_code=status.HTTP_204_NO_CONTENT,
)
def mark_conversation_read(conversation_id: str) -> Response:
    ensure_conversation_exists(conversation_id)
    with get_connection() as connection:
        connection.execute(
            "UPDATE conversations SET unread_count = 0 WHERE id = ?",
            (conversation_id,),
        )

    return Response(status_code=status.HTTP_204_NO_CONTENT)


def ensure_conversation_exists(conversation_id: str) -> None:
    with get_connection() as connection:
        exists = connection.execute(
            "SELECT 1 FROM conversations WHERE id = ?",
            (conversation_id,),
        ).fetchone()

    if exists is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
