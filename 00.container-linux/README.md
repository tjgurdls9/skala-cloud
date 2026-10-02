# 3 장 · 웹 서비스 실행 컨테이너 만들기 (참고 코드)

본 강의 덱 `KDT Cloud_컨테이너 이해 및 앱 컨테이너화_2608.pptx` 의
**3. 웹 서비스 실행 컨테이너 만들기** (34~49 쪽) 에서 쓰는 파일들입니다.

덱에 `webserver.py` 소스가 없어서 학생이 무엇을 띄우는지 알 수 없었습니다.
43 쪽 스크린샷(Welcome to Our Service · 8080 포트 · `/login`)에 맞춰 새로 작성했습니다.

| 파일 | 내용 |
| --- | --- |
| `webserver.py` | FastAPI 웹서버. `/`, `/login` 은 Welcome 페이지, `/healthz` 는 상태 JSON. 8080 포트 |
| `mycode.py` | 볼륨(`/mycode`) 동작을 확인하려고 넣어 두는 아주 작은 스크립트 |
| `v1.0/Dockerfile` | 껍데기 컨테이너. `CMD` 가 `sleep infinity` 라 아무 일도 안 한다 |
| `v1.1/Dockerfile` | `COPY webserver.py` 추가. 코드가 이미지에 들어간다 |
| `v1.2/Dockerfile` | `CMD ["python", "/mycode/webserver.py"]`. 실행하면 곧바로 서비스 |
| `run.sh` | 3 장의 세 단계를 순서대로 돌려 본다 |
| `inspect-image.sh` | **4 장** 「컨테이너 이미지 구조」의 명령을 순서대로 돌려 본다 |

```bash
./run.sh        # 첫 빌드에 20 초쯤, 그다음은 캐시가 살아 1 초 안쪽
```

## 세 단계가 무엇을 바꾸는가

| | v1.0 | v1.1 | v1.2 |
| --- | --- | --- | --- |
| webserver.py 위치 | 호스트 (`-v` 로 넣음) | 이미지 안 | 이미지 안 |
| 포트 | 열지 않음 | `-p 8888:8080` | `-p 8888:8080` |
| 누가 실행하나 | 사람이 `exec` 해서 | 사람이 `exec` 해서 | 컨테이너가 스스로 |
| `run` 직후 | 빈 껍데기 | 빈 껍데기 | 바로 서비스 |
| 재시작하면 | 직접 다시 띄운다 | 직접 다시 띄운다 | 알아서 돌아온다 |

## 실측값 (Apple Silicon / Docker Desktop 29.4.0)

`run.sh` 를 그대로 돌려 얻은 값이고, 슬라이드의 출력도 이것을 옮긴 것입니다.

```
=== v1.0
-- 컨테이너 안 /mydata 는 비어 있다        (아무것도 안 나옴)
-- 호스트에 webserver.py 를 넣으면          webserver.py
-- 컨테이너 안에서 curl                     {"status":"ok","host":"...","pid":18}
-- 호스트에서 curl (-p 를 안 줬다)          000

=== v1.1
-- 이미지 안에                              mycode.py  webserver.py
-- 아직 아무것도 안 떠 있다                  000
-- 손으로 띄운 뒤                            200
-- 컨테이너를 재시작하면                     000        <- 웹서버가 안 돌아온다

=== v1.2
-- exec 없이 바로                            200
-- 컨테이너 안 PID 1                         python /mycode/webserver.py
-- 재시작해도                                200
```

- 첫 빌드 약 **19 초**, 이미지 **411MB** (`psutil` 을 컴파일하느라 gcc 가 들어간다)
- v1.1 · v1.2 빌드는 캐시가 살아 **1 초 안쪽**
- v1.2 에서 웹서버가 **PID 1** 이다. 컨테이너의 수명이 곧 이 프로세스의 수명이다

## 자주 걸리는 곳

- **`uvicorn.run(..., host="0.0.0.0")` 이어야 한다.** `127.0.0.1` 로 두면 컨테이너 안에서는
  200 이 나오는데 호스트에서는 000 이다. 컨테이너의 localhost 는 컨테이너 안뿐입니다.
  (직접 바꿔서 확인했습니다: 컨테이너 안 200 / 호스트 000)
- **`EXPOSE` 는 길을 열지 않습니다.** 실제로 여는 것은 `docker run` 의 `-p` 입니다.
- 원본 덱에 있던 오류들 — `COPY webserver.py /mycocde/...` 오타, `CMD [“python”, ”...”]` 의
  스마트쿼트(이대로면 실행되지 않습니다), `–p` · `–it` 의 en-dash, 빌드는 `1.1` 인데 실행은
  `1.0` 이던 불일치 — 는 이번에 모두 고쳤습니다.

## 4 장에서 쓰는 것 — 이미지 구조 뜯어보기

`inspect-image.sh` 가 4 장(51~65 쪽)의 명령을 그대로 돌립니다. 슬라이드의 출력도 이것입니다.

```bash
./inspect-image.sh
```

실측값 (Apple Silicon / Docker Desktop 29.4.0):

| | |
| --- | --- |
| `docker images` 가 보여 주는 크기 | 411MB |
| `docker save` 로 나온 tar | **103MB** — 레이어가 `tar+gzip` 이라 파일은 더 작습니다 |
| 레이어 수 | 7 개 (mariadb:latest 는 8 개) |
| 맨 끝 레이어 | `mycode/mycode.py` 하나, 파일 크기 346 바이트 |
| `pip install` 레이어 | 항목 1901 개, 그중 **293 개가 `root/.cache/pip`** |
| `docker history` 상위 두 줄 | `apk add ...` 197MB + `pip install ...` 39MB = 236MB |
| v1.0 / v1.1 / v1.2 레이어 | 7 / 8 / 8 개, v1.1 과 v1.2 는 **완전히 동일** |

> `docker save` 는 지금 **OCI 레이아웃**으로 씁니다 — `index.json` · `manifest.json` ·
> `oci-layout` · `blobs/sha256/`. 예전처럼 `<sha>.tar` 가 나열되지 않습니다.
> 원본 덱에는 옛 형식이 실려 있어서 이번에 실측값으로 바꿨습니다.

> `pip install` 을 `--no-cache-dir` 없이 쓰면 pip 캐시가 이미지에 그대로 굳습니다.
> 우리 이미지에서는 293 개 항목이 그렇게 들어갔습니다.

## 정리

```bash
docker rm -f my-first-container
docker rmi container-linux:1.0 container-linux:1.1 container-linux:1.2
```
