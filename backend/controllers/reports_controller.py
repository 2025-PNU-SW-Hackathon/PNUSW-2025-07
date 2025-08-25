from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Dict
from database import get_db
from services.user_service import get_current_user
from models.user import User
from services.report_service import ReportService


router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/consent")
def get_consent(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        consent_info = ReportService.get_consent(db, current_user.id)
        return consent_info
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"동의 상태 조회 실패: {str(e)}")


@router.post("/consent")
def set_consent(
    payload: Dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        consented = bool(payload.get("consented", False))
        result = ReportService.set_consent(db, current_user.id, consented)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"동의 설정 실패: {str(e)}")


@router.post("/weekly/share")
def create_weekly_share(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        created = ReportService.create_weekly_share(db, current_user.id, period_days=7, expires_in_days=7)
        # 프론트에서 앱 도메인을 붙여 URL 구성: /reports/shared/{token}
        return {
            "token": created["token"],
            "share_path": f"/reports/shared/{created['token']}",
            "expires_at": created["expires_at"],
        }
    except ValueError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"공유 링크 생성 실패: {str(e)}")


@router.get("/shared/{token}")
def get_shared_report(token: str, db: Session = Depends(get_db)):
    try:
        snapshot = ReportService.get_shared_report(db, token)
        return snapshot
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"공유 보고서 조회 실패: {str(e)}")


@router.post("/revoke/{token}")
def revoke_shared_report(
    token: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        ok = ReportService.revoke_shared_report(db, current_user.id, token)
        if not ok:
            raise HTTPException(status_code=404, detail="해당 링크를 찾을 수 없습니다.")
        return {"revoked": True}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"공유 링크 취소 실패: {str(e)}")


@router.get("/list")
def list_shares(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        shares = ReportService.list_active_shares(db, current_user.id)
        return {"shares": shares}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"공유 링크 목록 조회 실패: {str(e)}")

