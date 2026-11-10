"""
Modèles Pydantic v2 pour le microservice Text-to-Speech — InterConnect Burundi.
"""
from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class AudioEncoding(str, Enum):
    MP3 = "MP3"
    LINEAR16 = "LINEAR16"
    OGG_OPUS = "OGG_OPUS"


class VoiceGender(str, Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"
    NEUTRAL = "NEUTRAL"


class TTSLanguage(str, Enum):
    """Codes BCP-47 supportés par Google TTS."""
    FRENCH = "fr-FR"
    ENGLISH_US = "en-US"
    ENGLISH_GB = "en-GB"
    SWAHILI = "sw-TZ"
    ARABIC = "ar-XA"
    SPANISH = "es-ES"
    PORTUGUESE = "pt-PT"
    CHINESE = "cmn-CN"
    KIRUNDI = "rn"  # Placeholder — non supporté nativement


class TTSRequest(BaseModel):
    """Corps de requête pour la synthèse vocale."""

    text: str = Field(..., min_length=1, max_length=5000, description="Texte à synthétiser")
    language_code: TTSLanguage = Field(
        default=TTSLanguage.FRENCH,
        description="Code BCP-47 de la langue",
    )
    voice_gender: VoiceGender = Field(
        default=VoiceGender.FEMALE,
        description="Genre de la voix synthétique",
    )
    audio_encoding: AudioEncoding = Field(
        default=AudioEncoding.MP3,
        description="Format audio de sortie",
    )
    speaking_rate: float = Field(
        default=1.0,
        ge=0.25,
        le=4.0,
        description="Vitesse de parole (1.0 = normale)",
    )
    pitch: float = Field(
        default=0.0,
        ge=-20.0,
        le=20.0,
        description="Hauteur de voix en demi-tons",
    )
    return_base64: bool = Field(
        default=True,
        description="Si True, retourne l'audio en base64 ; sinon stream binaire",
    )

    model_config = {"json_schema_extra": {"example": {
        "text": "Bonjour, bienvenue sur InterConnect Burundi !",
        "language_code": "fr-FR",
        "voice_gender": "FEMALE",
        "audio_encoding": "MP3",
        "speaking_rate": 1.0,
        "pitch": 0.0,
        "return_base64": True,
    }}}


class TTSResponse(BaseModel):
    """Réponse TTS avec audio encodé en base64."""

    audio_base64: str = Field(description="Audio encodé en Base64")
    audio_encoding: str
    language_code: str
    provider: str
    text_length: int
    duration_ms: int | None = Field(default=None, description="Durée estimée en ms")


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: dict | None = None
