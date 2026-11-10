"""
Configuration du microservice de traduction — InterConnect Burundi.
Toutes les valeurs proviennent de variables d'environnement (aucune valeur hardcodée).
"""
from __future__ import annotations

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Paramètres de configuration chargés depuis les variables d'environnement."""

    # ── Fournisseurs de traduction ─────────────────────────────────────────────
    google_translate_api_key: str
    deepl_api_key: str = ""
    translation_provider: str = "google"  # "google" | "deepl"

    # ── Langues supportées ─────────────────────────────────────────────────────
    supported_languages: list[str] = ["fr", "en", "rn", "sw", "ar", "es", "pt", "zh"]

    # ── Cache Redis ────────────────────────────────────────────────────────────
    redis_url: str = "redis://redis:6379"
    cache_ttl: int = 3600  # secondes

    # ── Application ───────────────────────────────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False
    cors_origins: list[str] = ["*"]
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @field_validator("translation_provider")
    @classmethod
    def validate_provider(cls, v: str) -> str:
        allowed = {"google", "deepl"}
        if v not in allowed:
            raise ValueError(f"translation_provider doit être parmi {allowed}")
        return v

    @field_validator("log_level")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        allowed = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        upper = v.upper()
        if upper not in allowed:
            raise ValueError(f"log_level doit être parmi {allowed}")
        return upper


def get_settings() -> Settings:
    """Retourne l'instance singleton des paramètres."""
    return Settings()  # type: ignore[call-arg]
