# 헬품타 Native(Compose) vs Flutter 비교 기록

## 비교 환경
- Native: Kotlin, Jetpack Compose, Clean Architecture + MVI, Hilt
- Flutter: Flutter 3.47.5 / Dart 3.13.4, Clean Architecture + Bloc
- 테스트 기기: Android 실기기 (iOS는 CI 빌드 검증까지만)

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
| 라이브러리 | Navigation Compose | go_router |
| 경로 정의 | `composable("group/{groupId}")` | `GoRoute(path: '/group/:groupId')` |
| 인자 수신 | `backStackEntry.arguments` | `state.pathParameters` |
| 스택 쌓기 | `navigate()` | `context.push()` |
| 스택 교체 | `navigate()` + `popUpTo(inclusive = true)` | `context.go()` |

- go_router는 라우트 선언 순서대로 매칭 → `/group/create`를 `/group/:groupId`보다 먼저 선언해야 함
- 스택 교체가 `go()` 한 번으로 끝나 로그인 → 홈 같은 흐름이 더 간결

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
| DI | Hilt 자동 주입 | `RepositoryProvider` + 라우트에서 수동 조립 |
| 로그인 상태 분기 | (시작 시 currentUser 확인) | go_router `redirect` |

### SideEffect
- Native: `SharedFlow`로 별도 전달 → `LaunchedEffect`에서 수집
- Flutter: Bloc에 전용 통로 없음 → State에 완료 플래그(`isLoggedIn`, `isSignedUp`) + `BlocListener`의 `listenWhen`으로 전환 시점에만 반응
- 인증 화면은 성공 시 화면을 떠나서 중복 실행 문제 없음. 같은 화면에 머무는 반복 효과는 별도 설계 필요

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

### Google 로그인
| 항목 | Native | Flutter |
|---|---|---|
| 라이브러리 | Credential Manager + googleid | google_sign_in 7.x |
| Activity 전달 | Intent에 Activity 실어서 ViewModel까지 전달 (예외 허용) | 불필요 — 플러그인 내부 처리 |
| 웹 클라이언트 ID | BuildConfig에 직접 설정 | google-services.json(client_type: 3)에서 자동 로드 |
| 계정 선택 흐름 | One Tap 실패 시 SignInWithGoogle로 재시도 직접 구현 | authenticate() 한 번으로 플러그인이 처리 |
| 초기화 | 없음 | authenticate() 전 initialize() 필수 |

- 코드량은 크게 줄었지만 계정 선택 흐름을 세부적으로 제어할 수 없음
- Dart는 모든 클래스가 암묵적 인터페이스 → 일반 클래스도 `implements`로 테스트 대역 생성 가능

---

## 공통 개선 후보 (Native / Flutter 양쪽)
- [인증] 회원가입: 계정 생성 후 닉네임 설정 실패 시 실패 반환 → 재시도하면 "이미 사용 중인 이메일"
- [인증] Google 로그인: 계정 선택 취소 시에도 에러 문구 표시 (취소 메시지가 ViewModel에서 덮어써짐)

## 실기기 검증 대기
- [인증] 회원가입 완료 SnackBar 표시
- [인증] Google 로그인 전체 흐름