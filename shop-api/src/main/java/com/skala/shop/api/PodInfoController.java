package com.skala.shop.api;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.skala.shop.domain.OrderRepository;

/**
 * 어느 Pod 가 응답했는지 보여 준다.
 *
 * <p>7장 부하 분산 실습에서 이 엔드포인트를 반복 호출하면 응답이 여러 Pod 로
 * 나뉘는 것이 눈에 보인다. 값은 5장 Downward API 로 주입된다.
 */
@RestController
public class PodInfoController {

    private final Instant startedAt = Instant.now();
    private final OrderRepository orders;

    @Value("${POD_NAME:local}")
    private String podName;

    @Value("${NODE_NAME:local}")
    private String nodeName;

    @Value("${POD_IP:127.0.0.1}")
    private String podIp;

    @Value("${spring.profiles.active:default}")
    private String profile;

    @Value("${app.greeting:안녕하세요}")
    private String greeting;

    public PodInfoController(OrderRepository orders) {
        this.orders = orders;
    }

    @GetMapping("/api/info")
    public Map<String, Object> info() {
        return Map.of(
                "pod", podName,
                "node", nodeName,
                "podIp", podIp,
                "profile", profile,
                "greeting", greeting,
                "uptimeSeconds", Duration.between(startedAt, Instant.now()).toSeconds(),
                "orderCount", orders.count());
    }
}
