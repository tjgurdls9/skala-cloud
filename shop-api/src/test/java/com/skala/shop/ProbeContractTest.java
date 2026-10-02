package com.skala.shop;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalManagementPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.skala.shop.api.ReadinessSwitch;

/**
 * 프로브 계약을 검증한다 — 이 테스트가 지키는 것이 곧 무중단 배포의 전제다.
 *
 * <p>가장 중요한 것은 마지막 테스트다. readiness 를 내렸을 때 liveness 는
 * 여전히 UP 이어야 한다. 그렇지 않으면 의존성이 잠깐 흔들릴 때
 * 모든 Pod 가 동시에 재시작한다(5장 '재시작 폭풍').
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "management.server.port=0")
class ProbeContractTest {

    @Autowired
    TestRestTemplate rest;

    @LocalManagementPort
    int managementPort;

    @AfterEach
    void restoreReady() {
        ReadinessSwitch.set(true);
    }

    private ResponseEntity<String> probe(String path) {
        return rest.getForEntity("http://localhost:" + managementPort + path, String.class);
    }

    @Test
    @DisplayName("liveness 와 readiness 가 별도 경로로 노출된다")
    void probesExposed() {
        assertThat(probe("/actuator/health/liveness").getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(probe("/actuator/health/readiness").getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    @DisplayName("readiness 가 내려가도 liveness 는 UP 이다 — 재시작 폭풍을 막는 계약")
    void readinessDownDoesNotKillLiveness() {
        ReadinessSwitch.set(false);

        ResponseEntity<String> readiness = probe("/actuator/health/readiness");
        assertThat(readiness.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);

        ResponseEntity<String> liveness = probe("/actuator/health/liveness");
        assertThat(liveness.getStatusCode())
                .as("liveness 가 readiness 를 따라 내려가면 Pod 가 죽는다")
                .isEqualTo(HttpStatus.OK);
    }
}
