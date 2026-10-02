#!/bin/sh
set +e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
OUT="$ROOT/output/pdf/verification-evidence.txt"
PYTHONPYCACHEPREFIX=/tmp/skala-report-pycache

{
  echo "SKALA report verification evidence"
  echo "timestamp=$(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "worktree=$ROOT"
  echo

  echo "[tool versions]"
  docker --version 2>&1; echo "exit=$?"
  docker compose version 2>&1; echo "exit=$?"
  node --version 2>&1; echo "exit=$?"
  ruby --version 2>&1; echo "exit=$?"
  python3 --version 2>&1; echo "exit=$?"
  echo

  echo "[compose config]"
  echo '$ docker compose -f 01.focused-labs/06.3tier/compose.yaml config'
  docker compose -f "$ROOT/01.focused-labs/06.3tier/compose.yaml" config 2>&1
  echo "exit=$?"
  echo

  echo "[kubernetes yaml parse]"
  echo '$ ruby -e YAML.load_stream'
  ruby -e 'require "yaml"; ARGV.each{|p| YAML.load_stream(File.read(p)); puts "#{p}: YAML parse OK"}' \
    "$ROOT/02.kubernetes/skala-webserver.yaml" \
    "$ROOT/k8s_yaml1/ch05-pod/pod.yaml" \
    "$ROOT/k8s_yaml1/ch05-pod/pod-with-probes.yaml" \
    "$ROOT/k8s_yaml1/ch06-deployment/deployment.yaml" \
    "$ROOT/k8s_yaml1/ch06-deployment/job-migration.yaml" \
    "$ROOT/k8s_yaml1/ch07-service/service.yaml" \
    "$ROOT/k8s_yaml1/ch08-ingress/ingress.yaml" 2>&1
  echo "exit=$?"
  echo

  echo "[javascript syntax]"
  for f in \
    "$ROOT/01.focused-labs/03.node-app/app.js" \
    "$ROOT/01.focused-labs/06.3tier/was/app.js" \
    "$ROOT/01.focused-labs/09.image-diet/server.js"; do
    node --check "$f" 2>&1
    rc=$?
    echo "$f: exit=$rc"
  done
  echo

  echo "[python syntax]"
  PYTHONPYCACHEPREFIX="$PYTHONPYCACHEPREFIX" python3 -m py_compile \
    "$ROOT/00.container-linux/mycode.py" \
    "$ROOT/00.container-linux/webserver.py" \
    "$ROOT/00.container-linux/mydata/webserver.py" \
    "$ROOT/00.container-linux/v1.0/mycode.py" \
    "$ROOT/00.container-linux/v1.1/mycode.py" \
    "$ROOT/00.container-linux/v1.1/webserver.py" \
    "$ROOT/00.container-linux/v1.2/mycode.py" \
    "$ROOT/00.container-linux/v1.2/webserver.py" \
    "$ROOT/05.compose/app/webserver.py" 2>&1
  echo "exit=$?"
  echo

  echo "[shell syntax]"
  sh -n "$ROOT/04.registry-push/push.sh" 2>&1; echo "push.sh exit=$?"
  sh -n "$ROOT/04.registry-push/rehearsal-local.sh" 2>&1; echo "rehearsal-local.sh exit=$?"
  echo

  echo "[docker runtime availability]"
  echo '$ docker ps -a'
  docker ps -a 2>&1
  echo "exit=$?"
  echo '$ docker images'
  docker images 2>&1
  echo "exit=$?"
  echo

  echo "[spring tests]"
  echo '$ GRADLE_USER_HOME=/tmp/skala-gradle-cache ./gradlew test --no-daemon'
  (cd "$ROOT/shop-api" && GRADLE_USER_HOME=/tmp/skala-gradle-cache ./gradlew test --no-daemon) 2>&1
  echo "exit=$?"
} > "$OUT"

# Compose config prints environment values. Keep the evidence useful without
# retaining lab credentials in the report artifact.
sed -E \
  -e 's/(MYSQL_(ROOT_)?PASSWORD: ).*/\1[REDACTED]/g' \
  -e 's/(password: ).*/\1[REDACTED]/g' \
  "$OUT" > "$OUT.redacted"
mv "$OUT.redacted" "$OUT"

echo "$OUT"
