from fastapi import FastAPI
from .dependency import Psql
from sqlalchemy import text

app = FastAPI()

@app.get(
    "/",
    response_model=dict
    )
async def read_root(
    psql: Psql
):
    await psql.execute(text("SELECT 1"))
    return {"message": "Hello, World!"}