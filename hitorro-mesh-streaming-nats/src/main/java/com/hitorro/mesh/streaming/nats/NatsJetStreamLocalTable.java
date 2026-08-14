/*
 * Copyright (c) 2006-2025 Chris Collins
 */
package com.hitorro.mesh.streaming.nats;

import com.hitorro.jsontypesystem.JVS;
import com.hitorro.jsontypesystem.Type;
import com.hitorro.mesh.agent.LocalTable;
import com.hitorro.streams.nats.NatsJetStreamSource;

import java.util.Iterator;

/**
 * A {@link LocalTable} whose scan iterator consumes from a NATS JetStream
 * subject via {@code hitorro-streams-nats}'s {@link NatsJetStreamSource}.
 * Rows arrive as they're published to the subject; the iterator blocks
 * between fetches.
 *
 * <p>Same shape as {@code InMemoryStreamingTable} from a mesh-agent
 * perspective — the phase-6a streaming foundation handles everything.</p>
 *
 * <p>NATS JetStream gives you durable consumers, replay, and per-consumer
 * offset tracking — a step up from raw NATS pub/sub. Use durable-name to
 * survive agent restarts without losing your place.</p>
 *
 * <p><b>Config knobs</b> live on the underlying {@link NatsJetStreamSource.Builder}:
 * URL, stream, subject, durable-name, batch size, fetch timeout.</p>
 *
 * <p><b>Cancellation:</b> the phase-6c.2 cancel signal interrupts the
 * agent's worker thread. The underlying source's iterator responds to
 * interruption during its fetch loop; the scan ends cleanly.</p>
 */
public final class NatsJetStreamLocalTable implements LocalTable, AutoCloseable {

    private final String name;
    private final Type type;
    private final String partitionKey;
    private final NatsJetStreamSource source;

    /**
     * @param name         logical table name in the SQL FROM clause
     * @param type         JVS type
     * @param partitionKey which partition of this table this agent holds
     * @param source       pre-configured JetStream source owning its Connection.
     *                     This class takes ownership and closes it in {@link #close()}.
     */
    public NatsJetStreamLocalTable(String name, Type type, String partitionKey, NatsJetStreamSource source) {
        this.name = name;
        this.type = type;
        this.partitionKey = partitionKey;
        this.source = source;
    }

    @Override public String name() { return name; }
    @Override public Type type() { return type; }
    @Override public String partitionKey() { return partitionKey; }

    @Override public Iterator<JVS> openScan() { return source.asJvsIterator(); }

    @Override
    public void close() {
        source.close();
    }
}
