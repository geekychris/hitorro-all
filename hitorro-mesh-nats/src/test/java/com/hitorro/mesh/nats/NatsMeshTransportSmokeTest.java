/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.nats;

import com.hitorro.mesh.MeshTransport;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NatsMeshTransport requires a running NATS server; full integration lives
 * in the mesh-examples module (or a Testcontainers-based suite later).
 * Here we just verify the API surface + that {@link MeshTransport} is the
 * exported interface — regression guard against accidental API drift.
 */
class NatsMeshTransportSmokeTest {

    @Test
    void implementsMeshTransport() {
        assertThat(MeshTransport.class.isAssignableFrom(NatsMeshTransport.class)).isTrue();
    }
}
