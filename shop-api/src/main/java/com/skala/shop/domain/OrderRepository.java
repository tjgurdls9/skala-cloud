package com.skala.shop.domain;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Repository;

/**
 * 인메모리 저장소.
 *
 * <p>Pod 가 재시작하면 내용이 사라진다. 이것은 결함이 아니라 실습 재료다 —
 * 5장에서 Pod 를 지워 보고, 10장에서 "그래서 상태를 어디에 둘 것인가"를 다룬다.
 */
@Repository
public class OrderRepository {

    private final ConcurrentHashMap<Long, Order> store = new ConcurrentHashMap<>();
    private final AtomicLong seq = new AtomicLong();

    public Order save(String item, int quantity) {
        long id = seq.incrementAndGet();
        Order order = new Order(id, item, quantity, "ACCEPTED");
        store.put(id, order);
        return order;
    }

    public Optional<Order> findById(Long id) {
        return Optional.ofNullable(store.get(id));
    }

    public List<Order> findAll() {
        return List.copyOf(store.values());
    }

    public boolean deleteById(Long id) {
        return store.remove(id) != null;
    }

    public int count() {
        return store.size();
    }

    Collection<Order> raw() {
        return store.values();
    }
}
