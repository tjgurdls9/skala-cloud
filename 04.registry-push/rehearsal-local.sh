#!/bin/sh
# Harbor 없이 로컬 registry:2 로 같은 절차를 예행 연습한다.
# 강의 전에 명령과 출력을 그대로 재현해 보고 싶을 때 쓴다.
set -e
PORT=5005                       # macOS 는 5000 번을 AirPlay 가 쓰는 경우가 많다
REG=localhost:$PORT

docker rm -f localreg myweb >/dev/null 2>&1 || true
docker run -d --name localreg -p $PORT:5000 registry:2 >/dev/null
sleep 3

docker build -t skala-webserver:1.0.0 .
docker tag  skala-webserver:1.0.0 $REG/skala-gj1/skala-webserver:1.0.0
echo "=== push"
docker push $REG/skala-gj1/skala-webserver:1.0.0 2>&1 | tr '\r' '\n' | grep -v -E 'Waiting|Preparing|Pushing'

echo "=== 레지스트리에 무엇이 있나"
curl -s $REG/v2/_catalog; echo
curl -s $REG/v2/skala-gj1/skala-webserver/tags/list; echo

echo "=== 지우고 다시 받아 띄우기"
docker rmi skala-webserver:1.0.0 $REG/skala-gj1/skala-webserver:1.0.0 >/dev/null
docker pull $REG/skala-gj1/skala-webserver:1.0.0 2>&1 | tail -3
docker run -d --name myweb -p 8081:80 $REG/skala-gj1/skala-webserver:1.0.0 >/dev/null
sleep 2
curl -s localhost:8081 | grep h2

echo "=== 정리"
docker rm -f myweb localreg >/dev/null
docker rmi $REG/skala-gj1/skala-webserver:1.0.0 >/dev/null 2>&1 || true
echo done
