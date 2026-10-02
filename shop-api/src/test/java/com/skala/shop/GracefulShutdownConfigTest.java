package com.skala.shop;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.web.server.Shutdown;

/**
 * 12장에서 계산한 시간 예산이 실제 설정과 맞는지 검증한다.
 *
 * <p>preStop 5초 + Spring 종료 유예 25초 &lt; terminationGracePeriodSeconds 40초.
 * 이 부등식이 깨지면 앱이 정리를 마치기 전에 SIGKILL 을 맞는다.
 */
@SpringBootTest
class GracefulShutdownConfigTest {

    @Value("${server.shutdown}")
    Shutdown shutdown;

    @Value("${spring.lifecycle.timeout-per-shutdown-phase}")
    Duration shutdownPhase;

    /** k8s/ 매니페스트의 값. 바꿀 때는 매니페스트와 함께 바꿔야 한다. */
    static final Duration PRE_STOP = Duration.ofSeconds(5);
    static final Duration GRACE_PERIOD = Duration.ofSeconds(40);

    @Test
    @DisplayName("graceful 종료가 켜져 있다 — 없으면 처리 중이던 요청이 끊긴다")
    void gracefulEnabled() {
        assertThat(shutdown).isEqualTo(Shutdown.GRACEFUL);
    }

    @Test
    @DisplayName("preStop + 종료 유예 < grace period — 검산이 맞아야 SIGKILL 을 피한다")
    void shutdownBudgetFits() {
        Duration needed = PRE_STOP.plus(shutdownPhase);
        assertThat(needed)
                .as("preStop(%s) + 종료 유예(%s) 가 grace period(%s) 를 넘으면 강제 종료된다",
                        PRE_STOP, shutdownPhase, GRACE_PERIOD)
                .isLessThan(GRACE_PERIOD);
    }
}
