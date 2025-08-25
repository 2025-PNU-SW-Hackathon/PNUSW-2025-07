from sqlalchemy.orm import Session
from models.record import Record
from models.user import User
from services.emotion_color_service import EmotionColorService
from services.ai_analysis_service import AIAnalysisService
from typing import List, Optional, Dict
import json

class RecordService:
    
    @staticmethod
    def create_record(
        db: Session,
        user_id: int,
        content: str,
        sleep_score: Optional[int] = None,
        stress_score: Optional[int] = None,
        share_with_counselor: bool = False
    ) -> Record:
        """감정 기록 생성 및 AI 분석 (감정의 바퀴 기반) - 개발자 모드가 아닌 경우 하루에 한 번만 가능"""
        
        # 사용자 정보 조회 (개발자 모드 확인용)
        user = db.query(User).filter(User.id == user_id).first()
        
        # 개발자 모드가 아닌 경우에만 하루 제한 적용
        if not user or not user.is_developer:
            # 오늘 이미 기록이 있는지 확인
            today_record = RecordService._get_today_record(db, user_id)
            if today_record:
                raise ValueError("오늘 이미 감정 기록을 작성했습니다. 하루에 한 번만 가능합니다.")
        
        # AI 키워드 추출 (GPT-4o mini)
        ai_keywords = AIAnalysisService.extract_keywords_with_gpt(content)
        
        # 1차 폴백: GPT 키워드가 비었으면 로컬 키워드 추출 사용
        if not ai_keywords:
            ai_keywords = RecordService._extract_keywords(content)
        
        # AI 요약 생성 (GPT-4o mini 우선 사용)
        ai_summary = AIAnalysisService.generate_summary_with_ai(content)
        
        # 감정 분석 및 색상 생성 (AI API 우선 사용)
        emotion_analysis = AIAnalysisService.analyze_emotion_with_ai(content)
        
        # 2차 폴백: 여전히 키워드가 비었으면 주감정을 최소 1개 키워드로 포함
        if (not ai_keywords) and emotion_analysis:
            primary_kw = emotion_analysis.get("primary_emotion")
            if primary_kw:
                ai_keywords = [primary_kw]

        # Record 생성
        record = Record(
            user_id=user_id,
            content=content,
            sleep_score=sleep_score,
            stress_score=stress_score,
            ai_keywords=ai_keywords,
            ai_summary=ai_summary,
            emotion_analysis=emotion_analysis,
            share_with_counselor=share_with_counselor
        )
        
        db.add(record)
        
        # 일기 작성 시 씨앗 지급 (기본 2개)
        if user:
            user.seeds += 2
        
        db.commit()
        db.refresh(record)
        # 주간 요약 캐시 갱신
        try:
            RecordService._update_weekly_cache_after_create(
                db=db,
                user_id=user_id,
                ai_summary=ai_summary,
                emotion_analysis=emotion_analysis,
                period_days=7
            )
        except Exception:
            pass
        return record

    @staticmethod
    def _update_weekly_cache_after_create(db: Session, user_id: int, ai_summary: str, emotion_analysis: Dict, period_days: int = 7) -> None:
        from datetime import date
        from models.weekly_summary import WeeklySummaryCache

        # 항목 구성
        primary_emotion = None
        try:
            primary_emotion = emotion_analysis.get("primary_emotion") if emotion_analysis else None
        except Exception:
            primary_emotion = None

        item = {
            "date": date.today().isoformat(),
            "summary": ai_summary or "",
            "primary_emotion": primary_emotion or ""
        }

        cache = db.query(WeeklySummaryCache).filter(
            WeeklySummaryCache.user_id == user_id,
            WeeklySummaryCache.period_days == period_days
        ).first()

        if not cache:
            cache = WeeklySummaryCache(
                user_id=user_id,
                period_days=period_days,
                items=[item]
            )
            db.add(cache)
        else:
            items = list(cache.items or [])
            # 같은 날짜 항목이 있으면 교체, 없으면 push
            items = [it for it in items if it.get("date") != item["date"]]
            items.append(item)
            # 길이 제한
            if len(items) > period_days:
                items = items[-period_days:]
            cache.items = items

        # 간단한 부정 비율/한줄 합성
        items = cache.items or []
        neg_emotions = {"우울", "슬픔", "분노", "혐오", "두려움", "불안", "짜증", "화남"}
        total = len(items)
        if total > 0:
            neg_count = sum(1 for it in items if it.get("primary_emotion") in neg_emotions)
            cache.negative_ratio = round(neg_count / total, 3)
            # 간단 합성: 최근 요약 2~3개를 연결
            summaries = [it.get("summary", "") for it in items if it.get("summary")]
            cache.one_line_summary = " ".join(summaries[-3:])[:200]

        db.commit()
    
    @staticmethod
    def get_user_records(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Record]:
        """사용자의 감정 기록 목록 조회 (최신순)"""
        return db.query(Record).filter(Record.user_id == user_id).order_by(Record.created_at.desc()).offset(skip).limit(limit).all()
    
    @staticmethod
    def get_user_records_by_period(db: Session, user_id: int, days: int = 30) -> List[Record]:
        """사용자의 특정 기간 감정 기록 조회 (최신순)"""
        from datetime import datetime, timedelta
        
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        return db.query(Record).filter(
            Record.user_id == user_id,
            Record.created_at >= start_date,
            Record.created_at <= end_date
        ).order_by(Record.created_at.desc()).all()
    
    @staticmethod
    def get_user_records_count(db: Session, user_id: int) -> int:
        """사용자의 총 감정 기록 수 조회"""
        return db.query(Record).filter(Record.user_id == user_id).count()
    
    @staticmethod
    def get_record(db: Session, record_id: int, user_id: int) -> Optional[Record]:
        """특정 감정 기록 조회 (본인 것만)"""
        return db.query(Record).filter(Record.id == record_id, Record.user_id == user_id).first()
    
    @staticmethod
    def get_today_record(db: Session, user_id: int) -> Optional[Record]:
        """오늘 작성한 감정 기록 조회"""
        return RecordService._get_today_record(db, user_id)
    
    @staticmethod
    def update_record(
        db: Session,
        record_id: int,
        user_id: int,
        content: Optional[str] = None,
        sleep_score: Optional[int] = None,
        stress_score: Optional[int] = None,
        share_with_counselor: Optional[bool] = None
    ) -> Optional[Record]:
        """감정 기록 수정"""
        record = db.query(Record).filter(Record.id == record_id, Record.user_id == user_id).first()
        if not record:
            return None
        
        # 업데이트할 필드들
        if content is not None:
            record.content = content
            # 내용이 변경되면 AI 분석도 다시 수행
            record.ai_keywords = RecordService._extract_keywords(content)
            record.ai_summary = RecordService._generate_summary(content)
            record.emotion_analysis = EmotionColorService.analyze_emotion_from_text(content)
        
        if sleep_score is not None:
            record.sleep_score = sleep_score
        
        if stress_score is not None:
            record.stress_score = stress_score
        
        if share_with_counselor is not None:
            record.share_with_counselor = share_with_counselor
        
        db.commit()
        db.refresh(record)
        # 내용 변경 시 주간 캐시도 업데이트
        try:
            RecordService._update_weekly_cache_after_create(
                db=db,
                user_id=user_id,
                ai_summary=record.ai_summary,
                emotion_analysis=record.emotion_analysis,
                period_days=7
            )
        except Exception:
            pass
        return record
    
    @staticmethod
    def delete_record(db: Session, record_id: int, user_id: int) -> bool:
        """감정 기록 삭제"""
        record = db.query(Record).filter(Record.id == record_id, Record.user_id == user_id).first()
        if not record:
            return False
        
        db.delete(record)
        db.commit()
        return True
    
    @staticmethod
    def get_emotion_statistics(db: Session, user_id: int, days: int = 7) -> Dict:
        """감정 통계 조회 (일주일, 이주일, 한달간)"""
        # 최적화된 기간별 조회 메서드 사용
        records = RecordService.get_user_records_by_period(db, user_id, days)
        
        if not records:
            return {
                "period": days,
                "record_count": 0,
                "average_color": EmotionColorService._get_color_with_intensity("기쁨", 5),
                "emotion_distribution": {},
                "message": f"지난 {days}일간의 기록이 없습니다."
            }
        
        # 감정 분포 계산
        emotion_distribution = {}
        for record in records:
            if record.emotion_analysis:
                emotion = record.emotion_analysis.get("primary_emotion", "기쁨")
                emotion_distribution[emotion] = emotion_distribution.get(emotion, 0) + 1
        
        # 평균 색상 계산
        emotion_records = [
            {"color": record.emotion_analysis["color"]} 
            for record in records 
            if record.emotion_analysis
        ]
        average_color = EmotionColorService.get_average_emotion_color(emotion_records)
        
        return {
            "period": days,
            "record_count": len(records),
            "average_color": average_color,
            "emotion_distribution": emotion_distribution,
            "message": f"지난 {days}일간의 평균 감정색은 {average_color['name']}입니다."
        }
    
    @staticmethod
    def _extract_keywords(content: str) -> List[str]:
        """AI 키워드 추출 (간단한 구현)"""
        # 실제로는 더 정교한 AI 모델을 사용해야 함
        keywords = []
        
        # 감정 관련 키워드 (감정의 바퀴 기반)
        emotion_keywords = [
            '기쁨', '신뢰', '두려움', '놀람', '슬픔', '혐오', '분노', '기대',
            '행복', '안전', '불안', '예상', '우울', '짜증', '화남', '희망'
        ]
        
        # 내용에서 감정 키워드 찾기
        for keyword in emotion_keywords:
            if keyword in content:
                keywords.append(keyword)
        
        # 기본 키워드 추가
        if len(keywords) == 0:
            keywords = ['일상', '감정기록']
        
        return keywords[:5]  # 최대 5개 키워드
    
    @staticmethod
    def _get_today_record(db: Session, user_id: int) -> Optional[Record]:
        """오늘 작성한 감정 기록 조회 (내부 메서드)"""
        from datetime import datetime, date
        
        today = date.today()
        
        # 오늘 날짜의 기록 조회 (created_at이 오늘인지 확인)
        return db.query(Record).filter(
            Record.user_id == user_id,
            Record.created_at >= datetime.combine(today, datetime.min.time()),
            Record.created_at <= datetime.combine(today, datetime.max.time())
        ).first()
    
    @staticmethod
    def _generate_summary(content: str) -> str:
        """AI 요약 생성 (간단한 구현)"""
        # 실제로는 더 정교한 AI 모델을 사용해야 함
        # 현재는 감정 분석 결과를 기반으로 요약
        
        # 감정 분석 수행
        emotion_analysis = EmotionColorService.analyze_emotion_from_text(content)
        primary_emotion = emotion_analysis["primary_emotion"]
        intensity = emotion_analysis["intensity"]
        
        # 감정별 요약 템플릿
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
            return emotion_summaries[primary_emotion]
        
        # 기본 요약
        return f"{primary_emotion}한 감정을 느낀 하루였습니다." 