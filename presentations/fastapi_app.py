

from fastapi import FastAPI

from presentations.routers.damage_detection_router import router as damage_detection_router

app = FastAPI(
    title="Damage Detection API",
    description="БДСМ где С это СДВГ"
)

# Подключаем роутеры
app.include_router(damage_detection_router)