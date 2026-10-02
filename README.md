# skala-cloud

Docker 컨테이너부터 Kubernetes 배포까지 이어지는 SKALA 클라우드 실습입니다.

| 경로 | 내용 |
| --- | --- |
| `00.container-linux/` | 컨테이너·리눅스 기초, Python 웹서버 버전 실습 |
| `01.focused-labs/` | Node 앱, 3계층 구성, 이미지 경량화 |
| `02.kubernetes/`, `k8s_yaml1/` | Pod·Deployment·Service·Ingress YAML |
| `04.registry-push/` | 레지스트리 업로드와 로컬 리허설 |
| `05.compose/` | 웹·앱·DB Compose 구성 |
| `shop-api/` | Spring Boot 컨테이너 앱 |
| `skala-gj/` | 캠퍼스 클러스터용 실습 매니페스트 |
| `output/pdf/` | 직접 작성한 구현 검증 보고서 |

각 구현 폴더의 README를 따릅니다. Docker/Compose, Kubernetes 실습에는 접근 가능한 클러스터가 필요합니다. `shop-api 2`와 `k8s_yaml1 2`는 원본과 소스가 동일해 `.local-backup/`에 보존했습니다. 로컬 실행 이력·PDF 임시 렌더링·빌드 결과는 Git에서 제외합니다. YAML의 `__ME__` 등 실습 자리표시자는 실행 전에 자신의 환경에 맞춥니다.

강의 PDF·캠퍼스 안내·교재 기반 요약과 따라 하기 가이드는 로컬에 보존하고 업로드하지 않습니다.
