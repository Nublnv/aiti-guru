from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from .. import routes

async def get_psql() -> AsyncSession:
    return routes.app.extra.get("psql")

Psql = Annotated[AsyncSession, Depends(get_psql)]