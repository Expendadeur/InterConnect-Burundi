"""
Point d'entrée UNIFIÉ des microservices IA — InterConnect Burundi.
Regroupe Traduction, Speech-to-Text et Text-to-Speech sur un seul serveur FastAPI.
"""
from __future__ import annotations

import sys
from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

# Import des routeurs des 3 sous-modules
from translation.routers.translation import router as translation_router
from speech_to_text.routers.stt import router as stt_router
from text_to_speech.routers.tts import router as tts_router

app = FastAPI(
    title="InterConnect Burundi — AI Services Hub",
    description="Microservices unifiés pour Traduction IA, Speech-to-Text et Text-to-Speech",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Enregistrement des 3 routeurs
app.include_router(translation_router)
app.include_router(stt_router)
app.include_router(tts_router)


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "app": "InterConnect Burundi - AI Services Hub",
        "modules": {
            "translation": "/translate",
            "speech_to_text": "/stt",
            "text_to_speech": "/tts",
        },
    }


@app.get("/sw.js", include_in_schema=False)
async def service_worker():
    """Gère la requête de Service Worker envoyée par les navigateurs modernes."""
    return Response(content="", media_type="application/javascript")


@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    """Gère l'icône demandée automatiquement par les navigateurs."""
    return Response(status_code=204)


@app.on_event("startup")
async def startup_event():
    logger.info("Démarrage du Hub IA InterConnect Burundi (Traduction + STT + TTS sur le port 8000)")

