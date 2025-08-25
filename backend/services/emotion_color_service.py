from typing import Dict, List, Tuple
import json

class EmotionColorService:
    """
    로버트 플루치크의 감정의 바퀴 기반 색상 매핑 서비스
    """
    
    # 8가지 기본 감정과 감정의 바퀴 원색 매핑
    EMOTION_COLORS = {
        "기쁨": {
            "name": "옐로우",
            "hex": "#FFFF00",
            "rgb": (255, 255, 0),
            "description": "기쁨의 원색"
        },
        "신뢰": {
            "name": "그린",
            "hex": "#00FF00",
            "rgb": (0, 255, 0),
            "description": "신뢰의 원색"
        },
        "두려움": {
            "name": "청록",
            "hex": "#00FFFF",
            "rgb": (0, 255, 255),
            "description": "두려움의 원색"
        },
        "놀람": {
            "name": "블루",
            "hex": "#0000FF",
            "rgb": (0, 0, 255),
            "description": "놀람의 원색"
        },
        "슬픔": {
            "name": "네이비",
            "hex": "#000080",
            "rgb": (0, 0, 128),
            "description": "슬픔의 원색"
        },
        "혐오": {
            "name": "퍼플",
            "hex": "#800080",
            "rgb": (128, 0, 128),
            "description": "혐오의 원색"
        },
        "분노": {
            "name": "레드",
            "hex": "#FF0000",
            "rgb": (255, 0, 0),
            "description": "분노의 원색"
        },
        "기대": {
            "name": "오렌지",
            "hex": "#FFA500",
            "rgb": (255, 165, 0),
            "description": "기대의 원색"
        }
    }
    
    # 감정 강도별 색상 변화 (1-10점) - 더 선명한 색상
    INTENSITY_MODIFIERS = {
        1: {"brightness": 0.95, "saturation": 0.8},
        2: {"brightness": 0.9, "saturation": 0.85},
        3: {"brightness": 0.85, "saturation": 0.9},
        4: {"brightness": 0.8, "saturation": 0.95},
        5: {"brightness": 0.75, "saturation": 1.0},
        6: {"brightness": 0.7, "saturation": 1.0},
        7: {"brightness": 0.65, "saturation": 1.0},
        8: {"brightness": 0.6, "saturation": 1.0},
        9: {"brightness": 0.55, "saturation": 1.0},
        10: {"brightness": 0.5, "saturation": 1.0}
    }

    # 감정의 바퀴 순서 (시계방향)
    WHEEL_ORDER = ["기쁨", "신뢰", "두려움", "놀람", "슬픔", "혐오", "분노", "기대"]

    # 2차 감정(Secondary dyads) 한글 라벨
    DYAD_LABELS = {
        ("기쁨", "신뢰"): "사랑",
        ("신뢰", "두려움"): "순종",
        ("두려움", "놀람"): "경외",
        ("놀람", "슬픔"): "실망",
        ("슬픔", "혐오"): "후회",
        ("혐오", "분노"): "경멸",
        ("분노", "기대"): "공격성",
        ("기대", "기쁨"): "낙관",
    }

    @staticmethod
    def _mix_rgb(rgb_a: tuple, rgb_b: tuple, wa: float = 0.5) -> tuple:
        wb = 1.0 - wa
        return (
            int(rgb_a[0] * wa + rgb_b[0] * wb),
            int(rgb_a[1] * wa + rgb_b[1] * wb),
            int(rgb_a[2] * wa + rgb_b[2] * wb),
        )

    @staticmethod
    def _build_extended_palette(intensity: int) -> Dict[str, Dict]:
        """플루치크 팔레트 확장: 8가지 기본 + 8가지 2차 감정(이웃 혼합)."""
        intensity = max(1, min(10, intensity))
        base = {
            emotion: EmotionColorService._get_color_with_intensity(emotion, intensity)
            for emotion in EmotionColorService.WHEEL_ORDER
        }

        # 기본
        palette: Dict[str, Dict] = {name: info for name, info in base.items()}

        # 이웃 혼합(Secondary dyads)
        n = len(EmotionColorService.WHEEL_ORDER)
        for i, emo in enumerate(EmotionColorService.WHEEL_ORDER):
            nxt = EmotionColorService.WHEEL_ORDER[(i + 1) % n]
            label = EmotionColorService.DYAD_LABELS.get((emo, nxt)) or EmotionColorService.DYAD_LABELS.get((nxt, emo))
            if not label:
                continue
            rgb = EmotionColorService._mix_rgb(base[emo]["rgb"], base[nxt]["rgb"], 0.5)
            palette[label] = {
                "name": label,
                "hex": "#{:02x}{:02x}{:02x}".format(*rgb),
                "rgb": rgb,
                "description": f"{emo}+{nxt} 조합 색",
                "intensity": intensity,
            }

        return palette

    @staticmethod
    def _find_closest_from_palette(rgb: tuple, palette: Dict[str, Dict]) -> str:
        best_name = None
        best_dist = float("inf")
        for name, info in palette.items():
            prgb = info.get("rgb")
            if not prgb:
                continue
            dist = sum((a - b) ** 2 for a, b in zip(rgb, prgb))
            if dist < best_dist:
                best_dist = dist
                best_name = name
        # 안전장치: 없으면 기쁨
        return best_name or "기쁨"
    
    @staticmethod
    def get_emotion_colors() -> Dict:
        """모든 감정 색상 정보 반환"""
        return EmotionColorService.EMOTION_COLORS
    
    @staticmethod
    def analyze_emotion_from_text(content: str) -> Dict:
        """
        텍스트에서 감정을 분석하고 색상 정보를 반환
        (실제로는 외부 AI API를 사용할 예정)
        """
        # 임시 감정 분석 로직 (실제로는 AI API 사용)
        emotion_scores = EmotionColorService._analyze_emotion_keywords(content)
        
        # 가장 높은 점수의 감정 찾기
        primary_emotion = max(emotion_scores.items(), key=lambda x: x[1])
        
        # 감정 강도 계산 (1-10)
        intensity = min(10, max(1, int(primary_emotion[1] * 10)))
        
        # 색상 정보 생성
        color_info = EmotionColorService._get_color_with_intensity(
            primary_emotion[0], intensity
        )
        
        return {
            "primary_emotion": primary_emotion[0],
            "emotion_scores": emotion_scores,
            "intensity": intensity,
            "color": color_info,
            "message": f"오늘의 감정색은 {color_info['name']}입니다~"
        }
    
    @staticmethod
    def _analyze_emotion_keywords(content: str) -> Dict[str, float]:
        """
        텍스트에서 감정 키워드를 분석하여 점수 반환
        (실제로는 AI API로 대체 예정)
        """
        emotion_keywords = {
            "기쁨": ["기쁘", "행복", "즐거", "웃", "신나", "좋", "만족", "감사"],
            "신뢰": ["믿", "안전", "안정", "확신", "신뢰", "의지"],
            "두려움": ["무서", "겁", "불안", "걱정", "두려", "떨", "긴장"],
            "놀람": ["놀라", "깜짝", "예상", "갑작", "충격", "놀람"],
            "슬픔": ["슬프", "우울", "속상", "서럽", "눈물", "비통", "허전"],
            "혐오": ["싫", "역겨", "불쾌", "짜증", "화나", "분노", "열받"],
            "분노": ["화나", "열받", "짜증", "분노", "화", "열", "폭발"],
            "기대": ["기대", "희망", "꿈", "미래", "계획", "준비", "새로운"]
        }
        
        scores = {emotion: 0.0 for emotion in emotion_keywords.keys()}
        
        # 각 감정별 키워드 검색
        for emotion, keywords in emotion_keywords.items():
            for keyword in keywords:
                if keyword in content:
                    scores[emotion] += 0.3  # 키워드당 0.3점 추가
        
        # 최소 점수 보장
        if max(scores.values()) == 0:
            scores["기쁨"] = 0.1  # 기본값
        
        return scores
    
    @staticmethod
    def _get_color_with_intensity(emotion: str, intensity: int) -> dict:
        """감정과 강도에 따른 색상 정보 반환 (더 선명한 색상)"""
        if emotion not in EmotionColorService.EMOTION_COLORS:
            emotion = "기쁨"  # 기본값
        base_color = EmotionColorService.EMOTION_COLORS[emotion]
        modifier = EmotionColorService.INTENSITY_MODIFIERS.get(intensity, EmotionColorService.INTENSITY_MODIFIERS[5])
        
        # 강도에 따른 색상 조정 (밝기와 채도 조정)
        adjusted_rgb = tuple(int(c * modifier["brightness"]) for c in base_color["rgb"])
        
        # 채도 조정 (더 선명하게)
        saturation = modifier.get("saturation", 1.0)
        if saturation < 1.0:
            # RGB를 HSL로 변환하여 채도 조정
            r, g, b = adjusted_rgb
            max_val = max(r, g, b)
            min_val = min(r, g, b)
            delta = max_val - min_val
            
            if delta > 0:
                # 채도 조정
                new_delta = int(delta * saturation)
                adjusted_rgb = tuple(
                    int(max_val - new_delta * (max_val - c) / delta) if delta > 0 else c
                    for c in adjusted_rgb
                )
        
        adjusted_hex = "#{:02x}{:02x}{:02x}".format(*adjusted_rgb)
        return {
            "name": base_color["name"],
            "hex": adjusted_hex,
            "rgb": adjusted_rgb,
            "description": base_color["description"],
            "intensity": intensity
        }
    
    @staticmethod
    def get_average_emotion_color(emotion_records: List[Dict]) -> Dict:
        """
        대표 감정색은 플루치크 팔레트(기본 8감정 + 인접 2차 감정 조합)에서 선택한다.
        - 기록들의 평균 RGB를 계산
        - 평균 강도를 계산
        - 평균 강도로 생성한 확장 팔레트에서 평균 RGB와 가장 가까운 색을 선택
        """
        if not emotion_records:
            return EmotionColorService._get_color_with_intensity("기쁨", 5)

        # 평균 RGB
        rgbs = [tuple(rec.get("color", {}).get("rgb", ())) for rec in emotion_records]
        rgbs = [rgb for rgb in rgbs if isinstance(rgb, (list, tuple)) and len(rgb) == 3]
        if not rgbs:
            # 색 정보가 없으면 기본 로직으로 폴백
            return EmotionColorService._get_color_with_intensity("기쁨", 5)
        total_r = sum(rgb[0] for rgb in rgbs)
        total_g = sum(rgb[1] for rgb in rgbs)
        total_b = sum(rgb[2] for rgb in rgbs)
        count = len(rgbs)
        avg_rgb = (int(total_r / count), int(total_g / count), int(total_b / count))

        # 평균 강도
        intensities = []
        for rec in emotion_records:
            color = rec.get("color", {})
            intensity = color.get("intensity", rec.get("intensity", 5))
            try:
                intensities.append(int(intensity))
            except Exception:
                intensities.append(5)
        avg_intensity = int(round(sum(intensities) / len(intensities))) if intensities else 5
        avg_intensity = max(1, min(10, avg_intensity))

        # 확장 팔레트에서 가장 가까운 색 선택
        palette = EmotionColorService._build_extended_palette(avg_intensity)
        chosen_name = EmotionColorService._find_closest_from_palette(avg_rgb, palette)
        chosen = palette[chosen_name]

        return {
            "name": chosen["name"],
            "hex": chosen["hex"],
            "rgb": chosen["rgb"],
            "description": f"지난 {count}일간의 대표 감정색입니다.",
            "period": count,
            "closest_emotion": chosen_name,
            "average_intensity": float(avg_intensity),
        }
    
    @staticmethod
    def _generate_average_color_name(rgb: Tuple[int, int, int], emotion: str, intensity: float) -> str:
        """평균 색상의 이름을 생성"""
        r, g, b = rgb
        
        # 색상의 밝기 계산
        brightness = (r + g + b) / 3
        
        # 색상의 채도 계산
        max_val = max(r, g, b)
        min_val = min(r, g, b)
        saturation = (max_val - min_val) / max_val if max_val > 0 else 0
        
        # 색상 이름 생성
        if brightness > 200:
            prefix = "밝은"
        elif brightness > 150:
            prefix = "선명한"
        elif brightness > 100:
            prefix = "중간"
        elif brightness > 50:
            prefix = "어두운"
        else:
            prefix = "깊은"
        
        # 감정에 따른 색상 이름 매핑
        emotion_colors = {
            "기쁨": "노랑",
            "신뢰": "초록",
            "두려움": "청록",
            "놀람": "파랑",
            "슬픔": "남색",
            "혐오": "보라",
            "분노": "빨강",
            "기대": "주황"
        }
        
        base_color = emotion_colors.get(emotion, "회색")
        
        return f"{prefix} {base_color}"
    
    @staticmethod
    def _find_closest_emotion(rgb: Tuple[int, int, int]) -> str:
        """RGB 값과 가장 가까운 감정 찾기"""
        min_distance = float('inf')
        closest_emotion = "기쁨"
        
        for emotion, color_info in EmotionColorService.EMOTION_COLORS.items():
            distance = sum((a - b) ** 2 for a, b in zip(rgb, color_info["rgb"]))
            if distance < min_distance:
                min_distance = distance
                closest_emotion = emotion
        
        return closest_emotion 