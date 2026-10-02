#!/bin/sh
# 4 장 「컨테이너 이미지 구조」의 명령을 순서대로 돌려 본다.
# 슬라이드에 실린 출력은 이 스크립트를 돌려 얻은 것이다.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${1:-$HERE/work-image}
IMG=container-linux:1.0

rm -rf "$WORK" && mkdir -p "$WORK/container-image"
cd "$WORK/container-image"

echo "=== 1) 이미지를 파일 하나로 뽑는다"
docker save $IMG -o linux.tar
ls -lh linux.tar | awk '{print $5, $9}'

echo "=== 2) 풀기 전에 목록만"
tar tf linux.tar | head -3

echo "=== 3) 풀면"
tar xf linux.tar && rm linux.tar && ls

echo "=== 4) manifest.json"
cat manifest.json | jq

echo "=== 5) 레이어별 파일 크기 (오래된 것부터)"
i=1
for l in $(jq -r '.[0].Layers[]' manifest.json); do
  printf 'layer %d  %8s  %s\n' $i "$(ls -lh $l | awk '{print $5}')" "$(tar tf $l 2>/dev/null | head -1)"
  i=$((i+1))
done

echo "=== 6) 맨 끝 레이어 = 내가 COPY 한 것"
LAST=$(jq -r '.[0].Layers[-1]' manifest.json)
tar tvf $LAST

echo "=== 7) pip install 이 만든 레이어"
L6=$(jq -r '.[0].Layers[5]' manifest.json)
echo "  전체 항목 $(tar tf $L6 | wc -l | tr -d ' ') 개"
echo "  그중 pip 캐시 $(tar tf $L6 | grep -c 'root/.cache/pip') 개   <- --no-cache-dir 로 막을 수 있다"

echo "=== 8) docker history — 레이어를 Dockerfile 줄로 보기"
docker history $IMG --format 'table {{.Size}}\t{{.CreatedBy}}' --no-trunc | cut -c1-100

echo "=== 9) 레이어는 이미지끼리 공유된다"
for v in 1.0 1.1 1.2; do
  printf 'v%s  ' $v
  docker inspect container-linux:$v --format '{{range .RootFS.Layers}}{{println .}}{{end}}' \
    | sed 's/sha256://' | cut -c1-12 | tr '\n' ' '
  echo
done

echo
echo "정리: rm -rf $WORK"
