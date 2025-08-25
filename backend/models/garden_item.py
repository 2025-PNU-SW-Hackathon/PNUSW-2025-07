from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class GardenItem(Base):
    __tablename__ = "garden_items"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    item_type = Column(String(50), nullable=False)  # 'background', 'decoration', 'plant', 'water'
    item_name = Column(String(100), nullable=False)
    item_image = Column(String(255), nullable=True)  # 이미지 URL
    position_x = Column(Integer, default=0)  # 정원에서의 X 위치
    position_y = Column(Integer, default=0)  # 정원에서의 Y 위치
    layer = Column(Integer, default=0)  # 레이어 순서 (0: 배경, 1: 중간, 2: 앞)
    is_equipped = Column(Boolean, default=False)  # 정원에 배치되었는지
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    user = relationship("User", back_populates="garden_items")

class GardenItemTemplate(Base):
    __tablename__ = "garden_item_templates"
    
    id = Column(Integer, primary_key=True, index=True)
    item_type = Column(String(50), nullable=False)  # 'background', 'decoration', 'plant', 'water'
    item_name = Column(String(100), nullable=False)
    item_description = Column(String(500), nullable=True)
    item_image = Column(String(255), nullable=True)
    price = Column(Integer, nullable=False)  # 씨앗 가격
    rarity = Column(String(20), default='common')  # 'common', 'rare', 'epic', 'legendary'
    layer = Column(Integer, default=0)  # 기본 레이어 (0: 배경, 1: 중간, 2: 앞)
    is_available = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow) 