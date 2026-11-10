"""
Modèles Pydantic v2 pour le microservice Speech-to-Text — InterConnect Burundi.
"""
from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class AudioFormat(str, Enum):
    WAV = "audio/wav"
    MP3 = "audio/mpeg"
    MP4 = "audio/mp4"
    OGG = "audio/ogg"
    WEBM = "audio/webm"
    FLAC = "audio/flac"


class STTProvider(str, Enum):
    WHISPER = "whisper"
    GOOGLE = "google"


class TranscriptionResponse(BaseModel):
    """Résultat de la transcription audio."""

    transcript: str = Field(description="Texte transcrit")
    detected_language: str = Field(description="Code ISO 639-1 de la langue détectée")
    confidence: float | None = Field(
        default=None,
        ge=0.0,
        le=1.0,
        description="Score de confiance (0.0 – 1.0)",
    )
    provider: str = Field(description="Fournisseur STT utilisé")
    duration_seconds: float | None = Field(
        default=None, description="Durée de l'audio en secondes"
    )
    segments: list[TranscriptionSegment] | None = Field(
        default=None, description="Segments Whisper avec timestamps"
    )


class TranscriptionSegment(BaseModel):
    """Segment de transcription avec timestamps (Whisper)."""

    start: float
    end: float
    text: str


# Résolution de la référence forward
TranscriptionResponse.model_rebuild()


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: dict | None = None
