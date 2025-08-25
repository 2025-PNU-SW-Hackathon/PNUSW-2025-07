from sqlalchemy.orm import Session
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import jwt, JWTError
from models.user import User
from database import get_db
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import os
import secrets

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SECRET_KEY:
    # 개발용 기본 시크릿 키 생성 (프로덕션에서는 반드시 환경변수 설정 필요)
    SECRET_KEY = secrets.token_urlsafe(32)
    

ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: timedelta = timedelta(hours=1)):
    to_encode = data.copy()
    expire = datetime.utcnow() + expires_delta
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_user(db: Session, email: str, password: str, nickname: str, social_type: str = None, social_id: str = None):
    hashed_pw = get_password_hash(password) if password else None
    user = User(
        email=email,
        password=hashed_pw,
        nickname=nickname,
        social_type=social_type,
        social_id=social_id,
        seeds=200
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def authenticate_user(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user or not user.password or not verify_password(password, user.password):
        return None
    return user

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    return user

# 회원정보 수정
def update_user(db: Session, user: User, nickname: str = None, password: str = None):
    if nickname:
        user.nickname = nickname
    if password:
        user.password = get_password_hash(password)
    db.commit()
    db.refresh(user)
    return user

# 회원 탈퇴
def delete_user(db: Session, user: User):
    db.delete(user)
    db.commit()