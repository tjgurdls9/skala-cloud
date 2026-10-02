#!/bin/sh
# 3 장의 세 단계를 순서대로 돌려 본다.  수업에서는 한 단계씩 직접 치는 편이 낫다.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
# 연결이 거절되면 curl 이 0 이 아닌 값으로 끝난다.  set -e 에 걸리지 않게 || true 를 붙인다
code() { curl -s -m 5 -o /dev/null -w '%{http_code}' localhost:8888/healthz || true; echo; }

docker rm -f my-first-container >/dev/null 2>&1 || true
rm -rf "$HERE/work" && mkdir -p "$HERE/work/mydata"

echo "=== v1.0  껍데기 컨테이너 + 볼륨으로 코드 넣기"
(cd "$HERE/v1.0" && docker build -q -t container-linux:1.0 . >/dev/null)
docker run -d -v "$HERE/work/mydata":/mydata --name my-first-container container-linux:1.0 >/dev/null
sleep 2
echo "-- 컨테이너 안 /mydata 는 비어 있다"
docker exec my-first-container ls /mydata
cp "$HERE/webserver.py" "$HERE/work/mydata/"
echo "-- 호스트에 넣으면 컨테이너에서 바로 보인다"
docker exec my-first-container ls /mydata
docker exec -d my-first-container sh -c 'python /mydata/webserver.py'
sleep 4
printf "%s" "-- 컨테이너 안에서 curl : "
docker exec my-first-container curl -s localhost:8080/healthz; echo
printf "%s" "-- 호스트에서 curl (-p 를 안 줬다) : "; code

echo
echo "=== v1.1  코드를 이미지 안으로 + 포트 열기"
docker rm -f my-first-container >/dev/null
(cd "$HERE/v1.1" && docker build -q -t container-linux:1.1 . >/dev/null)
docker run -d --name my-first-container -p 8888:8080 container-linux:1.1 >/dev/null
sleep 2
docker exec my-first-container ls /mycode
printf "%s" "-- 아직 아무것도 안 떠 있다 : "; code
docker exec -d my-first-container sh -c 'python /mycode/webserver.py'
sleep 4
printf "%s" "-- 손으로 띄운 뒤 : "; code
docker restart my-first-container >/dev/null; sleep 3
printf "%s" "-- 컨테이너를 재시작하면 : "; code

echo
echo "=== v1.2  실행하면 곧바로 웹서버"
docker rm -f my-first-container >/dev/null
(cd "$HERE/v1.2" && docker build -q -t container-linux:1.2 . >/dev/null)
docker run -d --name my-first-container -p 8888:8080 container-linux:1.2 >/dev/null
sleep 4
printf "%s" "-- exec 없이 바로 : "; code
docker exec my-first-container sh -c 'ps -o pid,args | head -2'
docker restart my-first-container >/dev/null; sleep 4
printf "%s" "-- 재시작해도 : "; code

echo
echo "정리: docker rm -f my-first-container && docker rmi container-linux:1.0 container-linux:1.1 container-linux:1.2"
