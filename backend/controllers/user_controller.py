from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from database import get_db
from models.user import User
from services.user_service import get_current_user, update_user, delete_user

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me")
def read_my_info(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "nickname": current_user.nickname,
        "email": current_user.email,
        "social_type": current_user.social_type,
        "is_developer": current_user.is_developer,  # 개발자 여부 추가
        "created_at": current_user.created_at,
    }

@router.put("/me")
def update_my_info(
    nickname: str = Body(None),
    password: str = Body(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user = update_user(db, current_user, nickname=nickname, password=password)
    return {
        "id": user.id,
        "nickname": user.nickname,
        "email": user.email,
        "social_type": user.social_type,
        "is_developer": user.is_developer,  # 개발자 여부 추가
        "created_at": user.created_at,
    }

@router.delete("/me")
def delete_my_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    delete_user(db, current_user)
    return {"detail": "회원 탈퇴가 완료되었습니다."}