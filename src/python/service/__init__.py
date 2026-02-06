from uvicorn import Config, Server
from asyncio import run
from .routes import app
from .settings import get_rest_settings, get_psql


async def start_server(
):
    rest_settings = get_rest_settings()
    
    async with get_psql() as psql:

        app.extra["psql"] = psql

        config = Config(
            app=app,
            host=rest_settings.host,
            port=rest_settings.port,
            log_level="info",
            loop="asyncio"
        )
        server = Server(config)
        await server.serve()


def main():
    run(start_server())