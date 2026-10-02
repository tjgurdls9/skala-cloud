package com.skala.shop;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class OrderApiTest {

    @Autowired
    MockMvc mvc;

    @Test
    @DisplayName("주문을 만들면 201 과 함께 접수 상태로 돌아온다")
    void createOrder() throws Exception {
        mvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"item\":\"키보드\",\"quantity\":2}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.item").value("키보드"))
                .andExpect(jsonPath("$.status").value("ACCEPTED"));
    }

    @Test
    @DisplayName("수량이 0 이면 400 — 잘못된 요청은 저장 전에 걸러진다")
    void rejectInvalidQuantity() throws Exception {
        mvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"item\":\"마우스\",\"quantity\":0}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("없는 주문은 404 — 예외가 아니라 상태 코드로 답한다")
    void notFound() throws Exception {
        mvc.perform(get("/api/orders/999999")).andExpect(status().isNotFound());
        mvc.perform(delete("/api/orders/999999")).andExpect(status().isNotFound());
    }
}
