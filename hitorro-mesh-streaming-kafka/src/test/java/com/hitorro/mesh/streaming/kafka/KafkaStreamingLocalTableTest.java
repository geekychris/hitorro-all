/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.streaming.kafka;

import com.hitorro.mesh.agent.LocalTable;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Adapter smoke test. Full integration (real broker, produce records, verify
 * mesh scan yields them) lives in {@code hitorro-mesh-examples} or a
 * Testcontainers-backed suite — too heavy for the default unit runs.
 * These pin the public surface so a rename or signature change fails loudly.
 */
class KafkaStreamingLocalTableTest {

    @Test
    void implementsLocalTable() {
        assertThat(LocalTable.class.isAssignableFrom(KafkaStreamingLocalTable.class)).isTrue();
    }

    @Test
    void implementsAutoCloseable() {
        assertThat(AutoCloseable.class.isAssignableFrom(KafkaStreamingLocalTable.class)).isTrue();
    }
}
