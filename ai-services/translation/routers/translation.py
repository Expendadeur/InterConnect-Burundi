"""
Router FastAPI pour la traduction — InterConnect Burundi.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Request, status

import structlog

from translation.models import (
    Language,
    LanguageDetectionRequest,
    LanguageDetectionResponse,
    TranslationRequest,
    TranslationResponse,
)
from translation.services.translator import TranslationService

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/translation", tags=["Translation"])


def _get_service(request: Request) -> TranslationService:
    """Récupère l'instance TranslationService depuis l'état de l'application."""
    return request.app.state.translation_service  # type: ignore[no-any-return]


@router.post(
    "/translate",
    response_model=TranslationResponse,
    status_code=status.HTTP_200_OK,
    summary="Traduire un texte",
    description=(
        "Traduit le texte fourni vers la langue cible. "
        "La langue source est auto-détectée si non précisée."
    ),
)
async def translate_text(
    body: TranslationRequest,
    service: TranslationService = Depends(_get_service),
) -> TranslationResponse:
    logger.info(
        "Requête de traduction reçue",
        target=body.target_language,
        source=body.source_language,
        text_len=len(body.text),
    )
    return await service.translate(body)


@router.post(
    "/detect",
    response_model=LanguageDetectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Détecter la langue d'un texte",
)
async def detect_language(
    body: LanguageDetectionRequest,
    service: TranslationService = Depends(_get_service),
) -> LanguageDetectionResponse:
    logger.info("Requête de détection de langue", text_len=len(body.text))
    detected = await service.detect_language(body.text)
    return LanguageDetectionResponse(text=body.text, detected_language=detected)


@router.get(
    "/languages",
    response_model=list[str],
    status_code=status.HTTP_200_OK,
    summary="Lister les langues supportées",
)
async def list_languages(request: Request) -> list[str]:
    settings = request.app.state.settings
    return settings.supported_languages  # type: ignore[no-any-return]
