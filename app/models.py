from pydantic import BaseModel, Field


class LeituraCreate(BaseModel):
    sensor_id: int
    umidade: float = Field(ge=0, le=100)
    temperatura: float = Field(ge=-20, le=70)
