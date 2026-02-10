from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from collections.abc import AsyncGenerator, AsyncGenerator
from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, AsyncEngine, async_sessionmaker
from fastapi import Depends

class RestSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", env_prefix="REST_", extra="ignore")

    host: str = Field(default="0.0.0.0")
    port: int = Field(default=8080)


class PsqlSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", env_prefix="PSQL_", extra="ignore")

    host: str = Field(default="localhost", env="PSQL_HOST")
    port: int = Field(default=5332, env="PSQL_PORT")
    user: str = Field(default="postgres", env="PSQL_USER")
    password: SecretStr = Field(... ,env="PSQL_PASSWORD")
    database: str = Field(default="postgres", env="PSQL_DB")


class SvcSettings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore")

    rest: RestSettings = Field(default_factory=RestSettings)
    psql: PsqlSettings = Field(default_factory=PsqlSettings)

@asynccontextmanager
async def _get_engine() -> AsyncGenerator[AsyncEngine, None]:
    settings = SvcSettings()
    psql_settings = settings.psql
    engine = create_async_engine(
        f"postgresql+asyncpg://{psql_settings.user}:{psql_settings.password.get_secret_value()}@{psql_settings.host}:{psql_settings.port}/{psql_settings.database}",
        echo=True,
    )
    yield engine

async def _get_sessionmaker() -> async_sessionmaker[AsyncSession]:
    async with _get_engine() as engine:
        return async_sessionmaker(engine, expire_on_commit=False)

@asynccontextmanager
async def get_psql() -> AsyncGenerator[AsyncSession, None]:
    sessionmaker = await _get_sessionmaker()
    async with sessionmaker() as session:
        session.begin()
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            raise e
        finally:
            await session.close()

def get_rest_settings() -> RestSettings:
    return RestSettings.model_validate({})