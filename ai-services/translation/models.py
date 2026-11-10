"""
Modèles Pydantic v2 pour le microservice de traduction — InterConnect Burundi.
"""
from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class Language(str, Enum):
    """Langues supportées par la plateforme InterConnect Burundi."""

    FRENCH = "fr"
    ENGLISH = "en"
    KIRUNDI = "rn"
    SWAHILI = "sw"
    ARABIC = "ar"
    SPANISH = "es"
    PORTUGUESE = "pt"
    CHINESE = "zh"


class TranslationContext(str, Enum):
    """Contexte applicatif de la traduction (peut affiner la qualité)."""

    SOCIAL_POST = "social_post"
    MESSAGE = "message"
    COMMENT = "comment"
    ARTICLE = "article"
    GENERAL = "general"


class TranslationRequest(BaseModel):
    """Corps de requête pour la traduction d'un texte."""

    text: str = Field(..., min_length=1, max_length=5000, description="Texte à traduire")
    source_language: Language | None = Field(
        default=None, description="Langue source (None = auto-détection)"
    )
    target_language: Language = Field(..., description="Langue cible")
    context: TranslationContext | None = Field(
        default=None,
        description="Contexte applicatif pour améliorer la traduction",
    )

    model_config = {"json_schema_extra": {"example": {
        "text": "Bonjour, comment allez-vous ?",
        "source_language": "fr",
        "target_language": "en",
        "context": "message",
    }}}


class TranslationResponse(BaseModel):
    """Réponse de traduction."""

    original_text: str
    translated_text: str
    source_language: str = Field(description="Code ISO 639-1 de la langue source détectée")
    target_language: str
    provider: str = Field(description="Fournisseur utilisé : 'google', 'deepl', 'kirundi_placeholder'")
    cached: bool = Field(default=False, description="True si la réponse provient du cache Redis")


class LanguageDetectionRequest(BaseModel):
    """Corps de requête pour la détection de langue."""

    text: str = Field(..., min_length=1, max_length=2000)


class LanguageDetectionResponse(BaseModel):
    """Réponse de détection de langue."""

    text: str
    detected_language: str
    confidence: float | None = None


class ErrorDetail(BaseModel):
    """Détail d'erreur structuré."""

    code: str
    message: str
    details: dict | None = None
