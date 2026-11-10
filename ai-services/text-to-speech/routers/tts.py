"""
Router pour les routes de Text-to-Speech.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
import base64

from ..config import Settings
from ..models import TTSRequest, TTSResponse
from ..services.tts_service import TTSService

router = APIRouter(prefix="/tts", tags=["Text-to-Speech"])


def get_settings() -> Settings:
    return Settings()


def get_tts_service(settings: Settings = Depends(get_settings)) -> TTSService:
    return TTSService(settings)


@router.post("/synthesize", response_model=TTSResponse, status_code=status.HTTP_200_OK)
async def synthesize_speech(
    request: TTSRequest,
    service: TTSService = Depends(get_tts_service),
) -> TTSResponse:
    try:
        return await service.synthesize(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur de synthèse vocale: {str(e)}",
        )


@router.post("/stream", status_code=status.HTTP_200_OK)
async def stream_speech(
    request: TTSRequest,
    service: TTSService = Depends(get_tts_service),
):
    try:
        result = await service.synthesize(request)
        audio_data = base64.b64decode(result.audio_content)
        return Response(content=audio_data, media_type=result.content_type)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur de streaming audio: {str(e)}",
        )

