from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from services.yolo_prediction import DamageDetectionResult
from ultralytics import YOLO
import cv2
import numpy as np
from PIL import Image
import io
import os
import tempfile
from loguru import logger

router = APIRouter(
    prefix="/damage-detection",
    tags=["damage-detection"]
)

# Инициализация модели YOLO
model = YOLO('ML_models/yolo_weights/yolo.pt')

@router.post("/analyze")
async def analyze_damage(file: UploadFile = File(...)):
    """
    Анализирует изображение автомобиля на наличие повреждений
    
    Args:
        file (UploadFile): Загруженное изображение
        
    Returns:
        JSONResponse: в ридми прочитаешь формат
    """
    try:
        # Проверка типа файла
        if not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=400,
                detail="Файл должен быть изображением"
            )
        
        # Создаем временный файл для сохранения изображения
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            contents = await file.read()
            temp_file.write(contents)
            temp_file_path = temp_file.name

        try:
            # Получение предсказаний от модели
            results = model.predict(
                temp_file_path,
                save=False
            )
            
            # Вывод основных данных модели
            logger.info("=== ДАННЫЕ МОДЕЛИ ===")
            for i, result in enumerate(results):
                logger.info(f"\nРезультат {i}:")
                logger.info(f"Всего обнаружено боксов: {len(result.boxes)}")
                logger.info(f"Классы: {result.names}")
                
                # Проверяем наличие боксов для каждого класса
                for cls_id in range(5):  # 0:car, 1:damage, 2:dent, 3:scratch, 4:rust
                    cls_boxes = result.boxes[result.boxes.cls == cls_id]
                    logger.info(f"Класс {result.names[cls_id]}: найдено {len(cls_boxes)} объектов")
                    if len(cls_boxes) > 0:
                        logger.info(f"Координаты (xyxy): {cls_boxes.xyxy.cpu().numpy()}")
                        logger.info(f"Уверенность: {cls_boxes.conf.cpu().numpy()}")
            
            # Обработка результатов
            damage_result = DamageDetectionResult()
            
            for result in results:
                # Получаем боксы для каждого типа повреждения
                car_bbox = result.boxes[result.boxes.cls == 0]  # car
                damage_bbox = result.boxes[result.boxes.cls == 1]  # damage
                dent_bbox = result.boxes[result.boxes.cls == 2]  # dent
                scratch_bbox = result.boxes[result.boxes.cls == 3]  # scratch
                rust_bbox = result.boxes[result.boxes.cls == 4]  # rust
                
                # Обработка автомобиля
                if len(car_bbox) > 0:
                    car_coords = car_bbox.xyxy[0].cpu().numpy()
                    damage_result.car_bbox = car_coords.tolist()
                    
                    # Если есть повреждения, рассчитываем соотношение
                    if len(damage_bbox) > 0:
                        car_area = car_bbox.xywh[0][2] * car_bbox.xywh[0][3]
                        damage_area = damage_bbox.xywh[0][2] * damage_bbox.xywh[0][3]
                        damage_ratio = float(damage_area / car_area)
                        damage_result.damage_ratio = damage_ratio
                        logger.info(f"Площадь автомобиля: {car_area}")
                        logger.info(f"Площадь повреждений: {damage_area}")
                        logger.info(f"Соотношение: {damage_ratio:.2%}")
                
                # Обработка всех типов повреждений
                for cls_id, boxes in enumerate([damage_bbox, dent_bbox, scratch_bbox, rust_bbox]):
                    class_name = result.names[cls_id + 1]  # +1 потому что 0 это car
                    for box in boxes:
                        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                        confidence = float(box.conf[0].cpu().numpy())
                        
                        damage_result.add_detection(
                            class_name=class_name,
                            bbox=[float(x1), float(y1), float(x2), float(y2)],
                            confidence=confidence
                        )
            
            return JSONResponse(content=damage_result.to_dict())
            
        finally:
            # Удаляем временный файл
            os.unlink(temp_file_path)
        
    except Exception as e:
        logger.error(f"Ошибка при обработке изображения: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка при обработке изображения: {str(e)}"
        ) 