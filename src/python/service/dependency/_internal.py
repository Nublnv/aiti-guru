from typing import Annotated, AsyncGenerator
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from .. import routes

async def get_psql() -> AsyncGenerator[AsyncSession, None]:
    async with routes.app.extra.get("psql")() as session:
        yield session

Psql = Annotated[AsyncSession, Depends(get_psql)]