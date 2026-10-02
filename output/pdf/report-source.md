# SKALA 컨테이너 실습 구현 검토 및 추진안

문서 성격: 권고 보고서 / 실행 전 PM 검토용
검토일: 2026-08-26
검토 대상: 01.focused-labs, 02.kubernetes, k8s_yaml1, shop-api

> 한 줄 결론: 9개 실습 전체를 학습 경로로 유지하되, 구현의 중심은 6-8번 3-tier 흐름으로 잡고 9번 이미지 경량화를 완료 조건으로 둔다. 5번 Harbor push/pull은 자격 증명과 외부 레지스트리 접근이 준비된 뒤 별도 실행한다.

---

# 01 협의 결과와 권고 범위

PM이 우선순위와 최종 승인권을 갖고, 구현·검증 역할을 분리한다.

| 역할 | 담당 | 책임 |
| --- | --- | --- |
| PM / 의사결정 | 사용자 | 범위, 우선순위, 변경 승인, 운영 전환 여부 결정 |
| 구현 리드 | Codex | 현재 산출물 점검, 구현안 정리, 승인된 변경 수행 |
| 검증 / 리뷰 | 독립 검토 관점 | 명령 결과, 재현성, 보안 노출, 잔여 위험 확인 |

## 권고 범위

- 포함: 집중실습 1-9의 실행 순서, 현재 코드·Compose·Kubernetes 매니페스트 검토, 정적 검증 결과, 다음 구현 후보
- 핵심 경로: 6번 수동 3-tier -> 7번 Compose -> 8번 scale/장애 확인
- 완료 기준 후보: 9번 v1-v4 이미지 비교 및 /healthz 동작 확인
- 조건부: 5번 Harbor는 계정·네트워크가 준비될 때만 push/pull 수행
- 이번 산출물에서 제외: 기존 애플리케이션 코드의 임의 수정, 실계정 로그인, 외부 클러스터 배포

이번 검토는 구현 권고를 제시하는 단계다. 실제 코드 변경이나 Harbor/Kubernetes 배포는 PM의 별도 승인 후 실행한다.

---

# 02 현재 상태 인벤토리

파일의 존재와 구성은 확인했지만, 컨테이너 실행 결과는 환경 제약으로 재현하지 못했다.

| 영역 | 확인된 구성 | 판정 |
| --- | --- | --- |
| 기초 Docker | 00.container-linux의 v1.0-v1.2, 이미지 조사 스크립트 | 실습 재료 있음 |
| 집중실습 1-4 | hello-world, Nginx, Node Dockerfile, MariaDB 볼륨 안내 | 실행 순서 있음 |
| 3-tier 6-8 | MariaDB init SQL, Node WAS, Nginx, compose.yaml | 핵심 경로 준비 |
| Registry 5 | Harbor push 스크립트와 local registry 예행연습 | 외부 의존 |
| 이미지 다이어트 9 | Dockerfile, v2, v3, v4와 Express healthz | 비교 재료 있음 |
| Kubernetes 보강 | Pod/Probe/Deployment/Job/Service/Ingress 매니페스트 | 다음 단계 준비 |
| shop-api | Spring Boot, multi-stage Dockerfile, 주문 API, probe/graceful 테스트 | 검증 대상 있음 |

## 중요 관찰

- 6.3tier Compose는 db healthcheck와 service_healthy 조건을 사용하며, db는 named volume을 사용한다.
- WAS는 DB_HOST=db, Web은 was:8080으로 연결되어 Compose 서비스명 기반 네트워크를 보여 준다.
- 09.image-diet의 v3는 운영 의존성만 설치하고 package 파일을 먼저 복사한다. v4는 멀티 스테이지지만 현재 앱에는 별도 빌드 산출물이 없어 v3 대비 효과를 실측해야 한다.
- shop-api는 liveness/readiness 분리, graceful shutdown, non-root 실행 등 Kubernetes 확장 학습에 필요한 재료가 있다.

---

# 03 권고 구현 순서

실습 간 의존성과 실패 원인을 분리하면 학습·검증·보고가 한 흐름으로 이어진다.

| 단계 | 실행 | 성공 증거 |
| --- | --- | --- |
| 1. 기초 | 실습 1-4. 기존 컨테이너와 3306 포트를 건드리지 않고 별도 이름·3307 포트 사용 | docker ps -a, curl, 재생성 후 DB 데이터 잔존 |
| 2. 3-tier | 실습 6. db -> was -> nginx 순서로 수동 연결 | /users 응답, 각 컨테이너 로그, 네트워크 연결 |
| 3. 재현화 | 실습 7. compose up/down으로 같은 구성을 코드 한 파일로 실행 | compose ps, /users, down 후 정리 |
| 4. 장애 | 실습 8. was를 3개로 scale하고 /whoami 분산·중지 후 동작 확인 | 응답 hostname 분산, 장애 시 proxy 결과 |
| 5. 최적화 | 실습 9. v1-v4 빌드·size·history·healthz 비교 | 이미지 크기 표, history, /healthz 200 |

---

# 04 검증 결과

정적·구성 검증은 verification-evidence.txt에 명령과 실제 출력으로 보존했다. PASS는 정적 검증에만 해당한다.

| 검증 항목 | 명령 / 대상 | 결과 |
| --- | --- | --- |
| Compose 구성 | docker compose ... config | PASS - 서비스 3개, named volume, healthcheck 확인 |
| Kubernetes YAML | Ruby YAML parser로 7개 매니페스트 파싱 | PASS - 구문 파싱 성공 |
| JavaScript | node --check: Node app, WAS, image-diet server | PASS - 3개 파일 |
| Python | python3 -m py_compile: container/compose 소스 | PASS - 문법 확인 |
| Shell | sh -n: push.sh, rehearsal-local.sh | PASS - 2개 파일 |
| Docker daemon | docker ps -a / docker images | BLOCKED - Docker socket 권한 거부 |
| Spring tests | ./gradlew test --no-daemon | BLOCKED - Gradle 배포판 다운로드 시 DNS 실패 |

구성 파일 자체는 다음 단계로 진행할 수 있는 수준이다. 그러나 Compose up, 실제 HTTP 응답, 이미지 크기, WAS scale, Kubernetes rollout과 같은 런타임 주장은 아직 이 실행 환경에서 재현되지 않았다.

재실행 체크리스트: docker version, docker ps -a, docker compose -f 01.focused-labs/06.3tier/compose.yaml up -d, curl -s localhost/users, docker compose -f 01.focused-labs/06.3tier/compose.yaml down

---

# 05 구현 시 반영할 핵심 판단

| 우선 | 판단 | 권고 |
| --- | --- | --- |
| 높음 | 3-tier 시작 순서는 좋지만 Web이 WAS의 healthy 상태를 기다리지 않는다. | WAS healthcheck를 추가하고 web depends_on을 service_healthy로 바꿀지 승인 후 검토 |
| 높음 | Compose/WAS 소스에 실습용 DB 비밀번호가 평문으로 있다. | 교육용 로컬 범위로 한정하고, 공유·운영 전환 시 .env/Secret 등 외부 주입으로 변경 |
| 높음 | 환경 안내 PDF에 계정·자격 증명 정보가 포함되어 있다. | 보고서에는 포함하지 않으며, 외부 배포 금지와 필요 시 자격 증명 회전 검토 |
| 중간 | image-diet v4는 현재 Node 앱에 별도 빌드 산출물이 없다. | v3와 v4의 실제 크기·레이어 수를 측정해 멀티스테이지 효과를 수치로 판정 |
| 중간 | WAS package.json에 lockfile이 보이지 않는다. | 재현 가능한 빌드가 필요하면 package-lock.json과 npm ci 도입을 별도 승인 |
| 중간 | K8s Ingress에 student-01 같은 환경별 placeholder가 있다. | 배포 전 namespace, group.name, host, image tag를 반별 값으로 치환하고 diff 확인 |

이번 단계에서는 소스 수정 대신 실행·검증 순서와 acceptance evidence를 고정한다. healthcheck, Secret 주입, lockfile, placeholder 치환은 각각 별도 작은 변경으로 승인한다.

---

# 06 리스크와 완료 기준

## 주요 리스크

- 포트 충돌: 기존 MariaDB 3306과 web 80을 사용하므로 실행 전 포트 점유를 확인한다.
- Harbor 의존성: login, 권한, 프로젝트명, 레지스트리 접근이 모두 필요하다. 자격 증명을 파일·채팅에 저장하지 않는다.
- 데이터 휘발: 3-tier/Compose named volume의 생명주기와 down -v의 차이를 실습자가 구분해야 한다.
- 장애 해석: WAS 3개를 띄우는 것과 자동 무중단은 다르므로, 분산과 장애 전환을 별도 증거로 남긴다.
- 수치 과장: 이미지 목표 크기는 기존 측정값이 아니라 현재 환경에서 다시 측정한 값으로 기록한다.

## 권고 acceptance criteria

| ID | 기준 | 증거 |
| --- | --- | --- |
| A1 | 기초 실습 1-4가 기존 컨테이너와 충돌 없이 완료 | 명령 출력과 포트·볼륨 확인 |
| A2 | 3-tier에서 DB 조회가 Web 경유로 성공 | curl /users 및 compose ps |
| A3 | Compose로 재기동해도 초기화·연결 동작을 설명 가능 | up/down, volume 상태, 로그 |
| A4 | WAS replica 분산과 1개 중지 후 동작을 구분해 확인 | /whoami hostname 집계, 장애 요청 결과 |
| A5 | v1-v4 이미지와 실행 결과를 수치로 비교 | docker images/history, /healthz |
| A6 | Harbor push/pull은 계정 준비 후에만 수행 | digest, pull 후 run, logout 확인 |

---

# 07 최종 결론 및 다음 승인 요청

권고 결론: 1-9 전체는 교육 범위로 보존한다. 실제 구현 순서는 1-4 기초 확인 -> 6-8 3-tier 통합 -> 9 이미지 경량화 -> 5 Harbor 조건부 -> Kubernetes 보강으로 확정한다.

## PM 결정 항목

| 결정 | 선택지 | 권고 기본값 |
| --- | --- | --- |
| 실행 범위 | 1-9 전체 / 6-9 집중 | 1-9 전체를 보존하고 6-9를 핵심 검증 |
| 코드 수정 | 보고서만 / healthcheck 등 작은 변경 포함 | 이번에는 보고서만, 후속 변경을 별도 승인 |
| 외부 배포 | Harbor·K8s 실행 / 로컬 검증만 | 자격 증명과 환경 확인 전까지 로컬 검증 |

## 재현성 산출물

- report-source.md: 보고서의 내용과 권고안 원문
- build_report.swift: Apple Core Graphics/Core Text 기반 PDF 생성기. AppleSDGothicNeo-Regular 한글 폰트를 사용한다.
- verify_static.sh: 승인된 정적 검증 명령을 실행하는 재현 스크립트
- verification-evidence.txt: 2026-08-26 실행 시각, 명령, 실제 출력과 종료 코드

보안 메모: 환경 안내 PDF에 포함된 계정·자격 증명은 본 보고서와 검증 증거에 재기록하지 않았다. 보고서 배포 전 원본 자료의 접근 범위도 별도로 점검해야 한다.

