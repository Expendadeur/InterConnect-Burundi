"""
Configuration du microservice Text-to-Speech — InterConnect Burundi.
"""
from __future__ import annotations

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Paramètres TTS chargés depuis les variables d'environnement."""

    # ── Fournisseur TTS ────────────────────────────────────────────────────────
    tts_provider: str = "google"  # "google" | "gtts" (fallback gratuit)
    google_tts_api_key: str = ""

    # ── Voix et qualité ────────────────────────────────────────────────────────
    default_language: str = "fr-FR"
    default_voice_gender: str = "FEMALE"  # "MALE" | "FEMALE" | "NEUTRAL"
    audio_encoding: str = "MP3"  # "MP3" | "LINEAR16" | "OGG_OPUS"
    speaking_rate: float = 1.0   # 0.25 – 4.0
    pitch: float = 0.0            # -20.0 – 20.0
    volume_gain_db: float = 0.0   # -96.0 – 16.0

    # ── Langues supportées ─────────────────────────────────────────────────────
    supported_languages: list[str] = ["fr", "en", "sw", "ar", "es", "pt", "zh"]

    # ── Application ───────────────────────────────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8002
    debug: bool = False
    cors_origins: list[str] = ["*"]
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @field_validator("tts_provider")
    @classmethod
    def validate_provider(cls, v: str) -> str:
        allowed = {"google", "gtts"}
        if v not in allowed:
            raise ValueError(f"tts_provider doit être parmi {allowed}")
        return v

    @field_validator("speaking_rate")
    @classmethod
    def validate_speaking_rate(cls, v: float) -> float:
        if not (0.25 <= v <= 4.0):
            raise ValueError("speaking_rate doit être entre 0.25 et 4.0")
        return v

    @field_validator("log_level")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        return v.upper()


def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
