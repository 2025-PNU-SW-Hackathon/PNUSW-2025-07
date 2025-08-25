# Garden Assets 폴더

이 폴더는 SimLog 마음 정원 기능에서 사용할 이미지 에셋들을 저장하는 곳입니다.

## 📁 폴더 구조
```
garden/
├── flowers/          # 꽃 이미지들
├── pots/            # 화분 이미지들
├── decorations/     # 장식품 이미지들
├── backgrounds/     # 배경 요소들
└── ui/              # UI 요소들
```

## 🎨 권장 이미지 크기
- **아이템 이미지**: 32x32px 또는 64x64px
- **배경 이미지**: 128x128px 또는 256x256px
- **형식**: PNG (투명 배경 권장)

## 📥 피그마에서 다운로드 방법
1. [Garden This - The Game](https://www.figma.com/design/gM5I0DyLyUUKReZpsuSKxw/Garden-This---The-Game--Community-?node-id=0-1&p=f&t=6kARzRFFqu14F3wQ-0) 접속
2. 원하는 요소 선택
3. 우클릭 → Export
4. PNG 형식으로 다운로드
5. 이 폴더에 저장

## 🔧 사용법
다운로드한 이미지는 `garden_screen.dart`에서 다음과 같이 사용됩니다:

```dart
Image.asset(
  'assets/images/garden/flowers/rose.png',
  width: 16,
  height: 16,
  fit: BoxFit.contain,
)
``` 