from uvicorn import Config, Server
from asyncio import run
from .routes import app


async def start_server():
    config = Config(
        app=app,
        host="localhost",
        port=8080,
        log_level="info",
        loop="asyncio"
    )
    server = Server(config)
    await server.serve()


def main():
    run(start_server())