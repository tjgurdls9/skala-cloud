package com.skala.shop.api;

import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 11장 HPA 실습용 부하 생성기.
 *
 * <p>{@code /api/load} 는 CPU 를 실제로 쓴다. HPA 가 지표를 보고 Pod 를 늘리는
 * 과정을 눈으로 확인하기 위한 것이다.
 *
 * <p>{@code /api/unready} 는 readinessProbe 만 실패시킨다. 5장에서 배운
 * "readiness 는 트래픽을 끊고 liveness 는 컨테이너를 죽인다"를 실제로 확인할 때 쓴다.
 */
@RestController
public class LoadController {

    /** readinessProbe 가 이 값을 본다. 12장 ReadinessConfig 참고. */
    static final AtomicBoolean READY = new AtomicBoolean(true);

    @GetMapping("/api/load")
    public Map<String, Object> load(@RequestParam(defaultValue = "200") int millis) {
        long budget = Math.min(millis, 5_000L);      // 실습용 상한
        long end = System.nanoTime() + budget * 1_000_000L;
        long spins = 0;
        double sink = 0;
        while (System.nanoTime() < end) {
            sink += Math.sqrt(spins++ % 10_000 + 1.0);
        }
        return Map.of("burnedMillis", budget, "spins", spins, "checksum", (long) sink);
    }

    @PostMapping("/api/unready")
    public ResponseEntity<Map<String, Object>> toggleReady(
            @RequestParam(defaultValue = "false") boolean ready) {
        READY.set(ready);
        return ResponseEntity.ok(Map.of("ready", READY.get()));
    }
}
