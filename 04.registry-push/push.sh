#!/bin/sh
# Harbor 로 빌드 → tag → push 를 한 번에.  ACCOUNT 만 자기 계정으로 바꾼다.
set -e
ACCOUNT=${1:-skala-gj1}
REGISTRY=harbor.skala-gj.com
TAG=${2:-1.0.0}

docker build -t skala-webserver:$TAG .
docker tag  skala-webserver:$TAG $REGISTRY/$ACCOUNT/skala-webserver:$TAG
docker push $REGISTRY/$ACCOUNT/skala-webserver:$TAG

echo
echo "확인:  docker pull $REGISTRY/$ACCOUNT/skala-webserver:$TAG"
echo "실행:  docker run -d --name myweb -p 8081:80 $REGISTRY/$ACCOUNT/skala-webserver:$TAG"
