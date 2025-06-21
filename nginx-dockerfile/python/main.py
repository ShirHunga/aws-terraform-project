from fastapi import FastAPI
import asyncpg
import os

app = FastAPI()

@app.get("/api/greeting")
async def get_greeting():
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT", 5432)),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASS"),
        database=os.getenv("DB_NAME")
    )
    row = await conn.fetchrow("SELECT message FROM greetings LIMIT 1")
    await conn.close()
    return {"message": row["message"] if row else "No message found"}
