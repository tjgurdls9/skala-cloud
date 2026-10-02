# 2장: 멀티스테이지 — 빌드 환경이 최종 이미지에 남지 않는다 (약 700MB → 약 200MB)

# ── 1단계: 빌드 (JDK 필요) ──────────────────────────────────
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build

# 의존성을 먼저 받아 레이어 캐시를 살린다 — 소스가 바뀌어도 이 레이어는 재사용된다
COPY gradlew settings.gradle build.gradle ./
COPY gradle/ gradle/
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# 소스는 자주 바뀌므로 가장 아래에 둔다
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# ── 2단계: 실행 (JRE 만 있으면 된다) ─────────────────────────
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

# 14장: non-root 로 실행한다. runAsNonRoot: true 를 켜면 root 이미지는 실행이 거부된다
RUN addgroup --system --gid 10001 app \
 && adduser --system --uid 10001 --ingroup app app

COPY --from=builder /build/build/libs/*.jar app.jar
USER 10001

EXPOSE 8080 8081

# 2장: exec 형식이어야 SIGTERM 이 자바 프로세스에 직접 전달된다.
#      셸 형식으로 쓰면 graceful shutdown 이 동작하지 않는다.
# 2장: MaxRAMPercentage 는 컨테이너 limit 기준 비율이라
#      limit 을 바꿔도 이미지를 다시 빌드하지 않아도 된다.
ENTRYPOINT ["java", \
  "-XX:MaxRAMPercentage=75", \
  "-XX:+ExitOnOutOfMemoryError", \
  "-jar", "/app/app.jar"]
