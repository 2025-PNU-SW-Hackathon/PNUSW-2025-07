from datetime import datetime, timedelta, timezone, date, time
from typing import List

from database import SessionLocal
from models.user import User
from models.record import Record
from models.weekly_summary import WeeklySummaryCache


def upsert_daily_record(session, user_id: int, day: date, content: str, summary: str, primary_emotion: str) -> None:
    start_dt = datetime.combine(day, time.min).replace(tzinfo=None)
    end_dt = datetime.combine(day, time.max).replace(tzinfo=None)

    rec = (
        session.query(Record)
        .filter(
            Record.user_id == user_id,
            Record.created_at >= start_dt,
            Record.created_at <= end_dt,
        )
        .first()
    )
    payload = {
        "content": content,
        "sleep_score": 5,
        "stress_score": 7,
        "ai_keywords": ["우울", "피곤"],
        "ai_summary": summary,
        "emotion_analysis": {
            "primary_emotion": primary_emotion,
            "intensity": 7,
            "color": {"name": "우울", "hex": "#6B7C93"},
        },
        "share_with_counselor": False,
        "created_at": datetime.combine(day, time(hour=12, minute=0, second=0)),
    }
    if rec:
        for k, v in payload.items():
            setattr(rec, k, v)
    else:
        rec = Record(user_id=user_id, **payload)
        session.add(rec)


def seed_weekly_negative_for_user(user_id: int = 1) -> None:
    session = SessionLocal()
    try:
        user = session.query(User).filter(User.id == user_id).first()
        if not user:
            print(f"User {user_id} not found")
            return
        # 개발자 계정으로 표시
        if not getattr(user, "is_developer", False):
            try:
                user.is_developer = True
            except Exception:
                pass
        session.commit()

        today = date.today()
        days: List[date] = [today - timedelta(days=i) for i in range(6, -1, -1)]

        # 더미 내용 구성
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
            content = contents[idx % len(contents)]
            summary = "우울한 하루였어요"
            upsert_daily_record(session, user_id, d, content, summary, "우울")

        # 주간 요약 캐시 업데이트
        cache = (
            session.query(WeeklySummaryCache)
            .filter(WeeklySummaryCache.user_id == user_id, WeeklySummaryCache.period_days == 7)
            .first()
        )
        items = [{"date": d.isoformat(), "summary": "우울한 하루였어요", "primary_emotion": "우울"} for d in days]
        if not cache:
            cache = WeeklySummaryCache(user_id=user_id, period_days=7, items=items)
            session.add(cache)
        else:
            cache.items = items
        cache.negative_ratio = 1.0
        cache.one_line_summary = " ".join([it["summary"] for it in items[-3:]])[:200]

        session.commit()
        print("Seeded 7 days of negative records and weekly cache for user_id=", user_id)
    finally:
        session.close()


if __name__ == "__main__":
    seed_weekly_negative_for_user(1)

