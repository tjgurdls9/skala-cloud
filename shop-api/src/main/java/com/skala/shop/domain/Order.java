package com.skala.shop.domain;

/** 주문 하나. 실습용이라 저장소는 메모리다 — 10장에서 이 선택의 의미를 다룬다. */
public record Order(Long id, String item, int quantity, String status) {

    public Order withStatus(String newStatus) {
        return new Order(id, item, quantity, newStatus);
    }
}
