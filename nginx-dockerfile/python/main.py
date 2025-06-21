from fastapi import FastAPI
import asyncpg
import os
import ssl 

app = FastAPI()

@app.get("/api/greeting")
async def get_greeting():
    ssl_context = ssl.create_default_context()

    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT", 5432)),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASS"),
        database=os.getenv("DB_NAME"),
        ssl=ssl_context
    )
    row = await conn.fetchrow("SELECT message FROM greetings LIMIT 1")
    await conn.close()
    return {"message": row["message"] if row else "No message found"}
