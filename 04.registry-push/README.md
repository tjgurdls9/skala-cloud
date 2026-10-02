# Registry Push 실습 (참고 코드)

본 강의 덱 `KDT Cloud_컨테이너 이해 및 앱 컨테이너화_2608.pptx` 의
**6. Registry Push 실습** (148~158 쪽) 에서 쓰는 파일들입니다.

| 파일 | 하는 일 |
| --- | --- |
| `index.html` | 내 계정과 이름이 찍히는 한 장짜리 페이지. **자기 계정·이름으로 고쳐서** 쓴다 |
| `Dockerfile` | `nginx:alpine` 에 `index.html` 한 장만 얹는다 |
| `push.sh` | 빌드 → tag → push 를 한 번에. `./push.sh skala-gj1 1.0.0` |
| `rehearsal-local.sh` | Harbor 없이 로컬 `registry:2` 로 같은 절차를 예행 연습한다 |

## 수업에서 하는 순서

```bash
# 0) index.html 의 <h2> 를 자기 계정 / 이름으로 고친다

# 1) 빌드하고 내 PC 에서 확인
docker build -t skala-webserver:1.0.0 .
docker run -d --name myweb -p 8081:80 skala-webserver:1.0.0
curl localhost:8081
docker rm -f myweb

# 2) 로그인 (계정은 반별로 배포. 1반 skala-gj1 ~ 4반 skala-gj4)
docker login harbor.skala-gj.com

# 3) 주소가 들어간 이름으로 tag 하고 push
docker tag  skala-webserver:1.0.0 harbor.skala-gj.com/skala-gj1/skala-webserver:1.0.0
docker push harbor.skala-gj.com/skala-gj1/skala-webserver:1.0.0
#   또는 ./push.sh skala-gj1 1.0.0

# 4) https://harbor.skala-gj.com 웹 콘솔에서 확인

# 5) 내 PC 의 이미지를 지우고 다시 받아 띄우기
docker rmi skala-webserver:1.0.0 harbor.skala-gj.com/skala-gj1/skala-webserver:1.0.0
docker pull harbor.skala-gj.com/skala-gj1/skala-webserver:1.0.0
docker run -d --name myweb -p 8081:80 harbor.skala-gj.com/skala-gj1/skala-webserver:1.0.0

# 6) index.html 한 줄만 고쳐 1.0.1 로 다시 push → 무엇이 달라지는가
```

## 슬라이드에 실린 출력은 어디서 나온 값인가

캠퍼스 Harbor 에 접속할 수 없는 환경에서 만들었기 때문에,
**로컬 `registry:2` 로 같은 절차를 그대로 돌려** 얻은 출력을 옮겼습니다
(`rehearsal-local.sh` 가 그 절차입니다). 호스트 이름만 `harbor.skala-gj.com` 으로 바꿔
적었고, push/pull 출력의 형식은 Harbor 도 같은 OCI Distribution API 라 동일합니다.

수업 전에 한 번 돌려 보면 명령과 출력을 그대로 재현할 수 있습니다.

```bash
./rehearsal-local.sh
```

검증한 것 (Apple Silicon / Docker Desktop 29.4.0):

- 첫 push : 레이어 **10 개 전부 `Pushed`**, 끝에 `digest: sha256:... size: 856`
- `index.html` 한 줄만 고쳐 두 번째 push : **8 개 `Layer already exists` · 2 개 `Pushed`**
- 이미지를 지운 뒤 `pull` → `run` → `curl localhost:8081` 로 페이지 확인까지 성공
- 레지스트리 주소를 빼고 push 하면 (슬라이드 158 쪽의 1 번 오류)

  ```
  The push refers to repository [docker.io/library/skala-webserver]
  push access denied, repository does not exist or may require authorization
  ```

> **IMAGE ID 와 digest 는 빌드할 때마다 달라집니다.** buildx 가 붙이는 provenance
> attestation 에 빌드 시각이 들어가기 때문입니다. 슬라이드에 적힌 값과 다르게 나오는 것이
> 정상이고, 학생마다 `index.html` 내용이 다르므로 어차피 서로 다릅니다.

## 로그인 정보가 어디에 남는가

`~/.docker/config.json` 을 열어 보면 됩니다.

- **Docker Desktop** : `"credsStore": "desktop"` 이고 `auths` 의 호스트 항목은 비어 있습니다.
  실제 값은 OS 키체인(macOS 키체인 / Windows 자격 증명 관리자)에 있습니다.
- **credsStore 가 없는 리눅스 서버** : `auths` 안에 `base64(아이디:비밀번호)` 가 그대로 들어갑니다.
  암호화가 아니라 인코딩이므로, 공용 서버에서 로그인했다면 반드시 `docker logout` 하고 나옵니다.

## 정리

```bash
docker rm -f myweb
docker rmi skala-webserver:1.0.0 harbor.skala-gj.com/skala-gj1/skala-webserver:1.0.0
docker logout harbor.skala-gj.com
```
