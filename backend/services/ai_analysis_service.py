"""
통합 AI 분석 서비스
- 텍스트 요약: GPT-4o mini
- 감정 분류: GPT-4o mini
- 음성 인식: NAVER CLOVA Speech Recognition (CSR)
"""
import os
import json
import base64
from typing import Dict, Optional
import requests
from openai import OpenAI
from dotenv import load_dotenv

# 환경 변수 로딩
load_dotenv(dotenv_path=".env")

class AIAnalysisService:
    """통합 AI 분석 서비스"""
    
    @staticmethod
    def analyze_emotion_with_gpt4o(content: str) -> Optional[Dict]:
        """GPT-4o mini를 사용한 감정 분석"""
        try:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                return None
            
            # 최신 openai 패키지와 호환되도록 수정
            try:
                client = OpenAI(api_key=api_key)
            except TypeError as e:
                if "proxies" in str(e):
                    # proxies 인자 문제가 있는 경우 기본 설정으로 생성
                    client = OpenAI(api_key=api_key, base_url="https://api.openai.com/v1")
                else:
                    raise e
            
            prompt = f"""
            다음 텍스트의 감정을 로버트 플루치크의 감정의 바퀴 8가지 중에서 분석해주세요:
            감정: 기쁨, 신뢰, 두려움, 놀람, 슬픔, 혐오, 분노, 기대
            
            텍스트: {content}
            
            반드시 다음 JSON 형태로만 응답해주세요. 다른 텍스트는 포함하지 마세요:
            {{
                "primary_emotion": "감정명",
                "intensity": 1-10 사이의 감정 강도 (1: 매우 약함, 10: 매우 강함),
                "confidence": 0.0-1.0 사이의 분석 확신도 (0.0: 매우 불확실, 1.0: 매우 확실),
                "reasoning": "분석 근거",
                "color_name": "이 감정을 나타내는 색상의 이름 (예: 선명한 빨강, 밝은 노랑, 깊은 파랑 등)"
            }}
            """
            
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3
            )
            
            content = response.choices[0].message.content
            
            try:
                result = json.loads(content)
                return result
            except json.JSONDecodeError as e:
                return None
            
        except Exception as e:
            return None
    
    @staticmethod
    def generate_summary_with_gpt4o(content: str) -> Optional[str]:
        """GPT-4o mini를 사용한 텍스트 요약"""
        try:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                return None
            
            # 최신 openai 패키지와 호환되도록 수정
            try:
                client = OpenAI(api_key=api_key)
            except TypeError as e:
                if "proxies" in str(e):
                    # proxies 인자 문제가 있는 경우 기본 설정으로 생성
                    client = OpenAI(api_key=api_key, base_url="https://api.openai.com/v1")
                else:
                    raise e
            
            prompt = f"""
            다음 감정 기록을 한 줄로 요약해주세요. 
            감정의 핵심과 주요 내용을 간결하게 표현해주세요.
            
            텍스트: {content}
            
            요약:
            """
            
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=100
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            return None
    
    @staticmethod
    def speech_to_text_with_clova(audio_file_path: str) -> Optional[str]:
        """NAVER CLOVA Speech Recognition을 사용한 음성 인식"""
        try:
            # CLOVA API 설정
            api_url = "https://naveropenapi.apigw.ntruss.com/recog/v1/stt"
            client_id = os.getenv("CLOVA_CLIENT_ID")
            client_secret = os.getenv("CLOVA_CLIENT_SECRET")
            
            if not client_id or not client_secret:
                return None
            
            headers = {
                "X-OCR-SECRET": client_secret,
                "Content-Type": "application/octet-stream"
            }
            
            # 오디오 파일 읽기
            with open(audio_file_path, "rb") as audio_file:
                audio_data = audio_file.read()
            
            # API 호출
            response = requests.post(
                api_url,
                headers=headers,
                data=audio_data
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("text", "")
            
            return None
            
        except Exception as e:
            return None
    
    @staticmethod
    def analyze_emotion_fallback(content: str) -> Dict:
        """AI API 실패 시 더 정확한 기본 감정 분석"""

        
        # 부정적 키워드 기반 분석
        negative_keywords = {
            '힘들', '어렵', '스트레스', '피곤', '지치', '불안', '걱정', '우울', '슬픔', 
            '화나', '짜증', '답답', '절망', '무기력', '의미없', '싫', '혐오', '두려움',
            '무섭', '놀람', '충격', '실망', '후회', '미안', '죄송', '부끄러', '창피',
            '죽고싶', '자살', '끝내', '그만', '싫어', '힘들어', '지쳐', '피곤해'
        }
        
        positive_keywords = {
            '기쁘', '행복', '즐겁', '신나', '좋', '만족', '감사', '희망', '기대', 
            '설렘', '신뢰', '안전', '편안', '평온', '차분', '여유', '성취', '성공',
            '자랑', '뿌듯', '감동', '감탄', '놀라', '신기', '재미', '웃음'
        }
        
        content_lower = content.lower()
        
        # 키워드 점수 계산
        negative_score = sum(1 for keyword in negative_keywords if keyword in content_lower)
        positive_score = sum(1 for keyword in positive_keywords if keyword in content_lower)
        

        
        # 감정 결정 (수정된 로직)
        if negative_score > positive_score:
            # 부정적 감정 중에서 세분화
            if any(k in content_lower for k in ['힘들', '지치', '피곤', '무기력', '절망', '죽고싶']):
                primary_emotion = "슬픔"
            elif any(k in content_lower for k in ['화나', '짜증', '답답']):
                primary_emotion = "분노"
            elif any(k in content_lower for k in ['불안', '걱정', '두려움', '무섭']):
                primary_emotion = "두려움"
            elif any(k in content_lower for k in ['놀람', '충격', '신기']):
                primary_emotion = "놀람"
            else:
                primary_emotion = "슬픔"
            intensity = min(10, max(1, negative_score * 2))
        elif positive_score > negative_score:
            primary_emotion = "기쁨"
            intensity = min(10, max(1, positive_score * 2))
        else:
            # 중립적이거나 혼재된 경우 - 더 정확한 판단
            if negative_score == 0 and positive_score == 0:
                primary_emotion = "신뢰"  # 정말 중립적인 경우만
            else:
                # 혼재된 경우 부정적 감정 우선
                primary_emotion = "슬픔"
            intensity = 5
        

        
        # 색상 정보 생성
        from services.emotion_color_service import EmotionColorService
        color_info = EmotionColorService._get_color_with_intensity(primary_emotion, intensity)
        
        return {
            "primary_emotion": primary_emotion,
            "intensity": intensity,
            "confidence": 0.6,  # 폴백이므로 신뢰도 낮게
            "reasoning": f"키워드 분석 결과: 부정({negative_score}), 긍정({positive_score}) - 폴백 분석 사용",
            "color": color_info,
            "message": f"오늘의 감정색은 {color_info['name']}입니다~ (키워드 분석)",
            "ai_used": False
        }
    
    @staticmethod
    def generate_summary_fallback(content: str) -> str:
        """AI API 실패 시 더 정확한 기본 요약 생성"""

        
        # 감정 분석 결과를 기반으로 요약
        emotion_analysis = AIAnalysisService.analyze_emotion_fallback(content)
        primary_emotion = emotion_analysis["primary_emotion"]
        
        # 감정별 요약 템플릿 (더 정확한 매칭)
        emotion_summaries = {
            '기쁨': '긍정적이고 기쁜 감정을 느낀 하루였습니다.',
            '신뢰': '안정감과 신뢰를 느낀 하루였습니다.',
            '두려움': '불안하고 두려운 감정이 있었던 하루였습니다.',
            '놀람': '예상치 못한 일로 놀란 하루였습니다.',
            '슬픔': '슬프고 우울한 감정이 있었던 하루였습니다.',
            '혐오': '불쾌하고 싫은 감정이 있었던 하루였습니다.',
            '분노': '화가 나고 분노한 감정이 있었던 하루였습니다.',
            '기대': '희망과 기대를 느낀 하루였습니다.'
        }
        
        # 감정에 맞는 요약 반환
        if primary_emotion in emotion_summaries:
            summary = emotion_summaries[primary_emotion]
            return summary
        
        # 기본 요약
        summary = f"{primary_emotion}한 감정을 느낀 하루였습니다."
        return summary
    
    @staticmethod
    def analyze_emotion_with_ai(content: str) -> Dict:
        """GPT-4o mini를 우선 사용하고, 실패 시 기본 분석 사용"""
        # GPT-4o mini 시도
        result = AIAnalysisService.analyze_emotion_with_gpt4o(content)
        if result:
            return AIAnalysisService._convert_ai_result_to_color(result)
        
        # 기본 분석 사용
        fallback_result = AIAnalysisService.analyze_emotion_fallback(content)
        fallback_result["ai_failed"] = True
        fallback_result["error_message"] = "AI API 호출에 실패하여 키워드 기반 분석을 사용했습니다."
        return fallback_result
    
    @staticmethod
    def generate_summary_with_ai(content: str) -> str:
        """GPT-4o mini를 우선 사용하고, 실패 시 기본 요약 사용"""
        
        # GPT-4o mini 시도
        summary = AIAnalysisService.generate_summary_with_gpt4o(content)
        if summary:
            return summary
        
        # 기본 요약 사용
        return AIAnalysisService.generate_summary_fallback(content)
    
    @staticmethod
    def extract_keywords_with_gpt(content: str) -> list:
        """GPT-4o mini를 사용한 감정 키워드 추출 (JSON 배열 파싱, 견고한 폴백 포함)"""
        try:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                return AIAnalysisService._extract_keywords_fallback(content)
            client = OpenAI(api_key=api_key)
            prompt = f"""
            다음 텍스트에서 감정과 관련된 핵심 키워드 3~5개만 뽑아주세요.
            반드시 아래 JSON 형식으로만, 추가 설명 없이 반환하세요.
            {{
              "keywords": ["키워드1", "키워드2", "키워드3"]
            }}

            텍스트: {content}
            """
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
                max_tokens=120
            )
            raw = (response.choices[0].message.content or "").strip()
            # 1) JSON 파싱 시도
            try:
                data = json.loads(raw)
                kws = data.get("keywords", []) if isinstance(data, dict) else []
            except Exception:
                # 2) 본문에서 JSON 객체 추출 시도
                import re
                match = re.search(r"\{[\s\S]*\}", raw)
                if match:
                    try:
                        data = json.loads(match.group(0))
                        kws = data.get("keywords", []) if isinstance(data, dict) else []
                    except Exception:
                        kws = []
                else:
                    kws = []
            # 3) 문자열로만 온 경우 대비: 쉼표 분리 폴백
            if not kws and raw:
                kws = [k.strip() for k in raw.split(',') if k.strip()]
            # 정제: 중복 제거, 길이 제한
            dedup = []
            seen = set()
            for k in kws:
                if not isinstance(k, str):
                    continue
                k = k.strip()
                if not k or k in seen:
                    continue
                seen.add(k)
                dedup.append(k)
            
            # 결과가 있으면 반환, 없으면 폴백 사용
            if dedup:
                return dedup[:5]
            else:
                return AIAnalysisService._extract_keywords_fallback(content)
                
        except Exception as e:
            return AIAnalysisService._extract_keywords_fallback(content)
    
    @staticmethod
    def _extract_keywords_fallback(content: str) -> list:
        """키워드 추출 실패 시 감정 관련 키워드 추출"""

        
        # 감정 관련 키워드 사전
        emotion_keywords = {
            '기쁨': ['기쁨', '행복', '즐거움', '신남', '좋음', '만족', '감사', '희망', '기대'],
            '슬픔': ['슬픔', '우울', '힘듦', '지침', '피곤', '무기력', '절망', '실망'],
            '분노': ['분노', '화남', '짜증', '답답', '열받음', '화가남'],
            '두려움': ['두려움', '불안', '걱정', '무섭', '긴장', '스트레스'],
            '놀람': ['놀람', '충격', '예상외', '신기', '놀라움'],
            '신뢰': ['신뢰', '안전', '편안', '평온', '차분', '여유'],
            '혐오': ['혐오', '싫음', '불쾌', '역겨움'],
            '기대': ['기대', '설렘', '희망', '미래', '꿈']
        }
        
        content_lower = content.lower()
        found_keywords = []
        
        # 각 감정 카테고리에서 매칭되는 키워드 찾기
        for emotion, keywords in emotion_keywords.items():
            for keyword in keywords:
                if keyword in content_lower:
                    found_keywords.append(keyword)
                    break  # 각 감정당 하나씩만
        
        # 감정 분석 결과에서 primary_emotion을 키워드로 사용 (우선순위 높음)
        emotion_analysis = AIAnalysisService.analyze_emotion_fallback(content)
        primary_emotion = emotion_analysis["primary_emotion"]
        
        # primary_emotion이 이미 있으면 추가하지 않음
        if primary_emotion not in found_keywords:
            found_keywords.insert(0, primary_emotion)  # 맨 앞에 추가
        
        # 최소 1개는 반환
        if not found_keywords:
            found_keywords.append(primary_emotion)
        
        return found_keywords[:5]
    
    @staticmethod
    def generate_average_color_name_with_gpt(emotion_records: list) -> str:
        """GPT-4o mini를 사용한 평균 색상 이름 생성"""
        try:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                return "평균 감정색"
            
            client = OpenAI(api_key=api_key)
            
            # 감정 기록 요약
            emotions_summary = []
            for record in emotion_records:
                emotion = record.get('emotion_analysis', {}).get('primary_emotion', '알 수 없음')
                color_name = record.get('emotion_analysis', {}).get('color', {}).get('name', '알 수 없음')
                emotions_summary.append(f"{emotion}({color_name})")
            
            emotions_text = ", ".join(emotions_summary)
            
            prompt = f"""
            다음 감정 기록들의 평균을 나타내는 색상 이름을 창의적으로 만들어주세요.
            
            감정 기록들: {emotions_text}
            기간: {len(emotion_records)}일간
            
            예시: "따뜻한 노랑", "차분한 파랑", "활기찬 주황" 등
            색상 이름만 반환해주세요. 다른 설명은 포함하지 마세요.
            """
            
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=30
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            return "평균 감정색"
    
    @staticmethod
    def _convert_ai_result_to_color(ai_result: Dict) -> Dict:
        """AI 분석 결과를 색상 정보로 변환"""
        from services.emotion_color_service import EmotionColorService
        
        primary_emotion = ai_result.get("primary_emotion", "기쁨")
        intensity = ai_result.get("intensity", 5)
        ai_color_name = ai_result.get("color_name", "")
        
        # AI가 제공한 색상 이름이 있으면 사용, 없으면 기본 색상 사용
        if ai_color_name:
            color_info = EmotionColorService._get_color_with_intensity(primary_emotion, intensity)
            color_info["name"] = ai_color_name  # AI가 제공한 색상 이름으로 덮어쓰기
        else:
            color_info = EmotionColorService._get_color_with_intensity(primary_emotion, intensity)
        
        return {
            "primary_emotion": primary_emotion,
            "intensity": intensity,
            "confidence": ai_result.get("confidence", 0.5),
            "reasoning": ai_result.get("reasoning", ""),
            "color": color_info,
            "message": f"오늘의 감정색은 {color_info['name']}입니다~ (AI 분석)",
            "ai_used": True
        } 