"""
Service Speech-to-Text — InterConnect Burundi.

Fournisseurs supportés :
  - OpenAI Whisper (local, via `openai-whisper`)
  - Google Cloud Speech-to-Text v1

L'audio est reçu en mémoire (BytesIO) et n'est jamais écrit sur disque de façon permanente.
Un fichier temporaire est utilisé le temps du traitement si nécessaire.
"""
from __future__ import annotations

import io
import tempfile
from pathlib import Path
from typing import TYPE_CHECKING

import structlog

if TYPE_CHECKING:
    pass

logger = structlog.get_logger(__name__)

try:
    import whisper  # type: ignore[import-untyped]

    _WHISPER_AVAILABLE = True
except ImportError:
    _WHISPER_AVAILABLE = False
    logger.info("openai-whisper optionnel non installé (fallback actif)")

try:
    from google.cloud import speech as google_speech  # type: ignore[import-untyped]

    _GOOGLE_SPEECH_AVAILABLE = True
except ImportError:
    _GOOGLE_SPEECH_AVAILABLE = False
    logger.info("google-cloud-speech optionnel non installé (fallback actif)")

from speech_to_text.config import Settings
from speech_to_text.models import TranscriptionResponse, TranscriptionSegment


class STTService:
    """Service de transcription audio multi-fournisseur."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._provider = settings.stt_provider
        self._whisper_model: "whisper.Whisper | None" = None
        self._google_client: "google_speech.SpeechClient | None" = None

    async def startup(self) -> None:
        """Charge le modèle Whisper ou initialise le client Google au démarrage."""
        if self._provider == "whisper":
            if not _WHISPER_AVAILABLE:
                logger.error("openai-whisper requis mais non installé")
                return
            logger.info(
                "Chargement du modèle Whisper",
                model=self._settings.whisper_model,
                device=self._settings.whisper_device,
            )
            self._whisper_model = whisper.load_model(
                self._settings.whisper_model,
                device=self._settings.whisper_device,
            )
            logger.info("Modèle Whisper chargé")

        elif self._provider == "google":
            if not _GOOGLE_SPEECH_AVAILABLE:
                logger.error("google-cloud-speech requis mais non installé")
                return
            self._google_client = google_speech.SpeechClient(
                client_options={"api_key": self._settings.google_speech_api_key}
            )
            logger.info("Client Google Speech initialisé")

    async def shutdown(self) -> None:
        """Libère les ressources."""
        self._whisper_model = None
        logger.info("STT service arrêté")

    # ── Validation de la taille ────────────────────────────────────────────────

    def validate_audio_size(self, audio_bytes: bytes) -> None:
        """Lève une HTTPException si le fichier dépasse la taille maximale configurée."""
        from fastapi import HTTPException, status

        max_bytes = self._settings.max_audio_size_mb * 1024 * 1024
        if len(audio_bytes) > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=(
                    f"Fichier audio trop volumineux. "
                    f"Maximum : {self._settings.max_audio_size_mb} MB."
                ),
            )

    # ── Transcription principale ───────────────────────────────────────────────

    async def transcribe(
        self,
        audio_bytes: bytes,
        content_type: str,
        language_hint: str | None = None,
    ) -> TranscriptionResponse:
        """Transcrit l'audio et retourne le texte + métadonnées."""
        self.validate_audio_size(audio_bytes)

        if self._provider == "whisper":
            return await self._transcribe_whisper(audio_bytes, language_hint)
        elif self._provider == "google":
            return await self._transcribe_google(audio_bytes, content_type, language_hint)
        else:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Aucun provider STT disponible.",
            )

    # ── Whisper ────────────────────────────────────────────────────────────────

    async def _transcribe_whisper(
        self,
        audio_bytes: bytes,
        language_hint: str | None,
    ) -> TranscriptionResponse:
        from fastapi import HTTPException, status

        if not self._whisper_model:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Modèle Whisper non chargé.",
            )

        # Écriture dans un fichier temporaire (Whisper requiert un fichier)
        suffix = ".wav"
        try:
            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name

            options: dict = {"verbose": False}
            if language_hint:
                options["language"] = language_hint

            result = self._whisper_model.transcribe(tmp_path, **options)
        except Exception as exc:  # noqa: BLE001
            logger.error("Erreur Whisper", error=str(exc))
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Erreur Whisper : {exc}",
            ) from exc
        finally:
            Path(tmp_path).unlink(missing_ok=True)

        segments = [
            TranscriptionSegment(
                start=s["start"],
                end=s["end"],
                text=s["text"].strip(),
            )
            for s in result.get("segments", [])
        ]

        return TranscriptionResponse(
            transcript=result["text"].strip(),
            detected_language=result.get("language", "und"),
            confidence=None,  # Whisper ne fournit pas de score global
            provider="whisper",
            duration_seconds=float(segments[-1].end) if segments else None,
            segments=segments or None,
        )

    # ── Google Speech ──────────────────────────────────────────────────────────

    async def _transcribe_google(
        self,
        audio_bytes: bytes,
        content_type: str,
        language_hint: str | None,
    ) -> TranscriptionResponse:
        from fastapi import HTTPException, status

        if not self._google_client:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Client Google Speech non initialisé.",
            )

        # Mapping MIME → encoding Google
        encoding_map = {
            "audio/wav": google_speech.RecognitionConfig.AudioEncoding.LINEAR16,
            "audio/mpeg": google_speech.RecognitionConfig.AudioEncoding.MP3,
            "audio/flac": google_speech.RecognitionConfig.AudioEncoding.FLAC,
            "audio/ogg": google_speech.RecognitionConfig.AudioEncoding.OGG_OPUS,
            "audio/webm": google_speech.RecognitionConfig.AudioEncoding.WEBM_OPUS,
        }
        encoding = encoding_map.get(
            content_type,
            google_speech.RecognitionConfig.AudioEncoding.ENCODING_UNSPECIFIED,
        )
        lang_code = f"{language_hint}-CM" if language_hint else "fr-FR"

        config = google_speech.RecognitionConfig(
            encoding=encoding,
            language_code=lang_code,
            enable_automatic_punctuation=True,
        )
        audio = google_speech.RecognitionAudio(content=audio_bytes)

        try:
            response = self._google_client.recognize(config=config, audio=audio)
        except Exception as exc:  # noqa: BLE001
            logger.error("Erreur Google Speech", error=str(exc))
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Erreur Google Speech : {exc}",
            ) from exc

        if not response.results:
            return TranscriptionResponse(
                transcript="",
                detected_language=language_hint or "und",
                confidence=0.0,
                provider="google",
            )

        best = response.results[0].alternatives[0]
        return TranscriptionResponse(
            transcript=best.transcript,
            detected_language=language_hint or "und",
            confidence=best.confidence,
            provider="google",
        )
