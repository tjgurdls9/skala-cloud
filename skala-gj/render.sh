#!/bin/bash
# 매니페스트의 자리표시자를 채워 표준출력으로 낸다. 적용은 파이프로 직접 한다.
#
#   export ME=G000
#   ./render.sh l07-pod.yaml | kubectl apply -f -
#   ./render.sh l07-pod.yaml | kubectl delete -f -
#
# 적용까지 하지 않는 이유: 무엇이 클러스터에 들어가는지 눈으로 본 뒤 적용하는 습관이
# 공유 네임스페이스에서는 특히 중요하다. 렌더 결과를 먼저 읽자.
#
# envsubst 는 맥 기본 설치가 아니라 sed 를 쓴다.
set -euo pipefail

: "${ME:?export ME=<자기 식별자>  를 먼저 실행하세요 (예: export ME=kim01)}"

NS="${NS:-$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)}"
: "${NS:?네임스페이스를 찾지 못했습니다. kubectl config set-context --current --namespace=skala-gj1}"

# 레지스트리 프로젝트 이름은 네임스페이스와 같다 (skala-gjN)
REG="${REG:-harbor.skala-gj.com/${NS}}"
TAG="${TAG:-1.0.0}"

for f in "$@"; do
    sed -e "s|__ME__|${ME}|g" \
        -e "s|__NS__|${NS}|g" \
        -e "s|__REG__|${REG}|g" \
        -e "s|__TAG__|${TAG}|g" "$f"
    echo "---"
done
