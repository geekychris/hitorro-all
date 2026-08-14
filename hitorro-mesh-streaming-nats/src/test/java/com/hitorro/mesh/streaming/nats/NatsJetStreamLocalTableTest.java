/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.streaming.nats;

import com.hitorro.mesh.agent.LocalTable;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class NatsJetStreamLocalTableTest {

    @Test
    void implementsLocalTable() {
        assertThat(LocalTable.class.isAssignableFrom(NatsJetStreamLocalTable.class)).isTrue();
    }

    @Test
    void implementsAutoCloseable() {
        assertThat(AutoCloseable.class.isAssignableFrom(NatsJetStreamLocalTable.class)).isTrue();
    }
}
