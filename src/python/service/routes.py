from fastapi import Body, FastAPI, Request
from fastapi.responses import JSONResponse
from .dependency import Psql
from .schemas import AddItemToOrderRequest
from .models import add_item_into_order
from .errors import AppError

app = FastAPI()

@app.exception_handler(Exception)
@app.exception_handler(500)
async def internal_exception_handler(
    _: Request,
    exc: Exception,

) -> JSONResponse:
    return JSONResponse(
        status_code=500,
        content={"message": str(exc)}
    )

@app.post(
    "/add_item_to_order",
    response_model=dict
    )
async def add_item_to_order(
    psql: Psql,
    data: AddItemToOrderRequest = Body(...)
):
    await add_item_into_order(
        session=psql,
        order_id=data.order_id,
        item_id=data.item_id,
        quantity=data.quantity
    )
    return {"message": f"Added {data.quantity} of item {data.item_id} into order {data.order_id}"}