package com.skala.shop.api;

/** LoadController 의 스위치를 설정 클래스에서 읽기 위한 통로. */
public final class ReadinessSwitch {

    private ReadinessSwitch() {}

    public static boolean isReady() {
        return LoadController.READY.get();
    }

    public static void set(boolean ready) {
        LoadController.READY.set(ready);
    }
}
