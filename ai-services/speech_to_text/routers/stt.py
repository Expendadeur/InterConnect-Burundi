"""
Router FastAPI pour le Speech-to-Text — InterConnect Burundi.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile, status
import structlog

from speech_to_text.models import TranscriptionResponse
from speech_to_text.services.stt_service import STTService

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/stt", tags=["Speech-to-Text"])


def _get_service(request: Request) -> STTService:
    return request.app.state.stt_service  # type: ignore[no-any-return]


@router.post(
    "/transcribe",
    response_model=TranscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Transcrire un fichier audio en texte",
    description=(
        "Accepte un fichier audio (WAV, MP3, OGG, FLAC, WebM, MP4) "
        "et retourne la transcription avec la langue détectée."
    ),
)
async def transcribe_audio(
    audio: UploadFile = File(..., description="Fichier audio à transcrire"),
    language_hint: str | None = Form(
        default=None,
        description="Code ISO 639-1 de la langue parlée (optionnel, ex: 'fr', 'sw')",
    ),
    service: STTService = Depends(_get_service),
) -> TranscriptionResponse:
    """Transcrit l'audio uploadé."""
    settings = service._settings

    # Validation du type MIME
    content_type = audio.content_type or ""
    if content_type not in settings.allowed_audio_formats:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=(
                f"Format audio '{content_type}' non supporté. "
                f"Formats acceptés : {settings.allowed_audio_formats}"
            ),
        )

    audio_bytes = await audio.read()
    logger.info(
        "Transcription demandée",
        filename=audio.filename,
        content_type=content_type,
        size_bytes=len(audio_bytes),
        language_hint=language_hint,
        provider=service._provider,
    )

    return await service.transcribe(
        audio_bytes=audio_bytes,
        content_type=content_type,
        language_hint=language_hint,
    )


@router.get(
    "/models",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    summary="Lister les modèles Whisper disponibles",
)
async def list_whisper_models(request: Request) -> dict:
    settings = request.app.state.settings
    return {
        "provider": settings.stt_provider,
        "current_model": settings.whisper_model if settings.stt_provider == "whisper" else None,
        "available_whisper_models": ["tiny", "base", "small", "medium", "large"],
    }
