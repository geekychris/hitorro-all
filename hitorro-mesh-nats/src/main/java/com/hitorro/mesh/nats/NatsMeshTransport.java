/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.nats;

import com.hitorro.mesh.MeshTransport;
import io.nats.client.Connection;
import io.nats.client.Dispatcher;
import io.nats.client.Nats;
import io.nats.client.Options;

import java.time.Duration;
import java.util.function.Consumer;

/**
 * NATS-backed {@link MeshTransport}. Phase-1 scope: plain pub/sub only.
 *
 * <p>Uses a single {@link Dispatcher} per subscription — NATS delivers
 * messages for that subscription on a dedicated thread, so per-subject
 * order is preserved without callers having to do anything. Wildcards
 * work as-is because subject matching is server-side.</p>
 *
 * <h3>What's NOT here yet (deliberate)</h3>
 * <ul>
 *   <li>No JetStream. Heartbeats, task dispatch and result rows are fine on
 *       plain pub/sub: a missed message just means the driver retries with
 *       another agent. Phase 2 introduces JetStream-backed subjects for
 *       shuffle output, where losing a partial aggregate would be wrong.</li>
 *   <li>No queue groups. The driver publishes to {@code mesh.agent.task.<agentId>}
 *       — a specific agent, not a load-balanced pool. Capability matching
 *       happens driver-side in {@code LiveAgentRegistry.pick(...)}.</li>
 *   <li>No request/reply. The {@link MeshTransport} SPI is intentionally
 *       narrow; every workflow expresses itself in publish + wildcard subscribe.</li>
 * </ul>
 *
 * <p><b>Design decision:</b> we let the caller pass in a {@link Connection}
 * they already own, or we build one from a URL string. This makes it easy
 * to reuse an existing NATS connection managed by the Spring context (e.g.
 * a connection shared with hitorro-streams-nats) rather than opening a
 * second TCP connection per module.</p>
 */
public final class NatsMeshTransport implements MeshTransport {

    private final Connection conn;
    private final boolean ownsConnection;

    public NatsMeshTransport(Connection conn) {
        this.conn = conn;
        this.ownsConnection = false;
    }

    public static NatsMeshTransport openUrl(String url) {
        return openUrl(url, NatsSecurity.none());
    }

    /**
     * Open a NATS connection with the given TLS + auth config. The security
     * config may be {@link NatsSecurity#none()} — equivalent to the single-arg
     * {@link #openUrl(String)}. The {@code tls://} URL scheme is honored
     * automatically by jnats regardless of {@code security.tls()}.
     */
    public static NatsMeshTransport openUrl(String url, NatsSecurity security) {
        try {
            Options.Builder b = new Options.Builder()
                    .server(url)
                    .connectionTimeout(Duration.ofSeconds(5))
                    .reconnectWait(Duration.ofSeconds(1))
                    .maxReconnects(-1);
            applySecurity(b, security);
            Connection c = Nats.connect(b.build());
            return new NatsMeshTransport(c, true);
        } catch (RuntimeException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("interrupted connecting to NATS at " + url, e);
        } catch (Exception e) {
            throw new RuntimeException("failed to connect to NATS at " + url, e);
        }
    }

    private static void applySecurity(Options.Builder b, NatsSecurity sec) throws Exception {
        if (sec == null || sec.isEmpty()) return;

        // Auth — pick the strongest configured option. Documented precedence
        // matches NatsSecurity's javadoc: creds > token > user/pass.
        if (sec.credentialsFile() != null && !sec.credentialsFile().isBlank()) {
            b.credentialPath(sec.credentialsFile());
        } else if (sec.token() != null && !sec.token().isBlank()) {
            b.token(sec.token().toCharArray());
        } else if (sec.username() != null && !sec.username().isBlank()) {
            b.userInfo(sec.username(), sec.password() == null ? "" : sec.password());
        }

        // TLS — custom SSL material takes precedence; falls back to
        // the JVM default trust store when just {@code tls: true} is set.
        if (sec.requiresTls()) {
            if (sec.hasCustomSslMaterial()) {
                b.sslContext(sec.buildSslContext());
            } else {
                b.secure();
            }
        }
    }

    private NatsMeshTransport(Connection conn, boolean ownsConnection) {
        this.conn = conn;
        this.ownsConnection = ownsConnection;
    }

    @Override
    public void publish(String subject, byte[] payload) {
        conn.publish(subject, payload);
    }

    @Override
    public Subscription subscribe(String subjectOrPattern, Consumer<byte[]> handler) {
        Dispatcher d = conn.createDispatcher(msg -> handler.accept(msg.getData()));
        d.subscribe(subjectOrPattern);
        return () -> conn.closeDispatcher(d);
    }

    @Override
    public void close() {
        if (ownsConnection) {
            try { conn.close(); }
            catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
        }
    }
}
