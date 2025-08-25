from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, timedelta
from models.user import User
from models.garden_item import GardenItem, GardenItemTemplate
from typing import List, Dict, Optional

class GardenService:
    
    @staticmethod
    def check_attendance(db: Session, user_id: int) -> Dict:
        """출석 체크 및 씨앗 지급"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("사용자를 찾을 수 없습니다")
        
        today = datetime.now().date()
        last_attendance = user.last_attendance_date.date() if user.last_attendance_date else None
        
        # 이미 오늘 출석했는지 확인
        if last_attendance == today:
            return {
                "message": "오늘 이미 출석했습니다",
                "seeds_earned": 0,
                "current_seeds": user.seeds,
                "attendance_streak": user.attendance_streak
            }
        
        # 연속 출석 체크
        if last_attendance and last_attendance == today - timedelta(days=1):
            user.attendance_streak += 1
        else:
            user.attendance_streak = 1
        
        # 씨앗 지급 (기본 2개 + 연속 출석 보너스)
        base_seeds = 2
        # 2, 4, 6일 연속 출석 시 추가 보너스
        streak_bonus = 0
        if user.attendance_streak == 2:
            streak_bonus = 2
        elif user.attendance_streak == 4:
            streak_bonus = 4
        elif user.attendance_streak == 6:
            streak_bonus = 6
        elif user.attendance_streak >= 7:
            streak_bonus = 8  # 7일 이상 연속 출석 시 최대 보너스
        
        weekly_bonus = 5 if user.attendance_streak % 7 == 0 else 0  # 7일마다 특별 보너스
        seeds_earned = base_seeds + streak_bonus + weekly_bonus
        
        user.seeds += seeds_earned
        user.last_attendance_date = datetime.now()
        
        db.commit()
        
        return {
            "message": f"출석 완료! {seeds_earned}개의 씨앗을 받았습니다",
            "seeds_earned": seeds_earned,
            "current_seeds": user.seeds,
            "attendance_streak": user.attendance_streak
        }
    
    @staticmethod
    def get_user_garden_info(db: Session, user_id: int) -> Dict:
        """사용자의 정원 정보 조회"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("사용자를 찾을 수 없습니다")
        
        # 사용자의 정원 아이템들 조회
        garden_items = db.query(GardenItem).filter(
            and_(GardenItem.user_id == user_id, GardenItem.is_equipped == True)
        ).all()
        
        return {
            "seeds": user.seeds,
            "attendance_streak": user.attendance_streak,
            "last_attendance_date": user.last_attendance_date,
            "garden_items": [
                {
                    "id": item.id,
                    "item_type": item.item_type,
                    "item_name": item.item_name,
                    "item_image": item.item_image,
                    "position_x": item.position_x,
                    "position_y": item.position_y,
                    "layer": item.layer
                }
                for item in garden_items
            ]
        }
    
    @staticmethod
    def get_shop_items(db: Session) -> List[Dict]:
        """상점에서 구매 가능한 아이템 목록 조회"""
        items = db.query(GardenItemTemplate).filter(
            GardenItemTemplate.is_available == True
        ).all()
        
        return [
            {
                "id": item.id,
                "item_type": item.item_type,
                "item_name": item.item_name,
                "item_description": item.item_description,
                "item_image": item.item_image,
                "price": item.price,
                "rarity": item.rarity
            }
            for item in items
        ]
    
    @staticmethod
    def purchase_item(db: Session, user_id: int, template_id: int, quantity: int = 1) -> Dict:
        """아이템 구매 (수량 지정 가능)"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("사용자를 찾을 수 없습니다")
        
        template = db.query(GardenItemTemplate).filter(
            GardenItemTemplate.id == template_id
        ).first()
        if not template:
            raise ValueError("아이템을 찾을 수 없습니다")
        
        if not template.is_available:
            raise ValueError("구매할 수 없는 아이템입니다")
        
        total_cost = template.price * quantity
        if user.seeds < total_cost:
            raise ValueError("씨앗이 부족합니다")
        
        # 아이템 구매 (수량만큼)
        purchased_items = []
        for _ in range(quantity):
            new_item = GardenItem(
                user_id=user_id,
                item_type=template.item_type,
                item_name=template.item_name,
                item_image=template.item_image
            )
            db.add(new_item)
            purchased_items.append(new_item)
        
        user.seeds -= total_cost
        db.commit()
        
        return {
            "message": f"{template.item_name} {quantity}개를 구매했습니다",
            "remaining_seeds": user.seeds,
            "purchased_items": [
                {
                    "id": item.id,
                    "item_type": item.item_type,
                    "item_name": item.item_name,
                    "item_image": item.item_image
                }
                for item in purchased_items
            ]
        }
    
    @staticmethod
    def equip_item(db: Session, user_id: int, item_id: int, position_x: int, position_y: int, variant: str = None) -> Dict:
        """아이템을 정원에 배치 (변형 선택 가능)"""
        item = db.query(GardenItem).filter(
            and_(GardenItem.id == item_id, GardenItem.user_id == user_id)
        ).first()
        
        if not item:
            raise ValueError("아이템을 찾을 수 없습니다")
        
        # 변형에 따른 이미지 경로 업데이트
        if variant:
            item_name = item.item_name
            
            if "연꽃" in item_name:
                # 연꽃 변형
                color_map = {
                    'light_green': 'light_green.png',
                    'green': 'green.png',
                    'moss_green': 'moss_green.png',
                    'dark_moss_green': 'dark_moss_green.png',
                }
                new_image = f"assets/images/garden/lotus/{color_map.get(variant, 'light_green.png')}"
                item.item_image = new_image
            elif "꽃" in item_name:
                # 꽃 변형
                color_map = {
                    '노란': 'yellow',
                    '파란': 'blue',
                    '보라': 'purple',
                    '분홍': 'pink',
                    '흰': 'white',
                    '복숭아': 'peach',
                }
                color = 'yellow'  # 기본값
                for color_name, color_code in color_map.items():
                    if color_name in item_name:
                        color = color_code
                        break
                
                size_map = {
                    'small_paddles': 'small_paddles',
                    'big_paddles': 'big_paddles',
                }
                size = size_map.get(variant, 'small_paddles')
                new_image = f"assets/images/garden/flowers/big_paddle/{color}_{size}.png"
                item.item_image = new_image
            elif "부시" in item_name:
                # 부시 변형
                # 부시 색상 매핑 - 더 정확한 매칭을 위해 조건부 처리
                if '연한 초록' in item_name:
                    color = 'light_green'
                elif '초록' in item_name and '이끼' not in item_name:
                    color = 'green'
                elif '이끼 초록' in item_name and '어두운' not in item_name:
                    color = 'moss_green'
                elif '어두운 이끼' in item_name:
                    color = 'dark_moss_green'
                else:
                    color = 'light_green'  # 기본값
                
                # 방향별 이미지 매핑 - 실제 파일명과 일치하도록 수정
                direction_map = {
                    'horizontal': 'horizontal_regular.png',
                    'vertical': 'vertical_regular.png',
                    'left': 'left_regular.png',
                    'right': 'right_regular.png',
                    'top': 'top_regular.png',
                    'bottom': 'bottom_regular.png',
                    'top_left': 'top_left_regular.png',
                    'top_right': 'top_right_regular.png',
                    'bottom_left': 'bottom_left_regular.png',
                    'bottom_right': 'bottom_right_regular.png',
                }
                
                direction_file = direction_map.get(variant, 'horizontal_regular.png')
                new_image = f"assets/images/garden/bushes/bush/{color}/{direction_file}"
                item.item_image = new_image
            elif "울타리" in item_name:
                # 울타리 변형
                color_map = {
                    '흰색': 'white',
                    '연한 나무': 'light_wood',
                }
                color = 'light_wood'  # 기본값
                for color_name, color_code in color_map.items():
                    if color_name in item_name:
                        color = color_code
                        break
                
                # 방향별 이미지 매핑
                color_name = 'White' if color == 'white' else 'Light Wood'
                
                if variant == 'horizontal':
                    new_image = f"assets/images/garden/fence/{color}/Direction=↔️ Horizontal, Color={color_name}.png"
                elif variant == 'vertical':
                    new_image = f"assets/images/garden/fence/{color}/Direction=↕️ Vertical, Color={color_name}.png"
                elif variant == 'left':
                    new_image = f"assets/images/garden/fence/{color}/Direction=⬅️ Left, Color={color_name}.png"
                elif variant == 'right':
                    new_image = f"assets/images/garden/fence/{color}/Direction=➡️ Right, Color={color_name}.png"
                elif variant == 'top':
                    new_image = f"assets/images/garden/fence/{color}/Direction=⬆️ Top, Color={color_name}.png"
                elif variant == 'bottom':
                    new_image = f"assets/images/garden/fence/{color}/Direction=⬇️ Bottom, Color={color_name}.png"
                elif variant == 'top_left':
                    new_image = f"assets/images/garden/fence/{color}/Direction=↖️Top Left, Color={color_name}.png"
                elif variant == 'top_right':
                    new_image = f"assets/images/garden/fence/{color}/Direction=↗️ Top Right, Color={color_name}.png"
                elif variant == 'bottom_left':
                    new_image = f"assets/images/garden/fence/{color}/Direction=↙️ Bottom Left, Color={color_name}.png"
                elif variant == 'bottom_right':
                    new_image = f"assets/images/garden/fence/{color}/Direction=↘️ Bottom Right, Color={color_name}.png"
                else:
                    # 기본값
                    new_image = f"assets/images/garden/fence/{color}/Direction=↔️ Horizontal, Color={color_name}.png"
                
                item.item_image = new_image
            elif "나무 다리" in item_name:
                # 나무 다리 변형

                if variant == 'horizontal':
                    new_image = "assets/images/garden/bridge/bridge_horizontal.png"
                elif variant == 'vertical':
                    new_image = "assets/images/garden/bridge/bridge_vertical.png"
                elif variant == 'left':
                    new_image = "assets/images/garden/bridge/bridge_left.png"
                elif variant == 'right':
                    new_image = "assets/images/garden/bridge/bridge_right.png"
                elif variant == 'top':
                    new_image = "assets/images/garden/bridge/bridge_top.png"
                elif variant == 'bottom':
                    new_image = "assets/images/garden/bridge/bridge_bottom.png"
                elif variant == 'left_short':
                    new_image = "assets/images/garden/bridge/bridge_left_short.png"
                elif variant == 'right_short':
                    new_image = "assets/images/garden/bridge/bridge_right_short.png"
                elif variant == 'top_short':
                    new_image = "assets/images/garden/bridge/bridge_top_short.png"
                elif variant == 'bottom_short':
                    new_image = "assets/images/garden/bridge/bridge_bottom_short.png"
                else:
                    # 기본값
                    new_image = "assets/images/garden/bridge/bridge_horizontal.png"
                
                item.item_image = new_image

            elif "연못" in item_name and "테두리" not in item_name:
                # 연못 변형

                if variant == 'center':
                    new_image = "assets/images/garden/pond/pond/Direction=🔄 Center.png"
                elif variant == 'top_left':
                    new_image = "assets/images/garden/pond/pond/Direction=↖️ Top Left.png"
                elif variant == 'top_right':
                    new_image = "assets/images/garden/pond/pond/Direction=↗️ Top Right.png"
                elif variant == 'bottom_left':
                    new_image = "assets/images/garden/pond/pond/Direction=↙️ Bottom Left.png"
                elif variant == 'bottom_right':
                    new_image = "assets/images/garden/pond/pond/Direction=↘️ Bottom Right.png"
                elif variant == 'left':
                    new_image = "assets/images/garden/pond/pond/Direction=⬅️ Left.png"
                elif variant == 'right':
                    new_image = "assets/images/garden/pond/pond/Direction=➡️ Right.png"
                elif variant == 'top':
                    new_image = "assets/images/garden/pond/pond/Direction=⬆️ Top.png"
                elif variant == 'bottom':
                    new_image = "assets/images/garden/pond/pond/Direction=⬇️ Bottom.png"
                else:
                    # 기본값
                    new_image = "assets/images/garden/pond/pond/Direction=🔄 Center.png"
                
                item.item_image = new_image

            elif "연꽃" in item_name:
                # 연꽃 변형
                color_map = {
                    'light_green': 'light_green.png',
                    'green': 'green.png',
                    'moss_green': 'moss_green.png',
                    'dark_moss_green': 'dark_moss_green.png',
                }
                new_image = f"assets/images/garden/lotus/{color_map.get(variant, 'light_green.png')}"
                item.item_image = new_image
            elif "꽃봉오리" in item_name:
                # Bloom 변형
                color_map = {
                    '노란': 'Yellow',
                    '보라': 'Purple',
                    '분홍': 'Pink',
                    '복숭아': 'Peach',
                }
                color = 'Yellow'  # 기본값
                for color_name, color_code in color_map.items():
                    if color_name in item_name:
                        color = color_code
                        break
                
                size_map = {
                    'bud': 'Bud',
                    'big_bud': 'Big Bud',
                    'flower': 'Flower',
                }
                size = size_map.get(variant, 'Bud')
                new_image = f"assets/images/garden/bloom/color/Size={size}, Color={color}.png"
                item.item_image = new_image
            elif "연못 테두리" in item_name:
                # 연못 테두리 변형
                color_map = {
                    '초록': 'green',
                    '연한 초록': 'light_green',
                    '회색': 'grey',
                    '어두운 회색': 'dark_grey',
                }
                color = 'green'  # 기본값
                for color_name, color_code in color_map.items():
                    if color_name in item_name:
                        color = color_code
                        break
                
                direction_map = {
                    'left': '⬅️ Left',
                    'right': '➡️ Right',
                    'top': '⬆️ Top',
                    'bottom': '⬇️ Bottom',
                    'top_left': '↖️Top Left',
                    'top_right': '↗️ Top Right',
                    'bottom_left': '↙️ Bottom Left',
                    'bottom_right': '↘️ Bottom Right',
                }
                
                direction = direction_map.get(variant, '⬅️ Left')
                color_name = 'Green' if color == 'green' else 'Light Green' if color == 'light_green' else 'Grey' if color == 'grey' else 'Dark Grey'
                new_image = f"assets/images/garden/pond/pond_borders/{color}/Border Option=🌳 Bush, Color={color_name}, Direction={direction}.png"
                item.item_image = new_image
            elif any(veggie in item_name for veggie in ['토마토', '딸기', '당근', '양파', '마늘', '오이', '체리 토마토', '무']):
                # 채소 변형
                veggie_map = {
                    '토마토': 'Tomato',
                    '딸기': 'Strawberry',
                    '당근': 'Carrot',
                    '양파': 'Onion',
                    '마늘': 'Garlic',
                    '오이': 'Cucumber',
                    '체리 토마토': 'Cherry Tomatoes',
                    '무': 'Radish',
                }
                
                veggie_type = 'Tomato'  # 기본값
                for veggie_name, veggie_code in veggie_map.items():
                    if veggie_name in item_name:
                        veggie_type = veggie_code
                        break
                
                if variant == 'single':
                    new_image = f"assets/images/garden/veggie/single/Type={veggie_type}.png"
                elif variant == 'paddle':
                    new_image = f"assets/images/garden/veggie/veggie_option/Type={veggie_type}s.png"
                else:
                    new_image = f"assets/images/garden/veggie/single/Type={veggie_type}.png"
                
                item.item_image = new_image
            elif "돌담" in item_name or "벽돌" in item_name:
                # 돌담/벽돌 변형 - 현재는 기본 이미지만 사용 (실제 파일이 없음)
                pass
            else:
                pass
        else:
            pass
        
        # 레이어 설정
        new_layer = GardenService._get_item_layer(item.item_name)
        item.layer = new_layer
        
        item.is_equipped = True
        item.position_x = position_x
        item.position_y = position_y
        
        db.commit()
        db.refresh(item) # Ensure the item object reflects the committed state
        
        return {
            "message": f"{item.item_name}을 정원에 배치했습니다",
            "item": {
                "id": item.id,
                "item_type": item.item_type,
                "item_name": item.item_name,
                "item_image": item.item_image,
                "position_x": item.position_x,
                "position_y": item.position_y,
                "layer": item.layer
            }
        }
    
    @staticmethod
    def _get_item_layer(item_name: str) -> int:
        """아이템 이름을 기반으로 레이어를 결정"""
        # 배경 아이템들 (레이어 0)
        background_items = ['잔디', '모래', '흙']
        for bg_item in background_items:
            if bg_item in item_name:
                return 0
        
        # 물 관련 아이템들 (레이어 1)
        water_items = ['연못', '물', '시냇물', '분수']
        for water_item in water_items:
            if water_item in item_name:
                return 1

        # 돌담/벽돌 류는 "중간(1)"으로 고정
        mid_decors = ['돌담', '벽돌', '원형 벽돌']
        for mid in mid_decors:
            if mid in item_name:
                return 1
        
        # 장식 아이템들: 기본적으로 연못(1) 위에서 보여야 하는 경우가 많음
        # 울타리, 다리 등은 레이어 2로 분류 (돌담/벽돌 류는 위에서 1로 처리)
        decoration_items_front = ['울타리', '다리', '벤치', '등불', '문']
        for dec_item in decoration_items_front:
            if dec_item in item_name:
                return 2

        # 연못 테두리는 물의 일부로 간주하여 레이어 1 유지
        if '연못 테두리' in item_name:
            return 1
        
        # 식물 아이템들 (레이어 2) - 연못 위에 배치 가능
        plant_items = ['꽃', '나무', '부시', '채소', '연꽃', '토마토', '딸기', '당근', '양파', '마늘', '오이', '무']
        for plant_item in plant_items:
            if plant_item in item_name:
                return 2
        
        # 동물 아이템들 (레이어 3) - 물고기를 가장 앞으로 이동
        # 물고기는 '물고기'가 포함된 모든 아이템 (빨간 물고기, 주황 물고기 등)
        if '물고기' in item_name:
            return 3
        
        animal_items = ['새', '나비', '벌', '주황 물고기', '빨간 물고기']
        for animal_item in animal_items:
            if animal_item in item_name:
                return 3
        
        # 기본값은 레이어 2
        return 2

    @staticmethod
    def unequip_item(db: Session, user_id: int, item_id: int) -> Dict:
        """아이템을 정원에서 제거"""
        item = db.query(GardenItem).filter(
            and_(GardenItem.id == item_id, GardenItem.user_id == user_id)
        ).first()
        
        if not item:
            raise ValueError("아이템을 찾을 수 없습니다")
        
        item.is_equipped = False
        item.position_x = 0
        item.position_y = 0
        
        db.commit()
        
        return {
            "message": f"{item.item_name}을 정원에서 제거했습니다"
        }
    
    @staticmethod
    def get_user_inventory(db: Session, user_id: int) -> List[Dict]:
        """사용자의 인벤토리 조회"""
        items = db.query(GardenItem).filter(GardenItem.user_id == user_id).all()
        
        return [
            {
                "id": item.id,
                "item_type": item.item_type,
                "item_name": item.item_name,
                "item_image": item.item_image,
                "is_equipped": item.is_equipped,
                "layer": item.layer,
                "position_x": item.position_x,
                "position_y": item.position_y
            }
            for item in items
        ]

    @staticmethod
    def sell_item(db: Session, user_id: int, item_id: int, quantity: int = 1) -> Dict:
        """아이템 판매"""
        try:
            # 사용자 조회
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise Exception("사용자를 찾을 수 없습니다")
            
            # 아이템 조회
            item = db.query(GardenItem).filter(
                GardenItem.id == item_id,
                GardenItem.user_id == user_id
            ).first()
            
            if not item:
                raise Exception("판매할 아이템을 찾을 수 없습니다")
            
            # 배치된 아이템은 판매 불가
            if item.is_equipped:
                raise Exception("배치된 아이템은 판매할 수 없습니다. 먼저 제거해주세요")
            
            # 판매 가격 계산 (기본 5씨앗)
            sell_price = 5 * quantity
            
            # 사용자 씨앗 증가
            user.seeds += sell_price
            
            # 아이템 삭제
            db.delete(item)
            db.commit()
            
            return {
                "success": True,
                "message": f"아이템을 {sell_price}씨앗에 판매했습니다",
                "seeds_earned": sell_price,
                "remaining_seeds": user.seeds
            }
            
        except Exception as e:
            db.rollback()
            raise Exception(f"아이템 판매 중 오류가 발생했습니다: {str(e)}") 