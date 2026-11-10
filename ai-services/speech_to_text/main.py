"""
Point d'entrée FastAPI — microservice Speech-to-Text InterConnect Burundi.
"""
from __future__ import annotations

import sys
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from speech_to_text.config import get_settings
from speech_to_text.routers.stt import router as stt_router
from speech_to_text.services.stt_service import STTService

# ── Logging ────────────────────────────────────────────────────────────────────
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer() if "--dev" in sys.argv else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(20),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
)

logger = structlog.get_logger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info(
        "Démarrage du service Speech-to-Text",
        provider=settings.stt_provider,
        whisper_model=settings.whisper_model,
        port=settings.port,
    )
    svc = STTService(settings)
    await svc.startup()

    app.state.settings = settings
    app.state.stt_service = svc

    yield

    logger.info("Arrêt du service Speech-to-Text")
    await svc.shutdown()


app = FastAPI(
    title="InterConnect Burundi — Speech-to-Text Service",
    description="Microservice de transcription audio en texte (Whisper / Google Speech).",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(stt_router, prefix="/api/v1")


@app.get("/health", tags=["Health"], summary="Vérification de santé")
async def health_check() -> JSONResponse:
    return JSONResponse(
        content={
            "status": "healthy",
            "service": "speech-to-text",
            "provider": settings.stt_provider,
            "whisper_model": settings.whisper_model if settings.stt_provider == "whisper" else None,
            "version": "1.0.0",
        }
    )


@app.get("/", include_in_schema=False)
async def root() -> JSONResponse:
    return JSONResponse(content={"service": "speech-to-text", "docs": "/docs"})
