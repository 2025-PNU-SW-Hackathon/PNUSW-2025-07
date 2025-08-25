from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from services.garden_service import GardenService
from services.user_service import get_current_user
from models.user import User
from typing import List, Dict

router = APIRouter(prefix="/garden", tags=["garden"])

@router.post("/attendance")
async def check_attendance(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """출석 체크 및 씨앗 지급"""
    try:
        result = GardenService.check_attendance(db, current_user.id)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.get("/info")
async def get_garden_info(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """사용자의 정원 정보 조회"""
    try:
        result = GardenService.get_user_garden_info(db, current_user.id)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.get("/shop")
async def get_shop_items(db: Session = Depends(get_db)):
    """상점 아이템 목록 조회"""
    try:
        items = GardenService.get_shop_items(db)
        return {"items": items}
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.post("/purchase/{template_id}")
async def purchase_item(
    template_id: int,
    quantity: int = 1,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """아이템 구매 (수량 지정 가능)"""
    try:
        result = GardenService.purchase_item(db, current_user.id, template_id, quantity)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.post("/equip/{item_id}")
async def equip_item(
    item_id: int,
    position_x: int,
    position_y: int,
    variant: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """아이템을 정원에 배치 (변형 선택 가능)"""
    try:
        result = GardenService.equip_item(db, current_user.id, item_id, position_x, position_y, variant)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.post("/unequip/{item_id}")
async def unequip_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """아이템을 정원에서 제거"""
    try:
        result = GardenService.unequip_item(db, current_user.id, item_id)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.get("/inventory")
async def get_inventory(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """사용자의 인벤토리 조회"""
    try:
        items = GardenService.get_user_inventory(db, current_user.id)
        return {"items": items}
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다")

@router.post("/sell/{item_id}")
async def sell_item(
    item_id: int,
    quantity: int = 1,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """아이템 판매"""
    try:
        result = GardenService.sell_item(db, current_user.id, item_id, quantity)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다") 