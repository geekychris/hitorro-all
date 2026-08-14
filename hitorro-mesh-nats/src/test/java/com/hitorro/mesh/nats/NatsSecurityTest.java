/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.nats;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifies the {@link NatsSecurity} config-object shape and its custom
 * {@link javax.net.ssl.SSLContext} construction. Live NATS connectivity
 * is covered by the smoke test — this class stays offline.
 */
class NatsSecurityTest {

    @Test
    void emptySecurity_requiresNoTls_hasNoCustomMaterial() {
        NatsSecurity sec = NatsSecurity.none();
        assertThat(sec.isEmpty()).isTrue();
        assertThat(sec.requiresTls()).isFalse();
        assertThat(sec.hasCustomSslMaterial()).isFalse();
    }

    @Test
    void tlsFlag_alone_requiresTls_noCustomMaterial() {
        NatsSecurity sec = new NatsSecurity(
                null, null, null, null, /*tls*/ true,
                null, null, null, null, null, null);
        assertThat(sec.isEmpty()).isFalse();
        assertThat(sec.requiresTls()).isTrue();
        assertThat(sec.hasCustomSslMaterial())
                .as("bare tls:true relies on the JVM default trust store").isFalse();
    }

    @Test
    void truststorePath_impliesRequireTls_andCustomMaterial() {
        NatsSecurity sec = new NatsSecurity(
                null, null, null, null, /*tls*/ false,
                "/some/truststore.p12", "changeit", "PKCS12",
                null, null, null);
        assertThat(sec.requiresTls()).isTrue();
        assertThat(sec.hasCustomSslMaterial()).isTrue();
    }

    @Test
    void buildSslContext_fromTrustStoreOnly_succeeds(@TempDir Path tmp) throws Exception {
        // Empty PKCS12 truststore — enough to exercise the load path without
        // needing a real certificate. Loading with a null CA set is legal.
        Path ts = tmp.resolve("empty.p12");
        KeyStore emptyStore = KeyStore.getInstance("PKCS12");
        emptyStore.load(null, "changeit".toCharArray());
        try (var out = Files.newOutputStream(ts)) {
            emptyStore.store(out, "changeit".toCharArray());
        }

        NatsSecurity sec = new NatsSecurity(
                null, null, null, null, false,
                ts.toString(), "changeit", "PKCS12",
                null, null, null);
        var ctx = sec.buildSslContext();
        assertThat(ctx).isNotNull();
        assertThat(ctx.getProtocol()).isEqualTo("TLSv1.2");
    }

    @Test
    void propertiesToSecurity_roundTrips() {
        NatsSecurityProperties p = new NatsSecurityProperties();
        p.setUsername("alice");
        p.setPassword("s3cret");
        p.setTls(true);
        NatsSecurity sec = p.toSecurity();
        assertThat(sec.username()).isEqualTo("alice");
        assertThat(sec.password()).isEqualTo("s3cret");
        assertThat(sec.requiresTls()).isTrue();
    }
}
