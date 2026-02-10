from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import VARCHAR, TIMESTAMP, BOOLEAN, insert, INTEGER, FLOAT
from sqlalchemy import select, update, ForeignKey
from sqlalchemy_utils import LtreeType
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from typing import Optional
from .errors import NotEnoughQuantityError, ItemNotFoundError, OrderNotFoundError, CustomerNotFoundError


class Base(DeclarativeBase):
    __table_args__ = {"schema": "public"}

    pass

class Items(Base):
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(INTEGER(), primary_key=True)
    label: Mapped[str] = mapped_column(VARCHAR(), nullable=False)
    category: Mapped[Optional[int]] = mapped_column(INTEGER(), ForeignKey("public.categories.id"), nullable=True)
    quantity: Mapped[int] = mapped_column(INTEGER(), nullable=False)
    price: Mapped[float] = mapped_column(FLOAT(), nullable=False)
    category_rel: Mapped[Optional["Categories"]] = relationship(back_populates="items_rel", lazy="joined")
    order_rel: Mapped[Optional["OrderItems"]] = relationship(back_populates="item_rel", lazy="joined")

class Categories(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(INTEGER(), primary_key=True, autoincrement=True)
    label: Mapped[str] = mapped_column(VARCHAR(), nullable=False)
    path: Mapped[Optional[str]] = mapped_column(LtreeType(), nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(INTEGER(), nullable=True)
    items_rel: Mapped[list["Items"]] = relationship(back_populates="category_rel", lazy="joined")

class Customers(Base):
    __tablename__ = "customers"

    id: Mapped[int] = mapped_column(INTEGER(), primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(VARCHAR(), nullable=False)
    address: Mapped[str] = mapped_column(VARCHAR(), nullable=False)
    is_deleted: Mapped[bool] = mapped_column(BOOLEAN(), nullable=False, default=False)
    orders_rel: Mapped[list["Orders"]] = relationship(back_populates="customer_rel", lazy="joined")

class Orders(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(INTEGER(), primary_key=True, autoincrement=True)
    customer_id: Mapped[int] = mapped_column(INTEGER(), ForeignKey("public.customers.id"), nullable=False)
    quantity: Mapped[int] = mapped_column(INTEGER(), nullable=False)
    date: Mapped[datetime] = mapped_column(TIMESTAMP(), nullable=False)
    is_complete: Mapped[bool] = mapped_column(BOOLEAN(), nullable=False, default=False)
    customer_rel: Mapped["Customers"] = relationship(back_populates="orders_rel", lazy="joined")
    order_items_rel: Mapped[list["OrderItems"]] = relationship(back_populates="order_rel", lazy="joined")

class OrderItems(Base):
    __tablename__ = "orders_items"

    order_id: Mapped[int] = mapped_column(INTEGER(), ForeignKey("public.orders.id"), nullable=False, primary_key=True)
    item_id: Mapped[int] = mapped_column(INTEGER(), ForeignKey("public.items.id"), nullable=False, primary_key=True)
    quantity: Mapped[int] = mapped_column(INTEGER(), nullable=False)
    order_rel: Mapped["Orders"] = relationship(back_populates="order_items_rel", lazy="joined")
    item_rel: Mapped["Items"] = relationship(back_populates="order_rel", lazy="joined")

async def add_item_into_order(
    session: AsyncSession,
    order_id: int,
    item_id: int,
    quantity: int
) -> None:
    
    check_quantity_stmt = (
        select(Items.quantity)
        .where(Items.id == item_id)
    )
    result = await session.execute(check_quantity_stmt)
    available_quantity = result.scalar_one_or_none()
    if available_quantity is None:
        raise ItemNotFoundError(f"Item with id {item_id} does not exist.")
    if available_quantity < quantity:
        raise NotEnoughQuantityError(f"Not enough quantity available for item with id {item_id}. Requested: {quantity}, Available: {available_quantity}")
    
    check_order_stmt = (
        select(Orders.id)
        .where(Orders.id == order_id))
    result = await session.execute(check_order_stmt)
    existing_order_id = result.scalar_one_or_none()
    if existing_order_id is None:
        raise OrderNotFoundError(f"Order with id {order_id} does not exist.")

    stmt = insert(OrderItems).values(
        order_id=order_id,
        item_id=item_id,
        quantity=quantity
    ).on_conflict_do_update(
        index_elements=["order_id", "item_id"],
        set_={"quantity": OrderItems.quantity + quantity}
    )
    await session.execute(stmt)

    update_quantity_stmt = (
        update(Items)
        .where(Items.id == item_id)
        .values(quantity=Items.quantity - quantity)
    )
    await session.execute(update_quantity_stmt)