from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import cv2
import numpy as np
from typing import List, Dict, Any
import io
from PIL import Image
import json

CONFIG = {
    'yolo_path': 'ML_models/yolo_weights/yolo.pt',
    }


class DamageDetectionResult:
    def __init__(self):
        """У нас есть rust -- ржавчина, dent -- вмятины,
        scratch --  царапины и damage -- это дырки всякие
        Плюс имеется """
        self.detections = {
            "rust": [],
            "dent": [],
            "scratch": [],
            "damage": []
        }
        self.car_bbox = None
        self.damage_ratio = 0.0

    def add_detection(self, class_name: str, bbox: List[float], confidence: float):
        """Добавляет обнаруженное повреждение в результаты"""
        detection = {
            "bbox": {
                "x_min": bbox[0],
                "y_min": bbox[1],
                "x_max": bbox[2],
                "y_max": bbox[3],
                "width": bbox[2] - bbox[0],
                "height": bbox[3] - bbox[1]
            },
            "confidence": float(confidence)
        }

        if class_name in self.detections:
            self.detections[class_name].append(detection)
        else:
            self.detections["damage"].append(detection)

    def calculate_damage_ratio(self, img_width: int, img_height: int):
        """Вычисляет степень повреждения автомобиля"""
        if not self.car_bbox:
            return 0.0

        # Площадь автомобиля
        car_area = (self.car_bbox[2] - self.car_bbox[0]) * (self.car_bbox[3] - self.car_bbox[1])

        # Суммарная площадь всех повреждений
        # Не учитывает пересечения. Наверное так чутка правильнее будет
        total_damage_area = 0
        for damage_type in self.detections.values():
            for damage in damage_type:
                bbox = damage["bbox"]
                total_damage_area += bbox["width"] * bbox["height"]

        self.damage_ratio = total_damage_area / car_area if car_area > 0 else 0
        return self.damage_ratio

    def to_dict(self) -> Dict[str, Any]:
        """Конвертирует результаты в словарь"""
        return {
            "car_bbox": self.car_bbox,
            "damage_ratio": float(self.damage_ratio),
            "detections": self.detections
        }

