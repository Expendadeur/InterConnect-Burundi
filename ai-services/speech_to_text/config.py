"""
Configuration du microservice Speech-to-Text — InterConnect Burundi.
"""
from __future__ import annotations

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Paramètres STT chargés depuis les variables d'environnement."""

    # ── Fournisseurs STT ───────────────────────────────────────────────────────
    stt_provider: str = "whisper"  # "whisper" | "google"
    google_speech_api_key: str = ""

    # ── Whisper ────────────────────────────────────────────────────────────────
    whisper_model: str = "base"  # tiny | base | small | medium | large
    whisper_device: str = "cpu"  # "cpu" | "cuda"

    # ── Paramètres audio ──────────────────────────────────────────────────────
    max_audio_size_mb: int = 25
    allowed_audio_formats: list[str] = [
        "audio/wav", "audio/mpeg", "audio/mp4",
        "audio/ogg", "audio/webm", "audio/flac",
    ]

    # ── Langues supportées ─────────────────────────────────────────────────────
    supported_languages: list[str] = ["fr", "en", "rn", "sw", "ar", "es", "pt", "zh"]

    # ── Application ───────────────────────────────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8001
    debug: bool = False
    cors_origins: list[str] = ["*"]
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @field_validator("stt_provider")
    @classmethod
    def validate_provider(cls, v: str) -> str:
        allowed = {"whisper", "google"}
        if v not in allowed:
            raise ValueError(f"stt_provider doit être parmi {allowed}")
        return v

    @field_validator("whisper_model")
    @classmethod
    def validate_whisper_model(cls, v: str) -> str:
        allowed = {"tiny", "base", "small", "medium", "large"}
        if v not in allowed:
            raise ValueError(f"whisper_model doit être parmi {allowed}")
        return v

    @field_validator("log_level")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        return v.upper()


def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
