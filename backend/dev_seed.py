from datetime import date, timedelta, datetime
from typing import List

from database import SessionLocal
from models.weekly_summary import WeeklySummaryCache
from models.record import Record
from services.emotion_color_service import EmotionColorService


def seed_weekly_cache(user_id: int, period_days: int = 7) -> None:
    session = SessionLocal()
    try:
        today = date.today()
        days: List[date] = [today - timedelta(days=i) for i in range(period_days - 1, -1, -1)]
        items = [
            {"date": d.isoformat(), "summary": "우울한 하루였어요", "primary_emotion": "슬픔"}
            for d in days
        ]

        cache = (
            session.query(WeeklySummaryCache)
            .filter(
                WeeklySummaryCache.user_id == user_id,
                WeeklySummaryCache.period_days == period_days,
            )
            .first()
        )
        if not cache:
            cache = WeeklySummaryCache(user_id=user_id, period_days=period_days, items=items)
            session.add(cache)
        else:
            cache.items = items
        cache.negative_ratio = 1.0
        cache.one_line_summary = " ".join([it["summary"] for it in items[-3:]])[:200]
        session.commit()
    finally:
        session.close()


def seed_weekly_records(user_id: int, period_days: int = 7) -> None:
    session = SessionLocal()
    try:
        today = date.today()
        days: List[date] = [today - timedelta(days=i) for i in range(period_days - 1, -1, -1)]
        contents = [
            "오늘 하루 마음이 많이 무겁고 우울했어요.",
            "의욕이 없고 쉽게 지치는 느낌이 들었어요.",
            "작은 일에도 마음이 가라앉고 집중이 잘 안 됐어요.",
            "무기력하고 주변이 희미하게 느껴졌어요.",
            "스스로에 대한 의심이 커지고 우울감이 길게 이어졌어요.",
            "잠이 오지 않고 마음이 자꾸 아래로 끌어내려지는 느낌이었어요.",
            "괜찮아지려 노력했지만 쉽지 않은 하루였어요.",
        ]

        for idx, d in enumerate(days):
            # 동일 날짜 기록이 있으면 업데이트, 없으면 생성
            start_dt = datetime.combine(d, datetime.min.time())
            end_dt = datetime.combine(d, datetime.max.time())
            rec = (
                session.query(Record)
                .filter(Record.user_id == user_id, Record.created_at >= start_dt, Record.created_at <= end_dt)
                .first()
            )
            color_info = EmotionColorService._get_color_with_intensity("슬픔", 7)
            payload = {
                "content": contents[idx % len(contents)],
                "sleep_score": 5,
                "stress_score": 7,
                "ai_keywords": ["슬픔", "우울", "피곤"],
                "ai_summary": "우울한 하루였어요",
                "emotion_analysis": {
                    "primary_emotion": "슬픔",
                    "intensity": 7,
                    "color": color_info,
                },
                "share_with_counselor": False,
                "created_at": datetime.combine(d, datetime.min.time()).replace(hour=12, minute=0, second=0),
            }
            if rec:
                for k, v in payload.items():
                    setattr(rec, k, v)
            else:
                rec = Record(user_id=user_id, **payload)
                session.add(rec)

        session.commit()
    finally:
        session.close()

