from sqlalchemy import JSON, Column, Integer, String

from app.db import Base


class OrderModel(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    item = Column(String, nullable=False)
    quantity = Column(Integer, nullable=False)
    user = Column(JSON, nullable=False)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "item": self.item,
            "quantity": self.quantity,
            "user": self.user,
        }
