from sqlalchemy import Column, Integer, String, Text, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Record(Base):
    __tablename__ = "records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    content = Column(Text, nullable=False)  # 감정 기록 내용
    
    # 수면 및 스트레스 점수 (1-10)
    sleep_score = Column(Integer, nullable=True)
    stress_score = Column(Integer, nullable=True)
    
    # AI 분석 결과 (감정의 바퀴 기반)
    ai_keywords = Column(JSON, nullable=True)  # AI가 추출한 키워드들
    ai_summary = Column(Text, nullable=True)  # AI가 생성한 한 줄 요약
    emotion_analysis = Column(JSON, nullable=True)  # 감정 분석 결과 (색상 포함)
    
    # 상담 공유 설정 (기본값: false)
    share_with_counselor = Column(Boolean, default=False, nullable=False)
    
    # 생성 시간
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    
    # 관계 설정
    user = relationship("User", back_populates="records") 