/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.streaming.kafka;

import com.hitorro.jsontypesystem.JVS;
import com.hitorro.jsontypesystem.Type;
import com.hitorro.mesh.agent.LocalTable;
import com.hitorro.streams.kafka.KafkaSource;

import java.util.Iterator;

/**
 * A {@link LocalTable} whose scan iterator consumes from a Kafka topic via
 * {@code hitorro-streams-kafka}'s {@link KafkaSource}. Rows arrive as
 * they're produced to the topic; the iterator blocks between polls.
 *
 * <p>Same shape as {@code InMemoryStreamingTable} from a mesh-agent
 * perspective — no changes to the agent, dispatcher, or wire protocol
 * needed. Streaming semantics come for free from the phase-6a foundation.</p>
 *
 * <p><b>Config knobs</b> live on the underlying {@link KafkaSource.Builder}:
 * bootstrap servers, group ID (typically {@code mesh-agent-<agentId>}),
 * topic, offset reset policy, poll batch size, etc. The mesh doesn't add
 * a config layer on top; deployers construct the KafkaSource however
 * they need and wrap it here.</p>
 *
 * <p><b>Cancellation:</b> the phase-6c.2 cancel signal interrupts the
 * agent's worker thread. {@link KafkaSource#asJvsIterator()} responds to
 * interruption by breaking out of its poll loop; the scan ends cleanly.</p>
 */
public final class KafkaStreamingLocalTable implements LocalTable, AutoCloseable {

    private final String name;
    private final Type type;
    private final String partitionKey;
    private final KafkaSource source;

    /**
     * @param name         logical table name that appears in the SQL FROM clause
     * @param type         JVS type — column names + types the mesh understands
     * @param partitionKey which partition of this table this agent holds (nullable
     *                     for "not partitioned"; typically a shard identifier)
     * @param source       pre-configured {@link KafkaSource} owning its Consumer.
     *                     This class takes ownership and closes it in {@link #close()}.
     */
    public KafkaStreamingLocalTable(String name, Type type, String partitionKey, KafkaSource source) {
        this.name = name;
        this.type = type;
        this.partitionKey = partitionKey;
        this.source = source;
    }

    @Override public String name() { return name; }
    @Override public Type type() { return type; }
    @Override public String partitionKey() { return partitionKey; }

    /**
     * Fresh iterator over the Kafka topic. The mesh agent's scan loop is
     * synchronous — each call to {@code hasNext()} blocks until a record
     * arrives (or the underlying {@code Consumer.poll()} returns from
     * interruption on cancel).
     *
     * <p>{@link KafkaSource} is intended to be scanned once — same convention
     * as every other {@code LocalTable} in the mesh. Calling {@code openScan}
     * a second time re-uses the same consumer's ongoing offset position,
     * which is what you want for a continuously-consumed stream.</p>
     */
    @Override public Iterator<JVS> openScan() { return source.asJvsIterator(); }

    @Override
    public void close() {
        source.close();
    }
}
