import os
import json
import base64
import requests
from typing import Dict, Optional
import logging
import io
from pydub import AudioSegment

class VoiceService:
    """Naver Clova STT를 사용한 음성인식 서비스"""
    
    def __init__(self):
        # 환경 변수 이름을 일치시킴
        self.client_id = os.getenv("CLOVA_CLIENT_ID") or os.getenv("NAVER_CLIENT_ID")
        self.client_secret = os.getenv("CLOVA_CLIENT_SECRET") or os.getenv("NAVER_CLIENT_SECRET")
        self.stt_url = "https://naveropenapi.apigw.ntruss.com/recog/v1/stt"
        
        if not self.client_id or not self.client_secret:
            logging.warning("Naver Clova API 키가 설정되지 않았습니다.")
            logging.warning(f"CLOVA_CLIENT_ID: {self.client_id}")
            logging.warning(f"CLOVA_CLIENT_SECRET: {self.client_secret}")
    
    def convert_webm_to_wav(self, audio_data: bytes) -> bytes:
        """WebM 오디오를 WAV로 변환"""
        try:
            # 메모리에서 오디오 데이터 로드
            audio_segment = AudioSegment.from_file(
                io.BytesIO(audio_data), 
                format="webm"
            )
            
            # WAV 형식으로 변환 (16kHz, 모노)
            audio_segment = audio_segment.set_frame_rate(16000).set_channels(1)
            
            # 메모리에 WAV 데이터 저장
            wav_buffer = io.BytesIO()
            audio_segment.export(wav_buffer, format="wav")
            
            return wav_buffer.getvalue()
            
        except Exception as e:
            logging.error(f"WebM to WAV 변환 오류: {str(e)}")
            # 변환 실패 시 원본 데이터 반환
            return audio_data

    def _map_language(self, language: str) -> str:
        """클로바 STT 언어 코드로 매핑 (STT005 방지)"""
        lang = (language or "").lower()
        mapping = {
            "ko": "Kor",
            "ko-kr": "Kor",
            "kor": "Kor",
            "en": "Eng",
            "en-us": "Eng",
            "eng": "Eng",
            "ja": "Jpn",
            "ja-jp": "Jpn",
            "jpn": "Jpn",
            "zh": "Chn",
            "zh-cn": "Chn",
            "chn": "Chn",
        }
        return mapping.get(lang, "Kor")
    
    def speech_to_text(self, audio_data: bytes, language: str = "ko") -> Dict:
        """음성 데이터를 텍스트로 변환"""
        if not self.client_id or not self.client_secret:
            return {
                "success": False,
                "error": "Naver Clova API 키가 설정되지 않았습니다."
            }
        
        try:
            # 언어 매핑
            clova_lang = self._map_language(language)
            params = {
                "lang": clova_lang
            }
            
            headers = {
                "X-NCP-APIGW-API-KEY-ID": self.client_id,
                "X-NCP-APIGW-API-KEY": self.client_secret,
                "Content-Type": "application/octet-stream"
            }
            
            # 디버깅용 로그 제거 (필요 시만 활성화)
            # logging.info(f"Clova STT 요청: {self.stt_url}")
            # logging.info(f"파라미터: {params}")
            # logging.info(f"오디오 데이터 크기: {len(audio_data)} bytes")
            
            response = requests.post(
                self.stt_url,
                headers=headers,
                params=params,
                data=audio_data
            )
            
            # 상세 응답 로그 제거
            # logging.info(f"Clova STT 응답 상태: {response.status_code}")
            # logging.info(f"Clova STT 응답 내용: {response.text}")
            
            if response.status_code == 200:
                result = response.json()
                return {
                    "success": True,
                    "text": result.get("text", ""),
                    "confidence": result.get("confidence", 0.0)
                }
            else:
                error_msg = f"STT API 오류: {response.status_code} - {response.text}"
                logging.error(error_msg)
                return {
                    "success": False,
                    "error": error_msg
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"음성인식 처리 중 오류 발생: {str(e)}"
            }
    
    def validate_audio_format(self, audio_data: bytes) -> Dict:
        """오디오 형식 검증"""
        try:
            # 기본적인 오디오 형식 검증
            if len(audio_data) == 0:
                return {"valid": False, "error": "빈 오디오 데이터"}
            
            if len(audio_data) > 10 * 1024 * 1024:  # 10MB 제한
                return {"valid": False, "error": "오디오 파일이 너무 큽니다 (최대 10MB)"}
            
            return {"valid": True}
            
        except Exception as e:
            return {"valid": False, "error": f"오디오 형식 검증 오류: {str(e)}"} 