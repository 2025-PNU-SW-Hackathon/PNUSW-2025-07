#!/usr/bin/env python3
"""
마음 정원 아이템 추가 스크립트
실제 이미지 파일들을 기반으로 아이템들을 추가합니다.
"""

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

# .env 파일 로드
load_dotenv()

# 데이터베이스 연결 설정
# Railway MySQL 환경변수 사용
DB_USER = os.getenv("MYSQL_USER", "simlog_user")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "simlog_password")
DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_NAME = os.getenv("MYSQL_DATABASE", "railway")

# Railway 환경변수 우선 사용
if os.getenv("RAILWAY_ENVIRONMENT"):
    DB_USER = os.getenv("MYSQL_USER", "simlog_user")
    DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "simlog_password")
    DB_HOST = os.getenv("MYSQL_HOST", "localhost")
    DB_NAME = os.getenv("MYSQL_DATABASE", "railway")

DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:3306/{DB_NAME}?charset=utf8mb4"

def connect_to_database():
    try:
        engine = create_engine(DATABASE_URL, echo=False)
        connection = engine.connect()
        print("MySQL 데이터베이스에 성공적으로 연결되었습니다.")
        return connection
    except OperationalError as e:
        print(f"데이터베이스 연결 오류: {e}")
        return None

def clear_garden_templates(connection):
    """기존 정원 아이템 템플릿 삭제"""
    try:
        connection.execute(text("DELETE FROM garden_item_templates"))
        connection.commit()
        print("기존 정원 아이템 템플릿이 삭제되었습니다.")
    except Exception as e:
        print(f"템플릿 삭제 오류: {e}")

def add_garden_items(connection):
    """정원 아이템 추가"""
    try:
        # 배경 아이템들 - 1원으로 설정
        background_items = [
            ("background", "잔디 배경", "자연스러운 잔디 배경", "assets/images/garden/backgrounds/Options=🌱 Grass.png", 1, "common", 0),
            ("background", "모래 배경", "따뜻한 모래 배경", "assets/images/garden/backgrounds/Options=🏝️ Sand.png", 1, "common", 0),
            ("background", "흙 배경", "비옥한 흙 배경", "assets/images/garden/backgrounds/Options=🪱 Soil.png", 1, "common", 0)
        ]
        
        # 연못 아이템들 - 더 비싸게 설정
        pond_items = [
            ("water", "연못", "아름다운 연못", "assets/images/garden/pond/pond/Direction=🔄 Center.png", 15, "common", 1)
        ]
        
        # 꽃 아이템들 - 노란 꽃, 보라 꽃, 분홍 꽃만 유지, 1원으로 설정
        flower_items = [
            ("decoration", "노란 꽃", "밝은 노란 꽃", "assets/images/garden/flowers/yellow.png", 1, "common", 2),
            ("decoration", "보라 꽃", "우아한 보라 꽃", "assets/images/garden/flowers/purple.png", 1, "common", 2),
            ("decoration", "분홍 꽃", "사랑스러운 분홍 꽃", "assets/images/garden/flowers/pink.png", 1, "common", 2)
        ]
        
        # 부시 아이템들 - 5원으로 설정, 올바른 이미지 경로 사용
        bush_items = [
            ("bush", "연한 초록 부시", "자연스러운 연한 초록 부시", "assets/images/garden/bushes/bush/light_green/horizontal_regular.png", 5, "common", 2),
            ("bush", "초록 부시", "자연스러운 초록 부시", "assets/images/garden/bushes/bush/green/horizontal_regular.png", 5, "common", 2),
            ("bush", "이끼 초록 부시", "자연스러운 이끼 초록 부시", "assets/images/garden/bushes/bush/moss_green/horizontal_regular.png", 5, "common", 2),
            ("bush", "어두운 이끼 초록 부시", "자연스러운 어두운 이끼 초록 부시", "assets/images/garden/bushes/bush/dark_moss_green/horizontal_regular.png", 5, "common", 2)
        ]
        
        # 울타리 아이템들 - 5원으로 설정
        fence_items = [
            ("decoration", "흰 울타리", "깔끔한 흰 울타리", "assets/images/garden/fence/white/Direction=↔️ Horizontal, Color=White.png", 5, "common", 2),
            ("decoration", "연한 나무 울타리", "자연스러운 연한 나무 울타리", "assets/images/garden/fence/light_wood/Direction=↔️ Horizontal, Color=Light Wood.png", 5, "common", 2)
        ]
        
        # 다리 아이템들 - 5원으로 설정
        bridge_items = [
            ("decoration", "나무 다리", "자연스러운 나무 다리", "assets/images/garden/bridge/bridge_horizontal.png", 5, "common", 2)
        ]
        
        # 물고기 아이템들 - 5원으로 설정
        fish_items = [
            ("decoration", "주황 물고기", "귀여운 주황 물고기", "assets/images/garden/fishes/orange.png", 5, "common", 2),
            ("decoration", "빨간 물고기", "아름다운 빨간 물고기", "assets/images/garden/fishes/red.png", 5, "common", 2)
        ]
        
        # 채소 아이템들 - 1원으로 설정, 변형 아이템 제거
        veggie_items = [
            ("decoration", "딸기", "달콤한 딸기", "assets/images/garden/veggie/single/Type=Strawberry.png", 1, "common", 2),
            ("decoration", "토마토", "신선한 토마토", "assets/images/garden/veggie/single/Type=Tomato.png", 1, "common", 2),
            ("decoration", "오이", "아삭한 오이", "assets/images/garden/veggie/single/Type=Cucumber.png", 1, "common", 2),
            ("decoration", "마늘", "향긋한 마늘", "assets/images/garden/veggie/single/Type=Garlic.png", 1, "common", 2),
            ("decoration", "양파", "자연스러운 양파", "assets/images/garden/veggie/single/Type=Onion.png", 1, "common", 2),
            ("decoration", "무", "아삭한 무", "assets/images/garden/veggie/single/Type=Radish.png", 1, "common", 2),
            ("decoration", "당근", "달콤한 당근", "assets/images/garden/veggie/single/Type=Carrot.png", 1, "common", 2),
            ("decoration", "체리 토마토", "작고 귀여운 체리 토마토", "assets/images/garden/veggie/single/Type=Cherry Tomatoes.png", 1, "common", 2)
        ]
        
        # 모든 아이템을 하나의 리스트로 합치기
        all_items = (background_items + pond_items + flower_items + bush_items + 
                    fence_items + bridge_items + fish_items + veggie_items)
        
        # 아이템 추가
        for item in all_items:
            connection.execute(text("""
                INSERT INTO garden_item_templates
                (item_type, item_name, item_description, item_image, price, rarity, layer)
                VALUES (:item_type, :item_name, :item_description, :item_image, :price, :rarity, :layer)
            """), {
                "item_type": item[0],
                "item_name": item[1],
                "item_description": item[2],
                "item_image": item[3],
                "price": item[4],
                "rarity": item[5],
                "layer": item[6]
            })
        
        connection.commit()
        print(f"총 {len(all_items)}개의 아이템이 성공적으로 추가되었습니다.")
        
        # 카테고리별 아이템 수 출력
        print(f"\n카테고리별 아이템 수:")
        print(f"- 배경: {len(background_items)}개")
        print(f"- 연못: {len(pond_items)}개")
        print(f"- 꽃: {len(flower_items)}개")
        print(f"- 덤불: {len(bush_items)}개")
        print(f"- 울타리: {len(fence_items)}개")
        print(f"- 다리: {len(bridge_items)}개")
        print(f"- 물고기: {len(fish_items)}개")
        print(f"- 채소: {len(veggie_items)}개")
        
    except Exception as e:
        print(f"아이템 추가 오류: {e}")

def main():
    connection = connect_to_database()
    if connection:
        try:
            clear_garden_templates(connection)
            add_garden_items(connection)
        finally:
            connection.close()
            print("데이터베이스 연결이 종료되었습니다.")

if __name__ == "__main__":
    main()
