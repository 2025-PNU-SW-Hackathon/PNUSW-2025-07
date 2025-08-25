from fastapi import FastAPI
import os
import logging
from sqlalchemy import text
from database import Base, engine

# 기본 모델들만 먼저 import
try:
    from models.user import User
    logging.info("User model imported successfully")
except Exception as e:
    logging.error(f"Failed to import User model: {e}")
    User = None

try:
    from models.record import Record
    logging.info("Record model imported successfully")
except Exception as e:
    logging.error(f"Failed to import Record model: {e}")
    Record = None

try:
    from models.garden_item import GardenItem, GardenItemTemplate
    logging.info("Garden models imported successfully")
except Exception as e:
    logging.error(f"Failed to import Garden models: {e}")
    GardenItem = None
    GardenItemTemplate = None

# 추가 모델들은 나중에 import (존재하는 것만)
additional_models = []
try:
    from models.user_consent import UserConsent
    additional_models.append(UserConsent.__table__)
    logging.info("UserConsent model imported successfully")
except Exception as e:
    logging.warning(f"Failed to import UserConsent model: {e}")

try:
    from models.weekly_summary import WeeklySummaryCache
    additional_models.append(WeeklySummaryCache.__table__)
    logging.info("WeeklySummaryCache model imported successfully")
except Exception as e:
    logging.warning(f"Failed to import WeeklySummaryCache model: {e}")

try:
    from models.shared_report import SharedReport
    additional_models.append(SharedReport.__table__)
    logging.info("SharedReport model imported successfully")
except Exception as e:
    logging.warning(f"Failed to import SharedReport model: {e}")

# 실제로는 garden_item_templates와 garden_items를 사용
# shop_items, user_inventory는 별도 테이블이 아님
logging.info("Shop and inventory use garden_item_templates and garden_items tables")

# 로깅 설정
logging.basicConfig(level=logging.DEBUG)  # DEBUG 레벨로 변경

app = FastAPI()

# CORS 설정 추가
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 중에는 모든 origin 허용
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메서드 허용
    allow_headers=["*"],  # 모든 헤더 허용
)

# 기본 엔드포인트
@app.get("/")
def read_root():
    return {"message": "SimLog API is running!"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "message": "SimLog API is running!"}

# 데이터베이스 초기화 (오류 처리 포함)
try:
    # 데이터베이스 연결 테스트
    with engine.connect() as connection:
        logging.info("Database connection successful")
        
    # 테이블 생성
    Base.metadata.create_all(bind=engine)
    logging.info("Database tables created successfully")
    
except Exception as e:
    logging.error(f"Database initialization failed: {e}")
    logging.error(f"Error type: {type(e)}")
    # 데이터베이스 연결 실패해도 앱은 실행되도록 함

def _initialize_shop_items(connection):
    """상점에 기본 아이템들을 한번에 추가 (add_garden_items.py 기반)"""
    try:
        # 기존 아이템 삭제 (중복 방지)
        connection.execute(text("DELETE FROM garden_item_templates"))
        logging.info("Cleared existing shop items")
        
        # 기본 상점 아이템들 (add_garden_items.py와 동일)
        items = [
            # 배경 아이템들 - 1원으로 설정
            ("background", "잔디 배경", "자연스러운 잔디 배경", "assets/images/garden/backgrounds/Options=🌱 Grass.png", 1, "common", 0),
            ("background", "모래 배경", "따뜻한 모래 배경", "assets/images/garden/backgrounds/Options=🏝️ Sand.png", 1, "common", 0),
            ("background", "흙 배경", "비옥한 흙 배경", "assets/images/garden/backgrounds/Options=🪱 Soil.png", 1, "common", 0),
            
            # 연못 아이템들 - 더 비싸게 설정
            ("water", "연못", "아름다운 연못", "assets/images/garden/pond/pond/Direction=🔄 Center.png", 15, "common", 1),
            
            # 꽃 아이템들 - 노란 꽃, 보라 꽃, 분홍 꽃만 유지, 1원으로 설정
            ("decoration", "노란 꽃", "밝은 노란 꽃", "assets/images/garden/flowers/yellow.png", 1, "common", 2),
            ("decoration", "보라 꽃", "우아한 보라 꽃", "assets/images/garden/flowers/purple.png", 1, "common", 2),
            ("decoration", "분홍 꽃", "사랑스러운 분홍 꽃", "assets/images/garden/flowers/pink.png", 1, "common", 2),
            
            # 부시 아이템들 - 5원으로 설정, 올바른 이미지 경로 사용
            ("bush", "연한 초록 부시", "자연스러운 연한 초록 부시", "assets/images/garden/bushes/bush/light_green/horizontal_regular.png", 5, "common", 2),
            ("bush", "초록 부시", "자연스러운 초록 부시", "assets/images/garden/bushes/bush/green/horizontal_regular.png", 5, "common", 2),
            ("bush", "이끼 초록 부시", "자연스러운 이끼 초록 부시", "assets/images/garden/bushes/bush/moss_green/horizontal_regular.png", 5, "common", 2),
            ("bush", "어두운 이끼 초록 부시", "자연스러운 어두운 이끼 초록 부시", "assets/images/garden/bushes/bush/dark_moss_green/horizontal_regular.png", 5, "common", 2),
            
            # 울타리 아이템들 - 5원으로 설정
            ("decoration", "흰 울타리", "깔끔한 흰 울타리", "assets/images/garden/fence/white/Direction=↔️ Horizontal, Color=White.png", 5, "common", 2),
            ("decoration", "연한 나무 울타리", "자연스러운 연한 나무 울타리", "assets/images/garden/fence/light_wood/Direction=↔️ Horizontal, Color=Light Wood.png", 5, "common", 2),
            
            # 다리 아이템들 - 5원으로 설정
            ("decoration", "나무 다리", "자연스러운 나무 다리", "assets/images/garden/bridge/bridge_horizontal.png", 5, "common", 2),
            
            # 물고기 아이템들 - 5원으로 설정
            ("decoration", "주황 물고기", "귀여운 주황 물고기", "assets/images/garden/fishes/orange.png", 5, "common", 2),
            ("decoration", "빨간 물고기", "아름다운 빨간 물고기", "assets/images/garden/fishes/red.png", 5, "common", 2),
            
            # 채소 아이템들 - 1원으로 설정, 변형 아이템 제거
            ("decoration", "딸기", "달콤한 딸기", "assets/images/garden/veggie/single/Type=Strawberry.png", 1, "common", 2),
            ("decoration", "토마토", "신선한 토마토", "assets/images/garden/veggie/single/Type=Tomato.png", 1, "common", 2),
            ("decoration", "오이", "아삭한 오이", "assets/images/garden/veggie/single/Type=Cucumber.png", 1, "common", 2),
            ("decoration", "마늘", "향긋한 마늘", "assets/images/garden/veggie/single/Type=Garlic.png", 1, "common", 2),
            ("decoration", "양파", "자연스러운 양파", "assets/images/garden/veggie/single/Type=Onion.png", 1, "common", 2),
            ("decoration", "무", "아삭한 무", "assets/images/garden/veggie/single/Type=Radish.png", 1, "common", 2),
            ("decoration", "당근", "달콤한 당근", "assets/images/garden/veggie/single/Type=Carrot.png", 1, "common", 2),
            ("decoration", "체리 토마토", "작고 귀여운 체리 토마토", "assets/images/garden/veggie/single/Type=Cherry Tomatoes.png", 1, "common", 2)
        ]
        
        # 모든 아이템을 한번에 추가
        for item_type, item_name, item_description, item_image, price, rarity, layer in items:
            connection.execute(text("""
                INSERT INTO garden_item_templates 
                (item_type, item_name, item_description, item_image, price, rarity, layer, is_available, created_at)
                VALUES (:item_type, :item_name, :item_description, :item_image, :price, :rarity, :layer, :is_available, NOW())
            """), {
                "item_type": item_type,
                "item_name": item_name,
                "item_description": item_description,
                "item_image": item_image,
                "price": price,
                "rarity": rarity,
                "layer": layer,
                "is_available": True
            })
        
        connection.commit()
        logging.info(f"Successfully added {len(items)} items to shop")
        
    except Exception as e:
        logging.error(f"Failed to initialize shop items: {e}")
        connection.rollback()
        raise  # 오류를 상위로 전파하여 로깅

# 단계 1: 기본 컨트롤러 (이미 성공한 것들)
try:
    from controllers import auth_controller
    app.include_router(auth_controller.router)
    logging.info("Auth controller loaded successfully")
except Exception as e:
    logging.warning(f"Auth controller failed to load: {e}")

try:
    from controllers import user_controller
    app.include_router(user_controller.router)
    logging.info("User controller loaded successfully")
except Exception as e:
    logging.warning(f"User controller failed to load: {e}")

# 단계 2: 핵심 기능 컨트롤러
try:
    from controllers import record_controller
    app.include_router(record_controller.router)
    logging.info("Record controller loaded successfully")
except Exception as e:
    logging.warning(f"Record controller failed to load: {e}")

try:
    from controllers import emotion_controller
    app.include_router(emotion_controller.router)
    logging.info("Emotion controller loaded successfully")
except Exception as e:
    logging.warning(f"Emotion controller failed to load: {e}")

try:
    from controllers import voice_controller
    app.include_router(voice_controller.router)
    logging.info("Voice controller loaded successfully")
except Exception as e:
    logging.warning(f"Voice controller failed to load: {e}")

# 단계 3: 정원 및 부가 기능 컨트롤러
try:
    from controllers import garden_controller
    app.include_router(garden_controller.router)
    logging.info("Garden controller loaded successfully")
except Exception as e:
    logging.warning(f"Garden controller failed to load: {e}")

try:
    from controllers import reports_controller
    app.include_router(reports_controller.router)
    logging.info("Reports controller loaded successfully")
except Exception as e:
    logging.warning(f"Reports controller failed to load: {e}")

try:
    from controllers import alerts_controller
    app.include_router(alerts_controller.router)
    logging.info("Alerts controller loaded successfully")
except Exception as e:
    logging.warning(f"Alerts controller failed to load: {e}")

@app.on_event("startup")
def seed_on_startup():
    """앱 시작 시 상점 초기화 및 개발용 더미 데이터 시드"""
    try:
        # 상점에 기본 아이템들을 한번에 추가
        logging.info("Initializing shop with default items...")
        with engine.connect() as connection:
            _initialize_shop_items(connection)
        logging.info("Shop initialization completed successfully")
    except Exception as e:
        logging.warning(f"Shop initialization failed: {e}")
        # 상점 초기화 실패해도 앱은 계속 실행
    
    # 개발용 더미 데이터 시드 (옵션)
    if os.environ.get("SIMLOG_DEV_SEED_WEEK") == "1":
        try:
            from dev_seed import seed_weekly_cache, seed_weekly_records
            # 기본: user_id=1에 7일 우울 캐시
            user_id = int(os.environ.get("SIMLOG_DEV_SEED_USER", "1"))
            period = int(os.environ.get("SIMLOG_DEV_SEED_PERIOD", "7"))
            seed_weekly_cache(user_id=user_id, period_days=period)
            seed_weekly_records(user_id=user_id, period_days=period)
            logging.info(f"Dev seed weekly cache done for user_id={user_id}, period={period}")
        except Exception as e:
            logging.warning(f"Dev seed failed: {e}")

# Railway 배포를 위한 서버 실행 코드
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
