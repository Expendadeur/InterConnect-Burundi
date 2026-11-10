"""
Point d'entrée du microservice Text-to-Speech — InterConnect Burundi.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from .config import Settings
from .routers import tts

settings = Settings()

app = FastAPI(
    title="InterConnect Burundi — AI Text-to-Speech",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tts.router)


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "text-to-speech",
        "provider": settings.tts_provider,
    }


@app.on_event("startup")
async def startup_event():
    logger.info("Démarrage du service AI Text-to-Speech InterConnect Burundi")

