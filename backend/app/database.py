from __future__ import annotations

import json
import sqlite3
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
DB_PATH = DATA_DIR / "vibe_im.sqlite3"


def utc_now() -> datetime:
    return datetime.now(UTC)


def isoformat(value: datetime) -> str:
    return value.isoformat(timespec="seconds").replace("+00:00", "Z")


def get_connection() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def init_db() -> None:
    with get_connection() as connection:
        connection.executescript(
            """
            CREATE TABLE IF NOT EXISTS conversations (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                title TEXT NOT NULL,
                avatar_label TEXT NOT NULL,
                avatar_color TEXT NOT NULL,
                tags_json TEXT NOT NULL DEFAULT '[]',
                last_message TEXT NOT NULL DEFAULT '',
                last_message_at TEXT NOT NULL,
                unread_count INTEGER NOT NULL DEFAULT 0,
                is_pinned INTEGER NOT NULL DEFAULT 0,
                is_muted INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                conversation_id TEXT NOT NULL,
                sender_id TEXT NOT NULL,
                sender_name TEXT NOT NULL,
                type TEXT NOT NULL DEFAULT 'text',
                content TEXT NOT NULL,
                created_at TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'sent',
                is_mine INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (conversation_id)
                    REFERENCES conversations(id)
                    ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
            ON messages(conversation_id, created_at);

            CREATE TABLE IF NOT EXISTS contacts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                avatar_label TEXT NOT NULL,
                avatar_color TEXT NOT NULL,
                department TEXT NOT NULL DEFAULT '',
                title TEXT NOT NULL DEFAULT '',
                email TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'offline',
                is_external INTEGER NOT NULL DEFAULT 0,
                is_favorite INTEGER NOT NULL DEFAULT 0
            );

            CREATE INDEX IF NOT EXISTS idx_contacts_name
            ON contacts(name);
            """
        )

        count = connection.execute("SELECT COUNT(*) FROM conversations").fetchone()[0]
        if count == 0:
            seed_database(connection)

        contact_count = connection.execute("SELECT COUNT(*) FROM contacts").fetchone()[0]
        if contact_count == 0:
            seed_contacts(connection)


def seed_database(connection: sqlite3.Connection) -> None:
    now = utc_now()
    conversations = [
        {
            "id": "qianli",
            "type": "direct",
            "title": "千里马",
            "avatar_label": "千",
            "avatar_color": "#E6332A",
            "tags": ["外部"],
            "last_message": "我接受了你的联系人申请，开始聊天吧！",
            "last_message_at": now - timedelta(minutes=8),
            "unread_count": 0,
        },
        {
            "id": "official",
            "type": "system",
            "title": "用户602472的飞书",
            "avatar_label": "官",
            "avatar_color": "#4C83FF",
            "tags": ["官方"],
            "last_message": "飞书助手：解锁@影视飓风同款生产力...",
            "last_message_at": now - timedelta(days=2),
            "unread_count": 2,
        },
        {
            "id": "azhe",
            "type": "direct",
            "title": "阿拉蕾",
            "avatar_label": "阿",
            "avatar_color": "#FF7043",
            "tags": ["智能体"],
            "last_message": "hello！有什么想聊的？",
            "last_message_at": now - timedelta(days=4),
            "unread_count": 0,
        },
        {
            "id": "security",
            "type": "bot",
            "title": "账号安全中心",
            "avatar_label": "盾",
            "avatar_color": "#2F80ED",
            "tags": ["机器人"],
            "last_message": "安全登录通知",
            "last_message_at": now - timedelta(days=4, minutes=40),
            "unread_count": 0,
        },
        {
            "id": "token",
            "type": "bot",
            "title": "妙搭助手",
            "avatar_label": "妙",
            "avatar_color": "#6C63FF",
            "tags": ["机器人"],
            "last_message": "飞书 OpenClaw 免费 Token 已到账",
            "last_message_at": now - timedelta(days=4, hours=2),
            "unread_count": 0,
        },
    ]

    for conversation in conversations:
        connection.execute(
            """
            INSERT INTO conversations (
                id, type, title, avatar_label, avatar_color, tags_json,
                last_message, last_message_at, unread_count
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                conversation["id"],
                conversation["type"],
                conversation["title"],
                conversation["avatar_label"],
                conversation["avatar_color"],
                json.dumps(conversation["tags"], ensure_ascii=False),
                conversation["last_message"],
                isoformat(conversation["last_message_at"]),
                conversation["unread_count"],
            ),
        )

    seed_messages = [
        ("m_q_1", "qianli", "u_qianli", "千里马", "text", "我接受了你的联系人申请，开始聊天吧！", now - timedelta(minutes=8), 0),
        ("m_o_1", "official", "bot_official", "飞书助手", "text", "欢迎回来，这里会展示官方通知和产品动态。", now - timedelta(days=2), 0),
        ("m_a_1", "azhe", "u_azhe", "阿拉蕾", "text", "hello！有什么想聊的？", now - timedelta(days=4), 0),
        ("m_a_2", "azhe", "me", "我", "text", "先把 IM 的桌面端骨架做起来。", now - timedelta(days=4, minutes=-3), 1),
    ]
    for message in seed_messages:
        connection.execute(
            """
            INSERT INTO messages (
                id, conversation_id, sender_id, sender_name, type,
                content, created_at, is_mine
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                message[0],
                message[1],
                message[2],
                message[3],
                message[4],
                message[5],
                isoformat(message[6]),
                message[7],
            ),
        )


def seed_contacts(connection: sqlite3.Connection) -> None:
    contacts = [
        {
            "id": "u_qianli",
            "name": "千里马",
            "avatar_label": "千",
            "avatar_color": "#E6332A",
            "department": "外部协作",
            "title": "产品顾问",
            "email": "qianli@example.com",
            "status": "online",
            "is_external": 1,
            "is_favorite": 1,
        },
        {
            "id": "u_azhe",
            "name": "阿拉蕾",
            "avatar_label": "阿",
            "avatar_color": "#FF7043",
            "department": "产品研发部",
            "title": "AI 助手",
            "email": "azhe@example.com",
            "status": "online",
            "is_external": 0,
            "is_favorite": 1,
        },
        {
            "id": "u_xiaoyu",
            "name": "小宇",
            "avatar_label": "宇",
            "avatar_color": "#2F80ED",
            "department": "前端体验组",
            "title": "Flutter 工程师",
            "email": "xiaoyu@example.com",
            "status": "busy",
            "is_external": 0,
            "is_favorite": 0,
        },
        {
            "id": "u_ling",
            "name": "林灵",
            "avatar_label": "林",
            "avatar_color": "#34A853",
            "department": "设计中心",
            "title": "交互设计师",
            "email": "linling@example.com",
            "status": "online",
            "is_external": 0,
            "is_favorite": 0,
        },
        {
            "id": "u_miao",
            "name": "妙搭助手",
            "avatar_label": "妙",
            "avatar_color": "#6C63FF",
            "department": "机器人",
            "title": "自动化助手",
            "email": "bot-miao@example.com",
            "status": "online",
            "is_external": 0,
            "is_favorite": 0,
        },
        {
            "id": "u_security",
            "name": "账号安全中心",
            "avatar_label": "盾",
            "avatar_color": "#2F80ED",
            "department": "系统通知",
            "title": "安全机器人",
            "email": "security@example.com",
            "status": "online",
            "is_external": 0,
            "is_favorite": 0,
        },
    ]

    for contact in contacts:
        connection.execute(
            """
            INSERT INTO contacts (
                id, name, avatar_label, avatar_color, department, title,
                email, status, is_external, is_favorite
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                contact["id"],
                contact["name"],
                contact["avatar_label"],
                contact["avatar_color"],
                contact["department"],
                contact["title"],
                contact["email"],
                contact["status"],
                contact["is_external"],
                contact["is_favorite"],
            ),
        )


def conversation_from_row(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "type": row["type"],
        "title": row["title"],
        "avatarLabel": row["avatar_label"],
        "avatarColor": row["avatar_color"],
        "tags": json.loads(row["tags_json"]),
        "lastMessage": row["last_message"],
        "lastMessageAt": row["last_message_at"],
        "unreadCount": row["unread_count"],
        "isPinned": bool(row["is_pinned"]),
        "isMuted": bool(row["is_muted"]),
    }


def message_from_row(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "conversationId": row["conversation_id"],
        "senderId": row["sender_id"],
        "senderName": row["sender_name"],
        "type": row["type"],
        "content": row["content"],
        "createdAt": row["created_at"],
        "status": row["status"],
        "isMine": bool(row["is_mine"]),
    }


def contact_from_row(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "name": row["name"],
        "avatarLabel": row["avatar_label"],
        "avatarColor": row["avatar_color"],
        "department": row["department"],
        "title": row["title"],
        "email": row["email"],
        "status": row["status"],
        "isExternal": bool(row["is_external"]),
        "isFavorite": bool(row["is_favorite"]),
    }
