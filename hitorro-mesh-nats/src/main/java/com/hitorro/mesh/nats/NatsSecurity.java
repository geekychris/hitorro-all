/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.nats;

import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyStore;

/**
 * TLS + authentication config for the NATS transport. Immutable. Empty by
 * default — {@link #none()} produces the "no auth, no TLS" config used by
 * dev clusters and the in-memory test transport.
 *
 * <h3>Auth precedence</h3>
 * When multiple auth fields are set, the transport picks the strongest
 * one in this order (later options override earlier ones at the jnats
 * layer, but we set only one to keep behaviour predictable):
 * <ol>
 *   <li>{@link #credentialsFile} — {@code .creds} file (nkey + JWT)</li>
 *   <li>{@link #token}</li>
 *   <li>{@link #username} + {@link #password}</li>
 * </ol>
 *
 * <h3>TLS activation</h3>
 * TLS is enabled if any of these are true:
 * <ul>
 *   <li>{@link #tls} is explicitly {@code true}</li>
 *   <li>A {@link #trustStorePath} is set (custom trust anchor)</li>
 *   <li>A {@link #keyStorePath} is set (mTLS client cert)</li>
 *   <li>The NATS URL scheme is {@code tls://} (jnats picks this up
 *       automatically; documented here for completeness)</li>
 * </ul>
 * When only {@link #tls} is set, the default SSL context is used (OS
 * trust store — good for public-CA-signed brokers). When any keystore
 * / truststore path is set, we build a custom {@link SSLContext}.
 */
public record NatsSecurity(
        String username,
        String password,
        String token,
        String credentialsFile,
        boolean tls,
        String trustStorePath,
        String trustStorePassword,
        String trustStoreType,
        String keyStorePath,
        String keyStorePassword,
        String keyStoreType
) {
    private static final NatsSecurity NONE = new NatsSecurity(
            null, null, null, null, false, null, null, null, null, null, null);

    public static NatsSecurity none() { return NONE; }

    public boolean isEmpty() {
        return this.equals(NONE);
    }

    public boolean requiresTls() {
        return tls || trustStorePath != null || keyStorePath != null;
    }

    public boolean hasCustomSslMaterial() {
        return trustStorePath != null || keyStorePath != null;
    }

    /**
     * Build an {@link SSLContext} from the configured keystore / truststore.
     * Only called when at least one is set — otherwise the transport uses
     * {@code Options.Builder.secure()} (default OS trust).
     */
    public SSLContext buildSslContext() throws Exception {
        KeyManager[] kms = null;
        if (keyStorePath != null) {
            KeyStore ks = KeyStore.getInstance(defaultIfBlank(keyStoreType, "PKCS12"));
            char[] pw = keyStorePassword == null ? new char[0] : keyStorePassword.toCharArray();
            try (InputStream in = Files.newInputStream(Paths.get(keyStorePath))) {
                ks.load(in, pw);
            }
            KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(ks, pw);
            kms = kmf.getKeyManagers();
        }
        TrustManager[] tms = null;
        if (trustStorePath != null) {
            KeyStore ts = KeyStore.getInstance(defaultIfBlank(trustStoreType, "PKCS12"));
            char[] pw = trustStorePassword == null ? new char[0] : trustStorePassword.toCharArray();
            try (InputStream in = Files.newInputStream(Paths.get(trustStorePath))) {
                ts.load(in, pw);
            }
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            tmf.init(ts);
            tms = tmf.getTrustManagers();
        }
        SSLContext ctx = SSLContext.getInstance("TLSv1.2");
        ctx.init(kms, tms, null);
        return ctx;
    }

    private static String defaultIfBlank(String v, String fallback) {
        return v == null || v.isBlank() ? fallback : v;
    }
}
