from fastapi import FastAPI, UploadFile, File
from fastapi.responses import RedirectResponse

from presentations.routers.damage_detection_router import router as damage_detection_router

app = FastAPI(
    title="Damage Detection API",
    description="БДСМ где С это СДВГ",
    docs_url="/model/docs",
    redoc_url="/model/redoc",
    openapi_url="/model/openapi.json"
)

# Подключаем роутеры
app.include_router(damage_detection_router)

@app.post("/model/analyze")
async def analyze(file: UploadFile = File(...)):
    """
    Корневой эндпоинт для анализа повреждений
    Перенаправляет на /model/damage-detection/analyze
    """
    from presentations.routers.damage_detection_router import analyze_damage
    return await analyze_damage(file)