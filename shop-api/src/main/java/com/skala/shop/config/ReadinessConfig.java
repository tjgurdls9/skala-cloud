package com.skala.shop.config;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.skala.shop.api.ReadinessSwitch;

/**
 * readiness 그룹에만 참여하는 헬스 인디케이터.
 *
 * <p>핵심은 이 인디케이터를 <b>readiness 그룹에만</b> 넣는다는 것이다
 * (application.yml 의 {@code management.endpoint.health.group.readiness.include}).
 * liveness 에 의존성 확인을 넣으면 5장에서 다룬 '재시작 폭풍'이 난다.
 */
@Configuration
public class ReadinessConfig {

    @Bean
    public HealthIndicator manualReadiness() {
        return () -> ReadinessSwitch.isReady()
                ? Health.up().withDetail("switch", "on").build()
                : Health.down().withDetail("switch", "off").build();
    }
}
