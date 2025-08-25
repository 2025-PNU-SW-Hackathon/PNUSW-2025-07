from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from database import get_db
from services.voice_service import VoiceService
from services.user_service import get_current_user
from models.user import User
from typing import Dict
import logging

router = APIRouter(prefix="/voice", tags=["voice"])

@router.post("/stt")
async def speech_to_text(
    audio_file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict:
    """음성 파일을 텍스트로 변환"""
    try:
        # 디버깅: 파일 정보 로그
        logging.info(f"업로드된 파일 정보:")
        logging.info(f"  - 파일명: {audio_file.filename}")
        logging.info(f"  - Content-Type: {audio_file.content_type}")
        logging.info(f"  - 파일 크기: {audio_file.size}")
        
        # 파일 형식 검증 (다양한 오디오 형식 허용)
        allowed_types = [
            'audio/',           # 일반 오디오 형식
            'video/webm',       # WebM (브라우저에서 사용)
            'application/octet-stream'  # 바이너리 데이터
        ]
        
        if audio_file.content_type:
            is_allowed = any(audio_file.content_type.startswith(t) for t in allowed_types)
            if not is_allowed:
                logging.warning(f"지원되지 않는 파일 형식: {audio_file.content_type}")
                raise HTTPException(status_code=400, detail=f"지원되지 않는 파일 형식입니다: {audio_file.content_type}")
        else:
            logging.warning("Content-Type이 없는 파일 업로드")
        
        # 파일 크기 검증 (10MB 제한)
        if audio_file.size and audio_file.size > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="파일 크기는 10MB 이하여야 합니다")
        
        # 오디오 데이터 읽기
        audio_data = await audio_file.read()
        
        # VoiceService 초기화
        voice_service = VoiceService()
        
        # 오디오 형식 검증
        validation_result = voice_service.validate_audio_format(audio_data)
        if not validation_result["valid"]:
            raise HTTPException(status_code=400, detail=validation_result["error"])
        
        # 음성인식 수행
        stt_result = voice_service.speech_to_text(audio_data)
        
        if not stt_result["success"]:
            raise HTTPException(status_code=500, detail=stt_result["error"])
        
        return {
            "success": True,
            "text": stt_result["text"],
            "confidence": stt_result["confidence"],
            "message": "음성인식이 완료되었습니다"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"음성인식 처리 중 오류: {str(e)}")
        raise HTTPException(status_code=500, detail="음성인식 처리 중 오류가 발생했습니다")

@router.post("/voice-to-emotion")
async def voice_to_emotion(
    audio_file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """음성 파일을 텍스트로 변환 후 감정 분석"""
    
    try:
        # 1단계: 음성을 텍스트로 변환
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(audio_file.filename)[1]) as temp_file:
            content = await audio_file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name
        
        text = AIAnalysisService.speech_to_text_with_clova(temp_file_path)
        os.unlink(temp_file_path)
        
        if not text:
            raise HTTPException(
                status_code=500,
                detail="음성 인식에 실패했습니다."
            )
        
        # 2단계: 텍스트를 감정 분석
        emotion_analysis = AIAnalysisService.analyze_emotion_with_ai(text)
        
        # 3단계: 요약 생성
        summary = AIAnalysisService.generate_summary_with_ai(text)
        
        return {
            "success": True,
            "original_text": text,
            "emotion_analysis": emotion_analysis,
            "summary": summary,
            "message": "음성 분석이 완료되었습니다."
        }
        
    except Exception as e:
        # 임시 파일 정리
        if 'temp_file_path' in locals():
            try:
                os.unlink(temp_file_path)
            except:
                pass
        
        raise HTTPException(
            status_code=500,
            detail=f"음성 분석 중 오류가 발생했습니다: {str(e)}"
        ) 