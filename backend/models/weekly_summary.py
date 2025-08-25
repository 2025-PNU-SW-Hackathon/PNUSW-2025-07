from sqlalchemy import Column, Integer, Text, Float, DateTime, ForeignKey, JSON, UniqueConstraint
from sqlalchemy.sql import func
from database import Base


class WeeklySummaryCache(Base):
    __tablename__ = "weekly_summary_cache"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    period_days = Column(Integer, nullable=False, default=7)
    # 최근 요약 아이템 리스트 (최대 period_days개)
    # 형태: [{"date": "YYYY-MM-DD", "summary": str, "primary_emotion": str}]
    items = Column(JSON, nullable=False, default=list)
    one_line_summary = Column(Text, nullable=True)
    negative_ratio = Column(Float, nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        UniqueConstraint('user_id', 'period_days', name='ux_weekly_summary_user_period'),
    )

