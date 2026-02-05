from fastapi import FastAPI

app = FastAPI()

@app.get(
    "/",
    response_model=dict
    )
async def read_root():
    return {"message": "Hello, World!"}