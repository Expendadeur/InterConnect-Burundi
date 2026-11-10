"""
Service de traduction — InterConnect Burundi.

Fournisseurs supportés :
  - Google Cloud Translation (v2 / Advanced)
  - DeepL (fallback configurable)

Fonctionnalités :
  - Cache Redis avec TTL configurable
  - Détection automatique de la langue
  - Gestion du Kirundi (rn) : indication si non supporté par le provider
"""
from __future__ import annotations

import hashlib
import json
import logging
from typing import TYPE_CHECKING

import structlog

if TYPE_CHECKING:
    pass

logger = structlog.get_logger(__name__)

# ── Imports conditionnels (évite les crashs si une lib n'est pas installée) ───

try:
    from google.cloud import translate_v2 as google_translate  # type: ignore[import-untyped]

    _GOOGLE_AVAILABLE = True
except ImportError:
    _GOOGLE_AVAILABLE = False
    logger.warning("google-cloud-translate non installé — provider Google indisponible")

try:
    import deepl as deepl_lib  # type: ignore[import-untyped]

    _DEEPL_AVAILABLE = True
except ImportError:
    _DEEPL_AVAILABLE = False
    logger.warning("deepl non installé — provider DeepL indisponible")

try:
    import redis.asyncio as aioredis  # type: ignore[import-untyped]

    _REDIS_AVAILABLE = True
except ImportError:
    _REDIS_AVAILABLE = False
    logger.warning("redis non installé — cache désactivé")

from translation.config import Settings
from translation.models import Language, TranslationRequest, TranslationResponse

# Langues supportées nativement par Google Translate
GOOGLE_SUPPORTED_LANGUAGES: set[str] = {
    "fr", "en", "sw", "ar", "es", "pt", "zh", "de", "it",
}

# Langues supportées nativement par DeepL
DEEPL_SUPPORTED_LANGUAGES: set[str] = {
    "fr", "en", "ar", "es", "pt", "zh", "de", "it",
}

# Kirundi n'est supporté par aucun grand provider commercial actuellement
KIRUNDI_CODE = "rn"


class TranslationService:
    """Service de traduction multi-fournisseur avec cache Redis."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._provider = settings.translation_provider
        self._redis: "aioredis.Redis | None" = None

        # Init Google
        self._google_client: "google_translate.Client | None" = None
        if self._provider == "google" and _GOOGLE_AVAILABLE:
            self._google_client = google_translate.Client(
                client_options={"api_key": settings.google_translate_api_key}
            )

        # Init DeepL
        self._deepl_client: "deepl_lib.Translator | None" = None
        if _DEEPL_AVAILABLE and settings.deepl_api_key:
            self._deepl_client = deepl_lib.Translator(settings.deepl_api_key)

    # ── Lifecycle ──────────────────────────────────────────────────────────────

    async def startup(self) -> None:
        """Initialise la connexion Redis au démarrage."""
        if _REDIS_AVAILABLE:
            try:
                self._redis = aioredis.from_url(
                    self._settings.redis_url,
                    encoding="utf-8",
                    decode_responses=True,
                )
                await self._redis.ping()
                logger.info("Redis connecté", url=self._settings.redis_url)
            except Exception as exc:  # noqa: BLE001
                logger.warning("Redis indisponible — cache désactivé", error=str(exc))
                self._redis = None

    async def shutdown(self) -> None:
        """Ferme proprement la connexion Redis."""
        if self._redis:
            await self._redis.aclose()
            logger.info("Connexion Redis fermée")

    # ── Cache ──────────────────────────────────────────────────────────────────

    def _cache_key(self, text: str, source: str | None, target: str) -> str:
        payload = f"{text}|{source or 'auto'}|{target}|{self._provider}"
        return f"translation:{hashlib.sha256(payload.encode()).hexdigest()}"

    async def _get_cache(self, key: str) -> TranslationResponse | None:
        if not self._redis:
            return None
        try:
            raw = await self._redis.get(key)
            if raw:
                return TranslationResponse.model_validate_json(raw)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Erreur lecture cache", error=str(exc))
        return None

    async def _set_cache(self, key: str, response: TranslationResponse) -> None:
        if not self._redis:
            return
        try:
            await self._redis.setex(
                key,
                self._settings.cache_ttl,
                response.model_dump_json(),
            )
        except Exception as exc:  # noqa: BLE001
            logger.warning("Erreur écriture cache", error=str(exc))

    # ── Détection de langue ────────────────────────────────────────────────────

    async def detect_language(self, text: str) -> str:
        """Détecte la langue du texte. Retourne le code ISO 639-1."""
        if self._google_client:
            try:
                result = self._google_client.detect_language(text)
                detected: str = result.get("language", "und")
                logger.info("Langue détectée", lang=detected, provider="google")
                return detected
            except Exception as exc:  # noqa: BLE001
                logger.error("Erreur détection Google", error=str(exc))

        if self._deepl_client:
            try:
                # DeepL ne propose pas de détection standalone — on traduit vers EN
                result = self._deepl_client.translate_text(text, target_lang="EN-US")
                detected = result.detected_source_lang.lower()
                logger.info("Langue détectée", lang=detected, provider="deepl")
                return detected
            except Exception as exc:  # noqa: BLE001
                logger.error("Erreur détection DeepL", error=str(exc))

        return "und"  # indéterminé

    # ── Traduction principale ──────────────────────────────────────────────────

    async def translate(self, request: TranslationRequest) -> TranslationResponse:
        """Traduit le texte selon la configuration active."""
        target = request.target_language.value
        source = request.source_language.value if request.source_language else None

        # Vérification cache
        cache_key = self._cache_key(request.text, source, target)
        cached = await self._get_cache(cache_key)
        if cached:
            cached.cached = True
            logger.info("Cache hit", key=cache_key[:16])
            return cached

        # Kirundi : non supporté nativement
        if target == KIRUNDI_CODE or source == KIRUNDI_CODE:
            response = TranslationResponse(
                original_text=request.text,
                translated_text=request.text,
                source_language=source or "und",
                target_language=target,
                provider="kirundi_placeholder",
                cached=False,
            )
            logger.warning(
                "Kirundi non supporté par les providers actuels — texte retourné tel quel",
                target=target,
                source=source,
            )
            return response

        # Auto-détection si nécessaire
        if source is None:
            source = await self.detect_language(request.text)

        # Sélection du provider
        if self._provider == "google" and self._google_client:
            response = await self._translate_google(request.text, source, target)
        elif self._deepl_client:
            response = await self._translate_deepl(request.text, source, target)
        else:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Aucun provider de traduction disponible. Vérifiez vos clés API.",
            )

        await self._set_cache(cache_key, response)
        return response

    # ── Google Translate ───────────────────────────────────────────────────────

    async def _translate_google(
        self, text: str, source: str, target: str
    ) -> TranslationResponse:
        """Appelle l'API Google Cloud Translation."""
        from fastapi import HTTPException, status

        if target not in GOOGLE_SUPPORTED_LANGUAGES:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Langue cible '{target}' non supportée par Google Translate.",
            )
        try:
            result = self._google_client.translate(  # type: ignore[union-attr]
                text,
                source_language=source if source != "und" else None,
                target_language=target,
            )
            detected_src: str = result.get("detectedSourceLanguage", source) or source
            return TranslationResponse(
                original_text=text,
                translated_text=result["translatedText"],
                source_language=detected_src,
                target_language=target,
                provider="google",
                cached=False,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("Erreur Google Translate", error=str(exc))
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Erreur Google Translate : {exc}",
            ) from exc

    # ── DeepL ─────────────────────────────────────────────────────────────────

    async def _translate_deepl(
        self, text: str, source: str, target: str
    ) -> TranslationResponse:
        """Appelle l'API DeepL."""
        from fastapi import HTTPException, status

        # Mapping codes DeepL (EN-US, PT-PT, ZH, …)
        deepl_target_map = {
            "en": "EN-US",
            "pt": "PT-PT",
            "zh": "ZH",
        }
        deepl_target = deepl_target_map.get(target, target.upper())

        if target not in DEEPL_SUPPORTED_LANGUAGES:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Langue cible '{target}' non supportée par DeepL.",
            )
        try:
            result = self._deepl_client.translate_text(  # type: ignore[union-attr]
                text,
                source_lang=source.upper() if source and source != "und" else None,
                target_lang=deepl_target,
            )
            return TranslationResponse(
                original_text=text,
                translated_text=result.text,
                source_language=result.detected_source_lang.lower(),
                target_language=target,
                provider="deepl",
                cached=False,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("Erreur DeepL", error=str(exc))
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Erreur DeepL : {exc}",
            ) from exc
