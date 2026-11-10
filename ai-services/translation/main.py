"""
Point d'entrée FastAPI — microservice de traduction InterConnect Burundi.
"""
from __future__ import annotations

import sys
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from translation.config import get_settings
from translation.routers.translation import router as translation_router
from translation.services.translator import TranslationService

# ── Logging structuré ──────────────────────────────────────────────────────────
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer() if "--dev" in sys.argv else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(20),  # INFO
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
)

logger = structlog.get_logger(__name__)

# ── Paramètres ─────────────────────────────────────────────────────────────────
settings = get_settings()


# ── Lifespan ───────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Gestion du cycle de vie de l'application (startup / shutdown)."""
    logger.info(
        "Démarrage du service de traduction",
        provider=settings.translation_provider,
        host=settings.host,
        port=settings.port,
        debug=settings.debug,
    )

    # Initialisation du service de traduction
    svc = TranslationService(settings)
    await svc.startup()

    app.state.settings = settings
    app.state.translation_service = svc

    yield

    # Arrêt propre
    logger.info("Arrêt du service de traduction")
    await svc.shutdown()


# ── Application FastAPI ────────────────────────────────────────────────────────
app = FastAPI(
    title="InterConnect Burundi — Translation Service",
    description="Microservice de traduction multi-langue et multi-fournisseur.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────────
app.include_router(translation_router, prefix="/api/v1")


# ── Health check ───────────────────────────────────────────────────────────────
@app.get(
    "/health",
    tags=["Health"],
    summary="Vérification de santé du service",
    response_description="Statut du service",
)
async def health_check() -> JSONResponse:
    return JSONResponse(
        content={
            "status": "healthy",
            "service": "translation",
            "provider": settings.translation_provider,
            "version": "1.0.0",
        }
    )


@app.get("/", include_in_schema=False)
async def root() -> JSONResponse:
    return JSONResponse(content={"service": "translation", "docs": "/docs"})
