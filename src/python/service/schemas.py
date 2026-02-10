from pydantic import BaseModel, Field
from typing import Annotated

class AddItemToOrderRequest(BaseModel):
    order_id: Annotated[
        int,
        Field(..., description="ID of the order")
    ]
    item_id: Annotated[
        int,
        Field(..., description="ID of the item")
    ]
    quantity: Annotated[
        int,
        Field(..., description="Quantity of items in the order", gt=0)
    ]