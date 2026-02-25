# DIT FolderGen - 설치 가이드

## 시스템 요구사항

- macOS 13.0 (Ventura) 이상
- Apple Silicon (M1/M2/M3/M4) 또는 Intel Mac

---

## 설치 방법

### DMG 파일로 설치하기

1. **`DIT_FolderGen_v1.0.0.dmg`** 파일을 더블클릭하여 엽니다
2. 열린 창에서 **DIT_FolderGen** 앱을 **Applications** 폴더로 드래그합니다
3. **Presets** 폴더도 함께 복사해주세요 (홈 폴더 등 원하는 위치에 저장)

### ZIP 파일로 설치하기

1. **`DIT_FolderGen_v1.0.0.zip`** 파일의 압축을 풀어주세요
2. **DIT_FolderGen.app**을 `/Applications` 폴더로 이동합니다

---

## 처음 실행 시 보안 경고 해결

이 앱은 Apple Developer 인증서로 서명되지 않았기 때문에, 처음 실행할 때 macOS가 보안 경고를 표시합니다. 아래 방법으로 해결할 수 있습니다.

### 방법 1: 우클릭으로 열기 (추천)

1. **Applications** 폴더에서 **DIT_FolderGen** 앱을 찾습니다
2. 앱 아이콘을 **우클릭** (또는 Control + 클릭) 합니다
3. 메뉴에서 **"열기"** 를 선택합니다
4. 경고 대화상자에서 **"열기"** 버튼을 클릭합니다
5. 이후부터는 일반적으로 더블클릭으로 열 수 있습니다

### 방법 2: 시스템 설정에서 허용

1. 앱을 더블클릭하면 경고가 뜹니다 → **"확인"** 클릭
2. **시스템 설정** → **개인 정보 보호 및 보안** 으로 이동합니다
3. 아래로 스크롤하면 **"DIT_FolderGen이(가) 차단되었습니다"** 메시지가 보입니다
4. **"확인 없이 열기"** 버튼을 클릭합니다
5. 비밀번호 또는 Touch ID로 인증합니다

### 방법 3: 터미널 명령어 (고급)

터미널을 열고 다음 명령어를 실행합니다:

```bash
xattr -cr /Applications/DIT_FolderGen.app
```

이후 앱을 정상적으로 열 수 있습니다.

---

## Presets 폴더 설정

앱이 커스텀 프리셋을 사용하려면 Presets 폴더가 필요합니다. 첫 실행 시 앱이 기본 프리셋을 자동으로 생성합니다.

DMG에 포함된 **Presets** 폴더에는 추가 프리셋이 포함되어 있으니, 필요하면 앱에서 불러와 사용할 수 있습니다.

---

## 문제 해결

| 증상 | 해결 방법 |
|------|----------|
| "앱이 손상되었습니다" 경고 | 터미널에서 `xattr -cr /Applications/DIT_FolderGen.app` 실행 |
| 앱이 실행되지 않음 | macOS 버전이 13.0 이상인지 확인 |
| 프리셋이 보이지 않음 | 앱을 한 번 실행하면 기본 프리셋이 자동 생성됩니다 |

---

## 삭제 방법

Applications 폴더에서 DIT_FolderGen.app을 휴지통으로 드래그하면 됩니다.

---

**Powered by Nomad Jay**
Copyright © 2025 Nomad Jay. All rights reserved.
