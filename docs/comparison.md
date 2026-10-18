# 헬품타 Native(Compose) vs Flutter 비교 기록

## 프로젝트 목적
- 네이티브 헬품타를 **요구사항 명세**로 사용하고, 구현은 **Flutter다운 좋은 아키텍처**로 새로 작성
- 코드를 언어만 바꿔 옮기는 것이 아니라, 같은 요구사항을 각 플랫폼의 현업 관례대로 구현하고 차이를 기록
- 네이티브의 버그·구조적 예외는 Flutter에서 복사하지 않고 개선해서 구현

## 비교 환경
- Native: Kotlin, Jetpack Compose, Clean Architecture + MVI, Hilt
- Flutter: Flutter 3.47.5 / Dart 3.13.4, Clean Architecture + Bloc
- 테스트 기기: Android 실기기 (iOS는 CI 빌드 검증까지만)

---

## 아키텍처 개요

### 레이어 대응
| 레이어 | Native | Flutter |
|---|---|---|
| Domain | 순수 Kotlin (model, repository 인터페이스, usecase) | 순수 Dart (entity, repository 인터페이스, usecase) |
| Data | RepositoryImpl + Mapper, Firebase 직접 호출 | 동일 |
| UI | MVI (Contract + ViewModel) | Bloc (Event / State / Bloc) |
| 공통 | Kotlin 표준 `Result` | `core/result.dart` (공식 가이드 Result 패턴) |
| DI | Hilt | `RepositoryProvider` + 라우트에서 조립 |
| 라우팅 | Navigation Compose | go_router |

### 설계 결정
| 항목 | 결정 | 근거 |
|---|---|---|
| 상태관리 | Bloc | MVI 계열로 단방향 흐름 유지. Riverpod과 함께 현업 양강 |
| 일회성 효과 | status enum + BlocListener | Bloc 현업 표준. 요청마다 loading을 거쳐 같은 효과가 반복돼도 동작 |
| 단순 화면 이동 | 화면에서 `context.go/push` 직접 호출 | go_router 관례. 로직 없는 이동은 Bloc을 거치지 않음 |
| 화면 간 결과 전달 | `context.pop(결과)` + `await context.push()` | 작업을 완료한 화면만 결과를 돌려주고, 받는 쪽은 결과가 있을 때만 반응 |
| 홈 새로고침 | 어느 화면에서 돌아오든 새로고침 (예외) | 덮어쓸 화면 상태가 없고 새로고침 중에도 그리드 유지. 목록이 바뀌는 경로마다 결과를 챙기는 것보다 누락 위험이 적음 |
| 오프라인 쓰기 | 서버 쓰기 전 연결 확인, 오프라인이면 즉시 실패 | Firestore는 오프라인 쓰기를 임시 저장하고 서버 응답까지 대기 → 무한 로딩과 중복 생성 방지 |
| 오케스트레이션 | UseCase가 다른 UseCase 호출 | "로그인 후 유저 저장" 같은 비즈니스 흐름을 UI 레이어에서 분리 |
| Service 레이어 | 두지 않음 | Firebase SDK 자체가 Service 역할 |
| Domain의 equatable | 허용 | Kotlin data class 역할 대체용 순수 Dart 패키지 |

---

## 0. 프로젝트 설정

### Firebase 연결
| 항목 | Native | Flutter |
|---|---|---|
| 앱 등록 | 콘솔에서 Android 앱 1개 수동 등록 | FlutterFire CLI가 Android·iOS 앱 자동 등록 |
| 설정 파일 | google-services.json 1개 | google-services.json, GoogleService-Info.plist, firebase_options.dart 3개 |
| 초기화 | google-services 플러그인이 자동 초기화 | main()에서 Firebase.initializeApp() 직접 호출 |

- Flutter는 Dart 코드가 네이티브 설정 파일을 직접 읽지 못해 firebase_options.dart가 별도로 필요
- runApp 전에 네이티브 기능을 쓰려면 WidgetsFlutterBinding.ensureInitialized() 선행 필요

### 빌드 환경
- AGP 9 Built-in Kotlin 전환 과도기: firebase_core가 아직 KGP를 사용해 경고 발생, android.builtInKotlin=false로 임시 호환
- 플러그인 생태계의 네이티브 빌드 도구 변화 대응이 플러그인 제작자에게 의존적 (Native는 직접 대응 가능)

### 라우팅
| 항목 | Native | Flutter |
|---|---|---|
| 경로 정의 | `composable("group/{groupId}")` | `GoRoute(path: '/group/:groupId')` |
| 인자 수신 | `backStackEntry.arguments` | `state.pathParameters` |
| 스택 쌓기 | `navigate()` | `context.push()` |
| 스택 교체 | `navigate()` + `popUpTo(inclusive = true)` | `context.go()` |
| 로그인 상태 분기 | NavGraph 호출부에서 `startDestination` 결정 후 주입 | `redirect`에서 매 이동마다 검사 |
| 화면의 이동 방식 | 화면은 콜백만 받고 경로는 NavGraph만 앎 | 화면이 `context.go()`로 직접 이동 (go_router 관례) |

- go_router는 라우트 선언 순서대로 매칭 → `group/create`를 `group/:groupId`보다 먼저 선언해야 함
- redirect는 시작 화면뿐 아니라 모든 이동에 적용 → 로그인 상태에서 로그인 화면 접근 차단까지 한 곳에서 처리

---

## 1. 인증

### 구조
| 항목 | Native | Flutter |
|---|---|---|
| 결과 타입 | Kotlin 표준 `Result` + `fold` | 공식 가이드 `Result`(sealed Ok/Error) + `switch` |
| 에러 판별 | FirebaseAuth 예외 **타입**별 `is` | `FirebaseAuthException.code` **문자열** switch |
| data class | `data class` 자동 생성 | `Equatable` + `props` + `copyWith` 직접 작성 |
| nullable 초기화 | `copy(errorMessage = null)` | `copyWith(errorMessage: () => null)` |
| UseCase 호출 | `operator fun invoke` | `call` 메서드 |
| 로그인 후 유저 저장 | ViewModel이 `saveUserUseCase()` 호출 | `GoogleLoginUseCase`/`SignUpUseCase` 내부에서 처리 |

### 일회성 효과 (SideEffect)
| | Native | Flutter |
|---|---|---|
| 방식 | `SharedFlow`로 별도 전달 → `LaunchedEffect`에서 수집 | State의 `status` 변화 → `BlocListener`가 반응 |
| 성공 이동 | `SideEffect.NavigateToHome` | `status == success` 전환 시 `context.go()` |

- Bloc은 State만 내보내고 SideEffect 전용 통로가 없음
- State에 "이동할 대상" 같은 값을 담으면 같은 값이 반복될 때 State가 변하지 않아 반응하지 않음
- 현업 해결책: 단순 이동은 화면에서 직접, 서버 결과는 `status`(initial → loading → success/failure)로 처리. 요청마다 loading을 거치므로 같은 실패가 연속돼도 매번 반응

### Google 로그인
| 항목 | Native | Flutter |
|---|---|---|
| 라이브러리 | Credential Manager + googleid | google_sign_in 7.x |
| Activity | Credential Manager가 요구 → ViewModel까지 전달 | 불필요 |
| 토큰 획득 위치 | ViewModel이 `GoogleAuthClient` 직접 호출 (UI → Data 의존, 예외 허용) | `AuthRepositoryImpl` 내부 (Data 레이어에 캡슐화) |
| 웹 클라이언트 ID | BuildConfig에 직접 설정 | google-services.json(client_type: 3)에서 자동 로드 |
| 계정 선택 흐름 | One Tap 실패 시 SignInWithGoogle로 재시도 직접 구현 | authenticate() 한 번으로 플러그인이 처리 |
| 초기화 | 없음 | authenticate() 전 initialize() 필수 |

- Activity 요구가 사라지면서 네이티브에서 허용했던 레이어 예외가 Flutter에선 해소됨
- 코드량은 크게 줄었지만 계정 선택 흐름을 세부적으로 제어할 수 없음

### 플랫폼 기능 대체
- `Patterns.EMAIL_ADDRESS` → 정규식 직접 작성 (완전히 동일한 규칙은 아님)
- `Toast` → `SnackBar` (Flutter 기본 Toast 없음, iOS엔 Toast 개념 자체가 없음)
- FlutterFire `User` 클래스명이 도메인 `User`와 충돌 → `as fb` import 별칭

### UI
- Modifier 없음 → 크기·여백을 `SizedBox`, `Padding` 위젯으로 감싸서 지정
- `Arrangement.spacedBy` → `Column(spacing:)`
- `isError` + 별도 Text → `InputDecoration(errorText:)` 하나로 처리
- 키보드 오버플로 방지용 `SingleChildScrollView` 필요 (Compose는 불필요했음)
- TextField는 자체 컨트롤러가 값을 보유 → Compose처럼 State가 입력값을 완전히 제어하지 않음

### 테스트
- 위젯 테스트가 기본으로 PC에서 실행 (Native Compose UI 테스트는 기본이 에뮬, PC 실행은 Robolectric 필요)
- Dart는 모든 클래스가 암묵적 인터페이스 → `extends Fake implements X`로 필요한 메서드만 구현한 테스트 대역 생성 (Native는 MockK 등 외부 라이브러리 사용)
- Repository 인터페이스 + 생성자 주입 구조 덕분에 Firebase 없이 앱 전체를 테스트 가능
- Bloc 테스트는 `bloc_test`의 `blocTest`로 "시작 상태(seed) → 이벤트(act) → State 순서(expect)"를 선언형으로 검증 (Native의 ViewModel + Turbine 조합에 해당)
- Equatable 덕분에 State를 값으로 비교 가능
- 사용하지 않는 UseCase도 `Fake`로 주입 → 의도치 않게 호출되면 테스트가 실패해 "이 이벤트는 이 UseCase만 쓴다"까지 검증

---

## 2. 홈 (그룹 목록)

### 구조
| 항목 | Native | Flutter |
|---|---|---|
| 단순 이동 (그룹 카드, 생성 버튼) | Intent → ViewModel → SideEffect → 이동 | 화면에서 `context.push()` 직접 호출 |
| Bloc/ViewModel 역할 | 목록 로딩 + 이동 중계 | 목록 로딩만 |
| 최초 로딩 | ViewModel `init` 블록 | `BlocProvider(create: ...)..add(event)` |
| 화면 복귀 시 새로고침 | `LifecycleEventObserver` `ON_RESUME` | `await context.push()` 완료 후 이벤트 전송 |
| 그리드 | `LazyVerticalGrid` | `GridView.builder` |
| 상태별 화면 분기 | `when` + 조건식 | `switch` + 패턴 매칭 (`HomeState(groups: [_, ...])`) |
| 이미지 로딩 | Coil3 `AsyncImage` | `cached_network_image` (디스크 캐시) |

- Flutter엔 화면 단위 ON_RESUME가 없음 → `push()`가 돌려주는 Future로 복귀 시점을 잡는 것이 관례
- 네이티브는 앱이 백그라운드에서 돌아올 때도 새로고침됐지만, 그룹 목록은 본인 행동(생성·탈퇴)으로만 바뀌어 Flutter에선 생략
- 라우트를 `/home` 하위로 중첩 → `go('/home/group/xxx')`가 "홈 → 대상" 스택을 만들어 `popUpTo(Home)`과 같은 효과

### UI
- `Box` 겹치기 → `Stack`
- `Card(onClick)` → InkWell 물결이 자식 아래에 그려져 이미지에 가려짐 → 투명 `Material` + `InkWell`을 Stack 맨 위에 배치
- 그라데이션 시작점: 네이티브 `startY = 300f`(픽셀 고정) → Flutter `stops`(비율)로 해상도와 무관하게 동일 위치
- 카드 비율: `Modifier.aspectRatio(1f)` → GridView는 칸 크기를 그리드가 정하므로 `childAspectRatio: 1`로 지정
- `colorScheme.surfaceVariant` → Flutter M3 권장 토큰 `surfaceContainerHighest`

---

## 3. 그룹 생성

### 구조
| 항목 | Native | Flutter |
|---|---|---|
| 이미지 선택 | `rememberLauncherForActivityResult(PickVisualMedia())` 콜백 | `await ImagePicker().pickImage()` |
| 이미지 전달 | `Uri.toString()` | `XFile.path` (파일 경로 문자열) |
| 미리보기 | `AsyncImage(model = uri)` | `Image.file(File(path))` |
| 압축 | `ImageCompressor` 직접 구현 (샘플링, 스케일, EXIF 회전, JPEG 인코딩) | `flutter_image_compress` + 크기 계산만 직접 |
| 원본 크기 읽기 | `BitmapFactory.Options(inJustDecodeBounds = true)` | `ui.ImageDescriptor` |
| 업로드 | `ref.putBytes(bytes, storageMetadata { })` | `ref.putData(bytes, SettableMetadata(...))` |
| 이미지 파일명 | 랜덤 UUID | Firestore 문서 ID (그룹 ↔ 이미지 1:1) |
| 생성 후 이동 | 생성 화면이 `navigate(상세) { popUpTo(Home) }` | 생성 화면이 `pop(groupId)` → 홈이 새로고침 후 상세로 `push` |

- `flutter_image_compress`의 `minWidth`/`minHeight`는 이름과 달리 축소 기준이며, 가로·세로 비율 중 작은 쪽으로 축소함 → 원본 크기를 읽어 목표 **짧은 변** 길이를 넘겨야 "긴 변 1080" 결과가 나옴 (EXIF 회전과 무관하게 동작)
- `image_picker`의 `maxWidth`/`imageQuality`로 고를 때 줄이는 방법도 있지만, 크기 정책이 UI로 올라오고 플랫폼별 리사이즈 차이 이슈가 있어 Data 레이어 압축 유지

### 화면 간 결과 전달
| | Native | Flutter |
|---|---|---|
| 결과 남기기 | `previousBackStackEntry?.savedStateHandle?.set(...)` | `context.pop(결과)` |
| 결과 받기 | `getStateFlow()` 관찰 + `LaunchedEffect` | `await context.push()` 반환값 |
| 신호 소비(리셋) | 직접 false로 되돌려야 함 | 불필요 (Future는 한 번만 완료) |

- 네이티브에서 겪은 "신호를 놓치거나 리셋 타이밍이 꼬이는" 문제가 구조적으로 발생하지 않음
- 주의: `go()`로 스택을 교체하면 기다리던 `push`의 Future가 완료되지 않음 → 처음엔 생성 화면에서 `go(상세)`로 이동했다가 홈 새로고침이 누락되는 버그 발생, `pop(결과)` 방식으로 수정

### 오프라인 처리
- Firestore는 오프라인 쓰기를 기기에 임시 저장하고 연결되면 전송 → `await`는 서버 응답까지 끝나지 않아 무한 로딩
- Storage 업로드는 연결될 때까지 재시도(기본 최대 10분) 후 실패
- 로딩 중 화면을 나가도 임시 저장된 쓰기는 남아 나중에 조용히 생성됨 → 재시도 시 중복 생성 위험
- 타임아웃은 "실패 표시 후 실제로는 생성"되는 중복 문제가 있어 제외
- `connectivity_plus`로 요청 전 연결 확인 → 명백한 오프라인은 즉시 "네트워크 연결을 확인해주세요". 와이파이는 잡혔지만 인터넷이 안 되는 경우는 판별 불가 (한계)
- 연결 확인은 Data 레이어(`NetworkChecker`), 실패 종류는 Domain(`NetworkUnavailableException`)에 두어 Bloc은 Data를 모른 채 문구만 선택

### UI
- `Spacer(Modifier.weight(1f))`로 버튼을 바닥에 두면 Flutter에선 키보드가 올라올 때 오버플로 → `SliverFillRemaining(hasScrollBody: false)`로 평소엔 바닥 고정, 공간 부족 시 스크롤
- 연속 실패 시 스낵바가 줄 서지 않도록 `hideCurrentSnackBar()` 후 표시

---

## 4. 그룹 상세

### 구조
| 항목 | Native | Flutter |
|---|---|---|
| 날짜 표현 | millis(Long) + `Calendar` 계산 | Domain은 `DateTime`, Firestore 저장만 millis |
| 날짜 이동 | `Calendar.add(DAY_OF_MONTH)` | `DateTime(y, m, d + n)` (월말·서머타임 자동 처리) |
| 병렬 로딩 | `supervisorScope` + `async` × 3 | `await (a, b, c).wait` |
| 재진입 방지 | `isSameGroup`이면 로딩 skip (`LaunchedEffect` 재실행 대응) | 불필요 — Bloc은 라우트당 한 번만 생성 |
| 달력 날짜 | Material3 DatePicker가 UTC 반환 → 로컬 변환 함수 필요 | `showDatePicker`가 로컬 `DateTime` 반환 |
| 확인 다이얼로그 | `showLeaveDialog`, `deleteTarget` 상태 변수 | `await showDialog<bool>()` 반환값 |
| 메뉴 | `DropdownMenu` + `menuExpanded` 상태 | `PopupMenuButton` (열림 상태 자체 관리) |
| 작성 완료 후 새로고침 | `savedStateHandle` 신호 + 소비 | `await push<bool>()` 결과가 `true`일 때만 |
| 단순 피드백 (이미 작성함) | Intent → ViewModel → SideEffect 토스트 | 화면에서 바로 스낵바 |

### 동시성 제어
| 상황 | Native | Flutter |
|---|---|---|
| 날짜 연타 | 대응 없음 → 늦게 온 이전 날짜 응답이 최신 화면을 덮어쓸 수 있음 | `restartable()` → 이전 요청 결과 무시 |
| 탈퇴 중복 요청 | `if (isLeaving) return` | `droppable()` |

- Bloc은 이벤트별로 처리 규칙을 선언형으로 지정 (`bloc_concurrency`)

### 데이터
- 탈퇴 시 내 기록 일괄 삭제를 WriteBatch로 처리 → 일부만 삭제되는 상태 방지
- 삭제 순서: 네이티브는 이미지 → 문서, Flutter는 문서 → 이미지. 문서 삭제 실패 시 "이미지 깨진 기록"이 남는 대신, 최악의 경우에도 보이지 않는 고아 파일만 남음
- 새 Firebase 프로젝트는 복합 인덱스를 다시 생성해야 함 (`groupId` + `createdAt`, `groupId` + `userId` + `createdAt`). 인덱스 없으면 `FAILED_PRECONDITION` + 생성 링크가 로그에 출력

### UI
- 한국어 달력을 위해 `flutter_localizations` + `locale: ko` 설정 필요 (Android는 시스템 언어를 따름)
- 네이티브 커스텀 비활성 색(`DisabledGray`) 대신 M3 비활성 규칙(onSurface 12% / 38%) 사용
- 초대 코드 복사: Flutter엔 초대 참여 기능이 없어 그룹 이름만 복사 (메뉴는 유지)

---

## 5. 기록 작성·수정

### 구조
| 항목 | Native | Flutter |
|---|---|---|
| 이미지 상태 | `imageUri: String?` 하나로 표현, Repository에서 `startsWith("http")`로 기존/신규 구분 | `sealed class RecordImage` (없음 / 기존 유지 / 새 사진) + `switch` |
| 작성·수정 구분 | `recordId` nullable 인자 | 라우트 쿼리 `?recordId=` |
| 기존 값 채우기 | `OutlinedTextField(value = uiState.x)` | 로딩 후 처음 그릴 때 `TextFormField(initialValue:)` |
| 운동 시간 입력 제한 | ViewModel에서 숫자 필터 + 상한 초과 무시 | `inputFormatters` (`digitsOnly` + 커스텀 상한 Formatter) |
| 저장 완료 전달 | `previousBackStackEntry.savedStateHandle["recordCreated"] = true` | `context.pop(true)` |
| 작성·수정 결과 타입 통일 | `.map { recordId }`로 `Result<String>`에 맞춤 | `Result<Object?>`로 받아 `switch` |

- Compose는 State가 입력값을 제어해서 ViewModel에서 초과 입력을 무시할 수 있었지만, Flutter `TextField`는 자체적으로 값을 보유 → Bloc에서 무시해도 입력창엔 그대로 보임 → 입력 단계(`inputFormatters`)에서 차단
- `initialValue`는 처음 그릴 때만 반영 → 수정 모드는 기존 기록 로딩이 끝난 뒤에 입력창을 그려야 함

### 도메인 규칙
| 규칙 | Native | Flutter |
|---|---|---|
| 하루 한 번 작성 | FAB 비활성화로만 막음. `hasWroteToday` 조회 실패 시 기본값 `false` → 중복 작성 가능 | `CreateRecordUseCase`에서 저장 직전 재확인 → `AlreadyWroteTodayException` |
| 당일만 수정 | 수정 버튼 표시 여부로만 막음. 23:59에 열고 00:01에 저장하면 어제 기록 수정됨 | `UpdateRecordUseCase`에서 작성일 확인 → `RecordEditExpiredException` |

- 화면 제어는 UX, 규칙 보장은 Domain. 화면이 실수하거나 조건이 바뀌어도 규칙은 UseCase가 지킴

### 이미지 처리
| | Native | Flutter |
|---|---|---|
| 교체 순서 | 새 업로드 → **기존 삭제** → 문서 업데이트 | 새 업로드 → 문서 업데이트 → **기존 삭제** |
| 문서 업데이트 실패 시 | 기존 이미지가 이미 지워져 기록 사진이 깨짐 | 새로 올린 이미지만 정리, 기존 기록은 그대로 |
| 파일명 | 랜덤 UUID | 기록 ID + 업로드 시각 |

- 같은 경로에 덮어쓰면 다운로드 URL이 그대로라 `cached_network_image`가 옛날 사진을 보여줄 수 있어 매번 새 파일명 사용

---

## 6. 사진 추출

### 구조
| 항목 | Native | Flutter |
|---|---|---|
| 캡처 방식 | `rememberGraphicsLayer()` + `drawWithContent { record }` | `RepaintBoundary` + `GlobalKey` |
| 캡처 결과 | `graphicsLayer.toImageBitmap()` → `android.graphics.Bitmap` | `boundary.toImage(pixelRatio:)` → `Uint8List`(PNG) |
| 출력 해상도 | 화면에 보이는 크기 그대로 (기기마다 다름, 예: 918×1632) | `pixelRatio = 1080 ÷ 화면상 폭` → 항상 1080×1920 |
| 시스템 글자 크기 | sp 단위라 영향 받음 → 카드 레이아웃 변동 | `MediaQuery.withNoTextScaling`으로 카드 안에서만 무시 |
| 이미지 로딩 대기 | Coil `onSuccess`/`onError` 콜백으로 개수 카운트 | 그리기 전에 `precacheImage` + `Future.wait` |
| 캡처 시 이미지 위젯 | `AsyncImage` | 페이드인 없는 `Image` (애니메이션 중 캡처 방지) |
| 갤러리 저장 | `ImageSaver`: MediaStore, `IS_PENDING`, 권한 런처, Android 버전 분기 | `gal` 패키지 `putImageBytes(album:)` 한 줄 |
| 저장 포맷 | JPEG 95% | PNG (무손실, 용량 큼) |
| 레이아웃 계산 | `BoxWithConstraints` | `LayoutBuilder` |

- 네이티브는 Contract에 Android `Bitmap` 타입이 들어가지만, Flutter는 순수 바이트라 Event에 플랫폼 타입이 없음
- `ClipRRect` 안쪽에 `RepaintBoundary`를 둬서 화면은 둥근 카드, 저장 이미지는 사각형 (바깥에 두면 모서리가 투명하게 잘림)

### 레이어 구조
| | Native | Flutter |
|---|---|---|
| 갤러리 저장 의존 | ViewModel이 `data/util/ImageSaver` 직접 주입 (UI → Data) | `GalleryRepository`(Domain 인터페이스) + `SaveImageToGalleryUseCase` |
| 저장 권한 거부 | 화면에서 권한 런처 결과로 판단 | Data에서 `GalleryAccessDeniedException`으로 변환 → Bloc이 문구 선택 |

### Dart 문법 주의
- switch **표현식** 안에서는 `return`을 쓸 수 없음 → 실패 시 바로 반환하려면 switch **문** + `final` 지연 초기화 사용
- Kotlin `getOrElse { return Result.failure(it) }` 한 줄이 Dart에선 switch 문 몇 줄로 늘어남

---

## 7. 마이페이지 · 홈 배치 설정

### 설정 저장과 구독
| 항목 | Native | Flutter |
|---|---|---|
| 저장소 | Preferences DataStore | `shared_preferences` (`SharedPreferencesAsync`) |
| 변경 구독 | DataStore가 `Flow` 제공 → 마이페이지에서 바꾸면 홈 자동 반영 | 변경 알림 없음 → Repository가 "현재 값 + 이후 변경"을 내보내는 Stream을 직접 구성 |
| Stream 생성 | `flow { }` / `dataStore.data.map { }` | `async*` + `yield` / `yield*` + `StreamController.broadcast()` |
| ViewModel/Bloc 구독 | `viewModelScope.launch { flow.collect { } }` | `emit.forEach(stream, onData:)` (Bloc이 닫히면 자동 해제) |
| 잘못된 저장값 | `runCatching { valueOf() }.getOrDefault(GRID)` | `values.asNameMap()[saved] ?? grid` |

- Flutter 방식의 한계: 이 Repository를 거친 변경만 알림. 설정을 바꾸는 곳이 마이페이지 하나라 충분

### 계정 삭제
| 항목 | Native | Flutter |
|---|---|---|
| 흐름 조립 | ViewModel이 "재인증 → 삭제" 순서 조립 | `DeleteAccountUseCase`가 재인증부터 Auth 삭제까지 전부 처리 |
| 재인증 방법 전달 | `DeleteWithGoogle(activity)` / `DeleteWithPassword(password)` Intent | `ReauthMethod` sealed class (`PasswordReauth` / `GoogleReauth`) |
| Google 재인증 토큰 | ViewModel이 `GoogleAuthClient`에 Activity 넘겨 직접 획득 (UI → Data) | `AuthRepositoryImpl.reauthenticateWithGoogle()` 내부에서 획득 |
| 그룹별 탈퇴 | UseCase 안에서 기록 삭제 + `leaveGroup` 반복 | 기존 `LeaveGroupUseCase` 재사용 |
| 비밀번호 입력 다이얼로그 | `showPasswordDialog` 상태 + 내부 `remember` | `showDialog<String>()`이 입력값을 Future로 반환 |

- 순서는 양쪽 동일: 본인 확인 → 그룹 탈퇴(내 기록 삭제 포함) → users 문서 삭제 → Auth 계정 삭제
- 본인 확인을 데이터 삭제 **전에** 먼저 하는 설계는 네이티브부터 잘 되어 있던 부분

### 에러 구분
| 상황 | Native | Flutter |
|---|---|---|
| 비밀번호 틀림 | "비밀번호를 확인해주세요" | 동일 |
| 오프라인에서 재인증 실패 | "비밀번호를 확인해주세요" (원인과 다른 안내) | 재인증 실패를 `ReauthenticationFailedException(cause)`로 감싸 원인 확인 → "네트워크 연결을 확인해주세요" |
| Google 계정 선택 취소 | "구글 인증에 실패했어요" | 문구 없이 원래 상태로 |

### 플랫폼 기능 대체
- 링크 열기: `Intent.ACTION_VIEW` → `url_launcher`
- 버전 표시: `BuildConfig.VERSION_NAME` → `package_info_plus` (`pubspec.yaml`의 `version`)
- 세그먼트 버튼: `SingleChoiceSegmentedButtonRow` → `SegmentedButton<T>` (선택값을 `Set`으로 다룸)

### Dart 문법
- `if (result case Error(:final error))` → 실패만 골라서 바로 반환할 때 switch 문보다 간결 (Kotlin `getOrElse { return }` 대응)

---

## 8. iOS 빌드 · CI

### iOS 설정 (Info.plist)
| 항목 | Android | iOS |
|---|---|---|
| 설정 파일 | `AndroidManifest.xml` | `Info.plist` |
| 사진 권한 | `uses-permission` 선언, 팝업 문구는 시스템 기본 | `NSPhotoLibraryUsageDescription` 등에 **이유 문구 직접 작성**. 없으면 접근 순간 앱 강제 종료 |
| Google 로그인 | `google-services.json` + SHA-1 등록으로 플러그인이 처리 | `GIDClientID` + `CFBundleURLTypes`(계정 선택 후 앱으로 돌아오는 URL scheme) 직접 등록 |

- 권한 문구·URL scheme 누락은 **빌드는 통과하고 실행 시점에 터지는** 문제라 CI로 잡을 수 없음 → 공식 문서 기준으로 선반영

### CI (GitHub Actions)
| 단계 | 러너 | 내용 |
|---|---|---|
| Flutter 테스트 | ubuntu | `flutter test` |
| iOS 빌드 검증 | macOS | 테스트 통과 시 `flutter build ios --no-codesign` |

- Flutter 버전을 로컬과 동일하게 고정해 환경 차이로 인한 실패 방지
- 퍼블릭 레포라 macOS 러너 무료 사용
- 서명 없는 빌드라 실기기 설치는 불가. 실기기 검증은 Apple Developer Program 가입 후 TestFlight 경로 필요

### 맥 없이 iOS 개발할 때의 한계
- Xcode가 macOS 전용이라 Windows에선 iOS 빌드·서명 불가
- 아이폰이 있어도 맥이나 유료 개발자 계정 없이는 설치 불가 (무료 서명은 맥에 기기를 연결한 Xcode 설치만 지원)
- "크로스플랫폼"이어도 iOS 쪽은 플랫폼 설정과 빌드 환경이 별도로 필요함

---

## 개선 기록

### Flutter에서 개선해서 구현한 것
- [인증] 회원가입: 계정 생성 후 닉네임 설정이 실패해도 가입 성공으로 처리, 닉네임은 users 문서에 명시적으로 저장
- [인증] Google 로그인: 계정 선택 취소 시 에러 문구 없이 원래 상태로 복귀
- [인증] 로그아웃 시 Google 세션도 정리 (다음 로그인 때 이전 계정 자동 선택 방지)
- [홈] 로딩 성공 시 이전 에러 문구 초기화 (네이티브는 한 번 실패하면 이후 성공해도 에러 화면 유지)
- [홈] 목록이 있으면 새로고침 중에도 그리드 유지 (네이티브는 복귀할 때마다 스피너로 깜빡임)
- [홈] 에러 시 Firebase 원문 대신 고정 한글 문구 표시
- [그룹 생성] 이미지 업로드 후 문서 저장 실패 시 업로드한 이미지 삭제 (고아 파일 방지)
- [그룹 생성] 이름·설명 앞뒤 공백 제거 후 저장
- [그룹 생성] 오프라인이면 요청 전에 즉시 실패 처리 (무한 로딩·중복 생성 방지)
- [그룹 상세] 날짜 연타 시 이전 응답이 최신 화면을 덮어쓰지 않도록 이전 요청 취소
- [그룹 상세] 날짜 변경 즉시 이전 날짜 기록을 비우고 로딩 표시 (네이티브는 응답 전까지 이전 날짜 기록이 남음)
- [그룹 상세] 탈퇴 시 내 기록 일괄 삭제를 Batch로 처리
- [그룹 상세] 삭제 시 문서 먼저, 이미지 나중 (깨진 기록 방지)
- [그룹 상세] 삭제·탈퇴에 오프라인 사전 확인 적용
- [그룹 상세] 그룹 로딩 실패 시 Firebase 원문 대신 고정 한글 문구 표시
- [기록] 이미지 상태를 sealed class로 구분 (문자열 접두사 판별 제거)
- [기록] 하루 한 번 작성 규칙을 UseCase에서 재확인
- [기록] 당일 수정 규칙을 UseCase에서 확인
- [기록] 이미지 교체 시 문서 업데이트 성공 후 기존 이미지 삭제 (깨진 사진 방지)
- [기록] 작성 실패 시 업로드한 이미지 정리
- [기록] 작성·수정에 오프라인 사전 확인 적용, 입력값 trim
- [추출] 저장 이미지 해상도를 1080×1920으로 고정 (기기와 무관)
- [추출] 시스템 글자 크기와 무관하게 카드 레이아웃 고정
- [추출] 갤러리 저장을 Repository + UseCase로 분리 (UI → Data 의존 제거)
- [추출] 미기록 멤버 닉네임 조회를 병렬로 실행, 닉네임 말줄임 처리
- [마이페이지] 계정 삭제 흐름을 ViewModel → UseCase로 이동, 그룹 탈퇴는 기존 UseCase 재사용
- [마이페이지] Google 재인증 토큰 획득을 Data 레이어로 이동 (Activity 전달·UI → Data 의존 제거)
- [마이페이지] 재인증 실패 원인 구분 (오프라인을 비밀번호 오류로 안내하지 않음), Google 계정 선택 취소 시 문구 없음
- [마이페이지] users 문서 삭제에 오프라인 사전 확인 적용 (가입 그룹이 없을 때 무한 대기 방지)
- [마이페이지] 계정 삭제 후 Google 세션 정리

### Native 개선 후보
- [인증] 위 Flutter 인증 개선 3건 역적용
- [인증] 로그인 후 유저 저장을 ViewModel → UseCase로 이동
- [홈] 위 Flutter 홈 개선 3건 역적용
- [그룹 생성] 위 Flutter 그룹 생성 개선 3건 역적용
- [그룹 상세] 위 Flutter 그룹 상세 개선 6건 역적용 (날짜 연타는 `Job` 취소 또는 `collectLatest`로 대응 가능)
- [기록] 위 Flutter 기록 개선 6건 역적용 (이미지 상태는 Kotlin sealed interface로 동일하게 표현 가능)
- [추출] 위 Flutter 추출 개선 4건 역적용 (해상도 고정은 캡처한 Bitmap을 `createScaledBitmap`으로 리사이즈하거나 고정 크기 레이어에 그리는 방식으로 가능)
- [마이페이지] 위 Flutter 마이페이지 개선 5건 역적용 (Google 재인증은 Credential Manager의 Activity 요구 때문에 UI에서 토큰을 받아 넘기는 구조는 유지하되, 흐름 조립은 UseCase로 이동 가능)
- [전체] 로직 없는 단순 이동(Intent → SideEffect 경유)을 UI 콜백에서 직접 처리하는 방식 검토

## 검증 현황

### 완료 (Android 실기기)
- [인증] 회원가입 완료 SnackBar 표시
- [인증] Google 로그인 전체 흐름 (계정 선택 → 홈, 취소 시 문구 없음, 로그아웃 후 재로그인)
- [홈] 이미지 카드 그라데이션, 목록형 카드 썸네일
- [그룹 생성] 이미지 포함 생성 → Storage `groups/{문서ID}.jpg` 생성, 용량 감소
- [그룹 생성] 세로로 찍은 사진의 EXIF 회전 보정
- [기록] 사진 포함 작성 → Storage `records/{groupId}/` 업로드, 카드에 표시
- [기록] 수정에서 사진 제거 → Storage에서도 삭제
- [기록] 수정에서 사진 교체 → 새 사진 표시 (캐시로 옛날 사진이 남지 않음), 기존 파일 삭제
- [추출] 사진 포함 기록 추출 → 로딩 중 FAB 스피너, 1080×1920 저장, 사진 선명
- [마이페이지] Google 계정 삭제 (계정 선택 → 재인증 → 삭제, 선택 취소 시 문구 없음), 데이터 정리

### 완료 (iOS)
- GitHub Actions에서 서명 없는 빌드 검증

### 미완료
- [iOS] 실기기 동작 (TestFlight 필요): 사진 권한 팝업, Google 로그인 후 앱 복귀, 앨범 저장
- [네이티브] 비행기 모드에서 그룹 생성 시 동작 (코드 기준 추론: 이미지 없으면 무한 로딩, 이미지 있으면 최대 10분 후 실패)