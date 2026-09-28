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