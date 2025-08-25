from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from database import SessionLocal, get_db
from services import user_service

router = APIRouter(prefix="/auth", tags=["auth"])

class UserCreate(BaseModel):
    email: EmailStr | None = None
    password: str | None = None
    nickname: str
    social_type: str | None = None
    social_id: str | None = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

@router.post("/signup", response_model=Token)
def signup(user: UserCreate, db: Session = Depends(get_db)):
    if user.email:
        db_user = db.query(user_service.User).filter(user_service.User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=400, detail="이미 가입된 이메일입니다.")
    db_nick = db.query(user_service.User).filter(user_service.User.nickname == user.nickname).first()
    if db_nick:
        raise HTTPException(status_code=400, detail="이미 사용 중인 닉네임입니다.")
    new_user = user_service.create_user(
        db,
        email=user.email,
        password=user.password,
        nickname=user.nickname,
        social_type=user.social_type,
        social_id=user.social_id
    )
    token = user_service.create_access_token({"sub": str(new_user.id)})
    return {"access_token": token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = user_service.authenticate_user(db, user.email, user.password)
    if not db_user:
        raise HTTPException(status_code=400, detail="이메일 또는 비밀번호가 올바르지 않습니다.")
    token = user_service.create_access_token({"sub": str(db_user.id)})
    return {"access_token": token, "token_type": "bearer"} 