"""
SmartEdge AgriGuardian — YOLO11 Classification Inference Service
=================================================================
File: modules/leaf_detection/leaf_service.py

Handles inference using the trained custom YOLO11 Classification model.
Exposes predictions, maps indexes to disease classes, and enforces a
70% confidence safety threshold gate.
"""

import os
import io
import logging
from typing import Dict, List, Optional

from PIL import Image
import numpy as np

logger = logging.getLogger(__name__)

# Path configuration
HERE = os.path.dirname(os.path.abspath(__file__))
MODEL_PT_PATH = os.path.join(HERE, "model", "best.pt")
MODEL_ONNX_PATH = os.path.join(HERE, "model", "best.onnx")

# Cache holders for the loaded YOLO model to avoid disk reads per request
_yolo_model = None


def _load_yolo_model() -> None:
    """
    Loads the YOLO11 model into memory and caches it.
    """
    global _yolo_model
    if _yolo_model is not None:
        return

    logger.info("Initializing YOLO11 Classification Model...")
    
    if not os.path.exists(MODEL_PT_PATH):
        raise RuntimeError(
            f"Trained YOLO11 checkpoint not found at: {MODEL_PT_PATH}. "
            "Please run the YOLO11 training script first to compile: "
            "`python modules/leaf_detection/train_yolo.py`"
        )

    try:
        from ultralytics import YOLO
        _yolo_model = YOLO(MODEL_PT_PATH)
        logger.info("YOLO11 Classification Model loaded successfully.")
    except ImportError:
        raise ImportError(
            "The 'ultralytics' package is required to load and run YOLO11 models. "
            "Please install it using: pip install ultralytics"
        )


def classify_leaf(image_bytes: bytes) -> Dict:
    """
    Diagnoses leaf disease using the YOLO11 Classification model.
    Enforces a 70% confidence threshold gate.

    Args:
        image_bytes: Raw binary uploaded image.

    Returns:
        JSON response dictionary conforming to the hackathon requirements.
    """
    # Guarantee model is loaded
    _load_yolo_model()

    # Preprocess image upload using Pillow
    try:
        img = Image.open(io.BytesIO(image_bytes))
        if img.mode != "RGB":
            img = img.convert("RGB")
    except Exception as exc:
        raise ValueError(f"Uploaded file is not a valid image: {exc}")

    # Run YOLO11 inference
    try:
        # YOLO handles resizing to 640x640 internally with correct padding
        results = _yolo_model(img, verbose=False)
        result = results[0]
    except Exception as exc:
        raise RuntimeError(f"YOLO11 execution failed: {exc}")

    # Extract prediction details
    probs = result.probs
    if probs is None:
        raise RuntimeError("Model did not return classification probabilities.")

    # Get class names list
    names = _yolo_model.names

    # Extract Top-1 class details
    top1_idx = int(probs.top1)
    top1_conf = float(probs.top1conf)
    top1_label = names[top1_idx]

    # Extract Top-3 classes details
    top5_indices = probs.top5
    top5_confs = probs.top5conf
    
    top3_predictions = []
    # Take up to top 3 predictions
    limit = min(3, len(top5_indices))
    for i in range(limit):
        idx = int(top5_indices[i])
        conf = float(top5_confs[i])
        lbl = names[idx]
        top3_predictions.append({
            "disease": lbl,
            "confidence": round(conf * 100, 2),  # Confidence in %
            "plant_type": _get_plant_type(lbl),
            "is_healthy": "healthy" in lbl.lower()
        })

    # Confidence Threshold Check Gate: 70%
    if top1_conf < 0.70:
        logger.warning(f"Detection confidence ({top1_conf*100:.1f}%) below 70% gate. Returning warning.")
        return {
            "status": "low_confidence",
            "message": "Low confidence. Please capture another image.",
            "confidence": round(top1_conf, 4),
            "top_predictions": top3_predictions
        }

    # High confidence result
    is_healthy = "healthy" in top1_label.lower()
    return {
        "status": "success",
        "disease": top1_label,
        "confidence": round(top1_conf, 4),
        "plant_type": _get_plant_type(top1_label),
        "is_healthy": is_healthy,
        "top_predictions": top3_predictions
    }


def _get_plant_type(class_label: str) -> str:
    """Helper to extract crop species name from PlantVillage class names."""
    lbl_lower = class_label.lower()
    if "tomato" in lbl_lower:
        return "Tomato"
    elif "potato" in lbl_lower:
        return "Potato"
    elif "pepper" in lbl_lower:
        return "Pepper (bell)"
    return "Unknown"
