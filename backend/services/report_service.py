from sqlalchemy.orm import Session
from typing import Optional, Dict, List
from datetime import datetime, timedelta, timezone
import secrets
import hashlib

from models.weekly_summary import WeeklySummaryCache
from models.shared_report import SharedReport
from models.user_consent import UserConsent


class ReportService:
    @staticmethod
    def _to_aware_utc(dt: datetime) -> datetime:
        if dt is None:
            return datetime.now(timezone.utc)
        if dt.tzinfo is None:
            # DB에서 naive로 돌아온 경우 UTC 기준으로 간주
            return dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    @staticmethod
    def _generate_token() -> str:
        return secrets.token_urlsafe(32)

    @staticmethod
    def _digest_token(token: str) -> str:
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    @staticmethod
    def get_consent(db: Session, user_id: int) -> Dict:
        """사용자의 동의 상태와 상세 정보를 반환"""
        consent = db.query(UserConsent).filter(UserConsent.user_id == user_id).first()
        
        if not consent:
            return {
                "consented": False,
                "has_record": True,
                "message": "동의하셔야 합니다",
                "action_required": "consent"
            }
        
        if not consent.consented:
            return {
                "consented": False,
                "has_record": True,
                "message": "동의하셔야 합니다",
                "action_required": "consent",
                "revoked_at": consent.revoked_at
            }
        
        return {
            "consented": True,
            "has_record": True,
            "message": "이미 동의하셨습니다",
            "action_required": "none",
            "consented_at": consent.consented_at
        }

    @staticmethod
    def set_consent(db: Session, user_id: int, consented: bool) -> Dict:
        consent = db.query(UserConsent).filter(UserConsent.user_id == user_id).first()
        now = datetime.now(timezone.utc)
        if not consent:
            consent = UserConsent(user_id=user_id)
            db.add(consent)
        consent.consented = consented
        if consented:
            consent.consented_at = now
            consent.revoked_at = None
        else:
            consent.revoked_at = now
        db.commit()
        db.refresh(consent)
        return {
            "user_id": user_id,
            "consented": consent.consented,
            "consented_at": consent.consented_at,
            "revoked_at": consent.revoked_at,
        }

    @staticmethod
    def create_weekly_share(db: Session, user_id: int, period_days: int = 7, expires_in_days: int = 7) -> Dict:
        # 동의 확인
        consent_info = ReportService.get_consent(db, user_id)
        if not consent_info["consented"]:
            raise ValueError("사용자가 공유에 동의하지 않았습니다.")

        cache: Optional[WeeklySummaryCache] = db.query(WeeklySummaryCache).filter(
            WeeklySummaryCache.user_id == user_id,
            WeeklySummaryCache.period_days == period_days
        ).first()

        # 1) 캐시에 데이터가 있으면 그대로 사용
        if cache and cache.items:
            items = cache.items
            one_line_summary = cache.one_line_summary or ""
            negative_ratio = cache.negative_ratio or 0.0
        else:
            # 2) 캐시가 없거나 비어 있으면 최근 period_days 내 기록으로 즉석 요약 생성
            from models.record import Record

            end_dt = datetime.now()
            start_dt = end_dt - timedelta(days=period_days)

            records = (
                db.query(Record)
                .filter(
                    Record.user_id == user_id,
                    Record.created_at >= start_dt,
                    Record.created_at <= end_dt,
                )
                .order_by(Record.created_at.asc())
                .all()
            )

            if not records:
                # 최근 기간 내 일기가 0개면 공유 불가
                raise ValueError("최근 7일 일기가 없습니다.")

            # 기록이 1개 이상이면 해당 범위 내에서 요약 생성
            items = []
            summaries: List[str] = []
            neg = {"우울", "슬픔", "분노", "혐오", "두려움", "불안", "짜증", "화남"}
            neg_count = 0

            for r in records[-period_days:]:
                # 날짜
                date_str = r.created_at.date().isoformat() if r.created_at else None
                # 요약
                summary = (r.ai_summary or "").strip()
                if summary:
                    summaries.append(summary)
                # 주감정
                primary_emotion = ""
                try:
                    if r.emotion_analysis:
                        primary_emotion = r.emotion_analysis.get("primary_emotion", "")
                except Exception:
                    primary_emotion = ""

                if primary_emotion in neg:
                    neg_count += 1

                items.append({
                    "date": date_str,
                    "summary": summary,
                    "primary_emotion": primary_emotion,
                })

            total = len(items)
            negative_ratio = round(neg_count / total, 3) if total > 0 else 0.0
            one_line_summary = " ".join(s for s in summaries[-3:] if s)[:200]

        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(days=expires_in_days)
        # MySQL은 timezone-aware datetime을 직접 저장하지 못할 수 있으므로 naive UTC로 변환
        expires_at_naive = expires_at.astimezone(timezone.utc).replace(tzinfo=None)

        snapshot = {
            "period": period_days,
            "items": items,
            "one_line_summary": one_line_summary,
            "negative_ratio": negative_ratio,
            "generated_at": now.astimezone(timezone.utc).replace(tzinfo=None).isoformat(),
        }

        token = ReportService._generate_token()
        token_digest = ReportService._digest_token(token)

        share = SharedReport(
            user_id=user_id,
            token_digest=token_digest,
            snapshot=snapshot,
            expires_at=expires_at_naive,
            revoked=False,
        )
        db.add(share)
        try:
            db.commit()
            db.refresh(share)
        except Exception as e:
            db.rollback()
            raise ValueError(f"공유 링크 저장 실패: {str(e)}")

        return {
            "token": token,
            "expires_at": expires_at,  # 응답은 timezone-aware ISO로 반환
        }

    @staticmethod
    def get_shared_report(db: Session, token: str) -> Dict:
        token_digest = ReportService._digest_token(token)
        share = db.query(SharedReport).filter(SharedReport.token_digest == token_digest).first()
        if not share or share.revoked:
            raise ValueError("유효하지 않은 공유 링크입니다.")
        now = datetime.now(timezone.utc)
        # naive/aware 혼용 대비하여 UTC aware로 변환 후 비교
        expires_at = ReportService._to_aware_utc(share.expires_at)
        now_aware = ReportService._to_aware_utc(now)
        if expires_at < now_aware:
            raise ValueError("만료된 공유 링크입니다.")
        return share.snapshot

    @staticmethod
    def revoke_shared_report(db: Session, user_id: int, token: str) -> bool:
        token_digest = ReportService._digest_token(token)
        share = db.query(SharedReport).filter(
            SharedReport.token_digest == token_digest,
            SharedReport.user_id == user_id
        ).first()
        if not share:
            return False
        share.revoked = True
        db.commit()
        return True

    @staticmethod
    def list_active_shares(db: Session, user_id: int) -> List[Dict]:
        now = datetime.now(timezone.utc)
        shares = db.query(SharedReport).filter(
            SharedReport.user_id == user_id,
            SharedReport.revoked == False,
            SharedReport.expires_at >= now
        ).all()
        return [
            {
                "created_at": ReportService._to_aware_utc(s.created_at),
                "expires_at": ReportService._to_aware_utc(s.expires_at),
            }
            for s in shares
        ]

