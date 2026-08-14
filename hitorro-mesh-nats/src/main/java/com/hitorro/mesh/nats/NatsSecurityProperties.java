/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.nats;

/**
 * Mutable properties-binding companion to {@link NatsSecurity}. Spring
 * {@code @ConfigurationProperties} needs a plain-Java bean with setters,
 * which records don't provide. This class fills that gap and converts
 * to the immutable {@link NatsSecurity} record via {@link #toSecurity()}.
 *
 * <p>The transport itself operates only on the immutable record. This
 * companion is only for YAML/env deserialization at Spring Boot startup.</p>
 */
public class NatsSecurityProperties {
    private String username;
    private String password;
    private String token;
    private String credentialsFile;
    private boolean tls;
    private String trustStorePath;
    private String trustStorePassword;
    private String trustStoreType;
    private String keyStorePath;
    private String keyStorePassword;
    private String keyStoreType;

    public NatsSecurity toSecurity() {
        return new NatsSecurity(
                username, password, token, credentialsFile,
                tls,
                trustStorePath, trustStorePassword, trustStoreType,
                keyStorePath, keyStorePassword, keyStoreType);
    }

    public String getUsername() { return username; }
    public void setUsername(String v) { this.username = v; }
    public String getPassword() { return password; }
    public void setPassword(String v) { this.password = v; }
    public String getToken() { return token; }
    public void setToken(String v) { this.token = v; }
    public String getCredentialsFile() { return credentialsFile; }
    public void setCredentialsFile(String v) { this.credentialsFile = v; }
    public boolean isTls() { return tls; }
    public void setTls(boolean v) { this.tls = v; }
    public String getTrustStorePath() { return trustStorePath; }
    public void setTrustStorePath(String v) { this.trustStorePath = v; }
    public String getTrustStorePassword() { return trustStorePassword; }
    public void setTrustStorePassword(String v) { this.trustStorePassword = v; }
    public String getTrustStoreType() { return trustStoreType; }
    public void setTrustStoreType(String v) { this.trustStoreType = v; }
    public String getKeyStorePath() { return keyStorePath; }
    public void setKeyStorePath(String v) { this.keyStorePath = v; }
    public String getKeyStorePassword() { return keyStorePassword; }
    public void setKeyStorePassword(String v) { this.keyStorePassword = v; }
    public String getKeyStoreType() { return keyStoreType; }
    public void setKeyStoreType(String v) { this.keyStoreType = v; }
}
