"""
Service de synthèse vocale (TTS) avec Google Text-to-Speech et fallback gTTS.
"""
from __future__ import annotations

import base64
import io
from typing import Optional
from loguru import logger
from gtts import gTTS

from ..config import Settings
from ..models import TTSRequest, TTSResponse, AudioEncoding


class TTSService:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    async def synthesize(self, request: TTSRequest) -> TTSResponse:
        logger.info(f"Synthesizing text: length={len(request.text)}, lang={request.language_code.value}")

        # Si l'API Google officielle est configurée
        if self.settings.tts_provider == "google" and self.settings.google_tts_api_key:
            try:
                return await self._synthesize_google(request)
            except Exception as e:
                logger.warning(f"Google Cloud TTS échoué, repli sur gTTS: {e}")

        # Fallback universel gratuit (gTTS)
        return await self._synthesize_gtts(request)

    async def _synthesize_google(self, request: TTSRequest) -> TTSResponse:
        from google.cloud import texttospeech

        client = texttospeech.TextToSpeechClient()
        s_input = texttospeech.SynthesisInput(text=request.text)
        voice = texttospeech.VoiceSelectionParams(
            language_code=request.language_code.value,
            ssml_gender=texttospeech.SsmlVoiceGender[request.voice_gender.value],
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding[request.audio_encoding.value],
            speaking_rate=request.speaking_rate or self.settings.speaking_rate,
            pitch=request.pitch or self.settings.pitch,
            volume_gain_db=request.volume_gain_db or self.settings.volume_gain_db,
        )

        resp = client.synthesize_speech(input=s_input, voice=voice, audio_config=audio_config)
        audio_b64 = base64.b64encode(resp.audio_content).decode("utf-8")

        return TTSResponse(
            audio_content=audio_b64,
            audio_encoding=request.audio_encoding,
            content_type=self._get_content_type(request.audio_encoding),
            size_bytes=len(resp.audio_content),
            duration_estimate_sec=round(len(request.text.split()) / 2.5, 2),
            provider="google-cloud-tts",
        )

    async def _synthesize_gtts(self, request: TTSRequest) -> TTSResponse:
        # Extraire le code de langue primaire (ex: 'fr-FR' -> 'fr')
        lang_code = request.language_code.value.split("-")[0]
        fp = io.BytesIO()
        tts = gTTS(text=request.text, lang=lang_code, slow=False)
        tts.write_to_fp(fp)
        fp.seek(0)
        audio_bytes = fp.read()
        audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")

        return TTSResponse(
            audio_content=audio_b64,
            audio_encoding=AudioEncoding.MP3,
            content_type="audio/mpeg",
            size_bytes=len(audio_bytes),
            duration_estimate_sec=round(len(request.text.split()) / 2.5, 2),
            provider="gtts-fallback",
        )

    def _get_content_type(self, encoding: AudioEncoding) -> str:
        mapping = {
            AudioEncoding.MP3: "audio/mpeg",
            AudioEncoding.LINEAR16: "audio/wav",
            AudioEncoding.OGG_OPUS: "audio/ogg",
        }
        return mapping.get(encoding, "audio/mpeg")

