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

### Native 개선 후보
- [인증] 위 Flutter 인증 개선 3건 역적용
- [인증] 로그인 후 유저 저장을 ViewModel → UseCase로 이동
- [홈] 위 Flutter 홈 개선 3건 역적용
- [그룹 생성] 위 Flutter 그룹 생성 개선 3건 역적용
- [전체] 로직 없는 단순 이동(Intent → SideEffect 경유)을 UI 콜백에서 직접 처리하는 방식 검토

## 검증 대기

### 실기기
- [인증] 회원가입 완료 SnackBar 표시
- [인증] Google 로그인 전체 흐름 (계정 선택 → 홈, 취소 시 문구 없음, 로그아웃 후 재로그인)
- [홈] 이미지 카드 그라데이션 표시
- [그룹 생성] 이미지 포함 생성 → Storage `groups/{문서ID}.jpg` 생성, 용량 감소 확인
- [그룹 생성] 세로로 찍은 사진의 EXIF 회전 보정

### 네이티브 동작 확인
- [그룹 생성] 비행기 모드에서 생성 시 동작 (코드 기준 추론: 이미지 없으면 무한 로딩, 이미지 있으면 최대 10분 후 실패)