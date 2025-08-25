import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# .env 파일 로드
load_dotenv()

# 데이터베이스 연결 설정
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "1234")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "simlog")

DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:3306/{DB_NAME}?charset=utf8mb4"

def check_items():
    try:
        engine = create_engine(DATABASE_URL, echo=False)
        with engine.connect() as connection:
            print("✅ 데이터베이스 연결 성공")
            
            # 전체 아이템 수 확인
            result = connection.execute(text("SELECT COUNT(*) FROM garden_item_templates"))
            total_count = result.fetchone()[0]
            print(f"📊 총 아이템 수: {total_count}개")
            
            # 카테고리별 아이템 수 확인
            result = connection.execute(text("SELECT item_type, COUNT(*) as count FROM garden_item_templates GROUP BY item_type ORDER BY item_type"))
            print("\n📋 카테고리별 아이템 수:")
            for row in result:
                print(f"   {row[0]}: {row[1]}개")
            
            # 방향성 아이템들이 통합되었는지 확인
            print("\n🔍 방향성 아이템 통합 확인:")
            
            # 연못 아이템 확인
            result = connection.execute(text("SELECT item_name FROM garden_item_templates WHERE item_name LIKE '%연못%'"))
            pond_items = [row[0] for row in result]
            print(f"   연못 아이템: {pond_items}")
            
            # 울타리 아이템 확인
            result = connection.execute(text("SELECT item_name FROM garden_item_templates WHERE item_name LIKE '%울타리%'"))
            fence_items = [row[0] for row in result]
            print(f"   울타리 아이템: {fence_items}")
            
            # 다리 아이템 확인
            result = connection.execute(text("SELECT item_name FROM garden_item_templates WHERE item_name LIKE '%다리%'"))
            bridge_items = [row[0] for row in result]
            print(f"   다리 아이템: {bridge_items}")
            
            # 새로운 아이템들 확인
            print("\n🐟 새로운 아이템 확인:")
            
            # 물고기 아이템 확인
            result = connection.execute(text("SELECT item_name FROM garden_item_templates WHERE item_name LIKE '%물고기%'"))
            fish_items = [row[0] for row in result]
            print(f"   물고기 아이템: {fish_items}")
            
            # 채소 아이템 확인
            result = connection.execute(text("SELECT item_name FROM garden_item_templates WHERE item_name LIKE '%딸기%' OR item_name LIKE '%토마토%' OR item_name LIKE '%오이%' OR item_name LIKE '%마늘%' OR item_name LIKE '%양파%' OR item_name LIKE '%무%' OR item_name LIKE '%당근%'"))
            veggie_items = [row[0] for row in result]
            print(f"   채소 아이템: {veggie_items}")
            
    except Exception as e:
        print(f"❌ 오류 발생: {e}")

if __name__ == "__main__":
    check_items()
