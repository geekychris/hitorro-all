<!-- Copied from the migration workspace (~/hitorro-j3/JACKSON3_NOTES.md) when HiTorro 4.0.0 was released; condensed in KNOWLEDGE.md section 4. -->
# Jackson 3 migration notes (HiTorro 4.0.0)

These are the conventions the four layer-0/1 repos (hitorro-core, hitorro-streams,
hitorro-mesh-core, hitorro-mesh-datasets) set. Every later repo should follow them. Each of
those four has a draft PR; see `STATUS.md`. If you learn something non-obvious, add it here.

## 1. Versions and BOM

| What | Coordinates | Version |
|---|---|---|
| Jackson 3 BOM (import in `<dependencyManagement>`) | `tools.jackson:jackson-bom` | **3.1.8**, the version Spring Boot 4.1.3 manages (`jackson-bom.version`) |
| core / databind | `tools.jackson.core:jackson-core`, `tools.jackson.core:jackson-databind` | from the BOM |
| annotations (unchanged package `com.fasterxml.jackson.annotation`) | `com.fasterxml.jackson.core:jackson-annotations` | **2.21** (from the BOM) |
| YAML / Smile | `tools.jackson.dataformat:jackson-dataformat-yaml` / `-smile` | from the BOM |
| java.time, Optional (jsr310, jdk8 modules) | built into databind | drop `jackson-datatype-jsr310` and `jackson-datatype-jdk8` |
| HiTorro | every `com.hitorro` artifact | **4.0.0** |

For reference, Boot 4.1.3 manages the Jackson 2 bridge at `com.fasterxml.jackson:jackson-bom`
2.21.8. None of the four repos needed it. Keep it only if `mvn dependency:tree` shows Jackson 2
arriving through a third-party library and you want to pin it for security.

## 2. pom changes (per repo)

1. `<version>` → `4.0.0` in every module. Also change every HiTorro dependency **and every
   version property** (`hitorro-core.version`, `hitorro.util.version`, …) to `4.0.0`. Grep for
   `3\.[0-9]\.[0-9]` near `com.hitorro`.
2. Replace the `com.fasterxml.jackson:jackson-bom` 2.x import with `tools.jackson:jackson-bom`
   `3.1.8`.
3. Change the direct Jackson dependencies to the `tools.jackson.*` coordinates without versions
   (the BOM manages them), and add `com.fasterxml.jackson.core:jackson-annotations` if the repo
   uses annotations directly. hitorro-core already exports databind, core, annotations and
   smile, so repos that depend on core don't need to declare Jackson unless they use another
   module (yaml etc.).
4. Remove the jsr310/jdk8 modules and any `registerModule(new JavaTimeModule())`.
5. Check with `mvn -s ~/hitorro-j3/settings.xml dependency:tree | grep -i jackson`. Only
   `tools.jackson.*` and `com.fasterxml.jackson.core:jackson-annotations` may appear, unless a
   third-party library brings Jackson 2 transitively (allowed, but note it in the PR).
6. **Audit lost mapper settings.** OpenRewrite silently dropped a
   `.disable(FAIL_ON_UNKNOWN_PROPERTIES)` in one repo. Before committing, run
   `git diff origin/<default>...HEAD -- src | grep -E '^-.*(enable|disable|configure|Feature|registerModule|Include\.)'`
   and make sure every removed setting reappears on the new builder. Core, streams, mesh-core and
   mesh-datasets were audited and lost nothing.
7. If you run OpenRewrite, **don't keep its pom edits**. It strips unrelated `<version>` tags.
   Restore the pom (`git checkout -- pom.xml`) and edit it by hand.

## 3. The format-compatibility convention (the important part)

**Decision:** HiTorro's mappers produce and accept exactly what Jackson 2 did in 3.x. Jackson 3's
own defaults differ on:
- property order: alphabetical (2.x used declaration order, and records were affected)
- dates: ISO strings (2.x wrote epoch millis)
- unknown properties: ignored (2.x failed)
- null for primitives: fails (2.x gave the default)
- trailing tokens: fail (2.x ignored them)
- empty beans: written as `{}` (2.x failed)

### 3.1 Mappers: `com.hitorro.util.json.JsonMappers` (hitorro-core)

| Instead of (2.x) | Use (4.0.0) |
|---|---|
| `new ObjectMapper()` | `JsonMappers.json()` (shared, immutable, thread safe) |
| `new ObjectMapper().configure(...)/enable(...)/registerModule(...)` | `JsonMappers.builder().configure(...).enable(...).addModule(...).build()` (keep it in a static field) |
| `new ObjectMapper(new SmileFactory())` | `JsonMappers.smile()` / `JsonMappers.smileBuilder()` |
| `new YAMLMapper()` | `YamlMappers.yaml()` / `YamlMappers.builder()...build()` (hitorro-core 4.0.0, commit 5d669de; declare `tools.jackson.dataformat:jackson-dataformat-yaml`, optional in core). Never a plain `YAMLMapper`: see "YAML" below |
| `new JsonFactory()` + `factory.createParser(reader)` | `JsonMappers.json().createParser(reader)` (the mapper is the factory) |
| `mapper.getFactory().createGenerator(out)` + `gen.setPrettyPrinter(new DefaultPrettyPrinter())` | `(pretty ? M.writerWithDefaultPrettyPrinter() : M.writer()).createGenerator(out)` |

`JsonMappers.builder()` is `JsonMapper.builderWithJackson2Defaults()` **plus Jackson 2.18's stream
limits** (core commit 362088f, after another agent's golden test found the difference). A repo without a
hitorro-core dependency (e.g. hitorro-mesh-datasets) calls that directly rather than adding the
dependency.

#### JDK types: `Jackson2JdkModule` (core d27ea01)

Jackson 3 writes and reads some JDK types differently, and no feature switches them back.
`com.hitorro.util.json.Jackson2JdkModule` restores 2.18.12's behaviour.
`JsonMappers.builder()`/`smileBuilder()` and `YamlMappers.builder()` register it; mesh-datasets has
its own copy. **A mapper not built from these builders must `addModule(new Jackson2JdkModule())`.**
Measured for JSON, Smile and YAML; as a value, a map key and a tree; writing and reading
(`Jackson2JdkModuleGoldenTest`, data from `~/hitorro-j3/tools/Jackson2JdkTypesGolden*.java.txt`):

| Type | Jackson 2.18 | Jackson 3.1.8 (without the module) |
|---|---|---|
| `Locale` value / tree | `toString()`: `"fr_CA"`, `"zh_TW_#Hant"`, `"_US"`, `"ja_JP_JP_#u-ca-japanese"` | language tag: `"fr-CA"`, `"zh-Hant-TW"`, `"und-US"`, `"nn-NO"` for `no_NO_NY` |
| `Locale` map key | `toString()` | `toString()` (same) |
| reading `"zh_TW_#Hant"`, `"sr__#Latn"`, `"de_DE_#u-co-phonebk"`, `"en__#x-foo"` | script / extension kept | lost (moved into the variant) |
| `Month` | `"NOVEMBER"` | `10` (zero-based) |
| `byte[]` in `valueToTree` | BINARY node | POJO node (streamed output identical) |

Identical in both, so left alone: Currency, TimeZone, ZoneId/ZoneOffset, URL, URI, File, Path,
InetAddress, InetSocketAddress, UUID, Class, Charset, Pattern, char[], enums (incl. `toString()`
overrides), StringBuilder, the atomics, BigDecimal, Date, Calendar, java.sql.Date/Timestamp, java.time
(timestamps on) and Optional/OptionalInt. Decision: for java.time and Optional, the reference is 2.18
*with* the jsr310/jdk8 modules. A plain 2.18 `new ObjectMapper()` (core's 3.x setup) could not write or
read them at all, and Jackson 3's built-in support equals the modules. The one place plain 2.18 wrote
something else: a `ZonedDateTime` **map key** came out as `toString()` with the zone id
(`...+01:00[Europe/Paris]`); with the module, and in 4.0.0, it has no zone id.

#### Stream limits (StreamReadConstraints / StreamWriteConstraints): set them explicitly

`builderWithJackson2Defaults()` / `configureForJackson2()` **do not** restore Jackson 2's stream
limits. Every default, measured on 2.18.12 (2.21.8 is the same) against 3.1.8:

| Limit | Jackson 2.18 / 2.21 | Jackson 3.1.8 |
|---|---|---|
| read `maxNestingDepth` | **1000** | **500** |
| write `maxNestingDepth` | **1000** | **500** |
| read `maxStringLength` | **20,000,000** | **100,000,000** (looser) |
| read `maxNumberLength` | 1000 | 1000 |
| read `maxNameLength` | 50,000 | 50,000 |
| read `maxDocumentLength` / `maxTokenCount` | unlimited (-1) | unlimited (-1) |
| `ErrorReportConfiguration` (error token / raw content length) | 256 / 500 | 256 / 500 |

`JsonMappers.json()`, `builder()`, `smile()` and `smileBuilder()` use
`JsonMappers.JACKSON2_READ_CONSTRAINTS` / `JACKSON2_WRITE_CONSTRAINTS`. `JsonMappersLimitsTest` checks
each boundary (1000 ok, 1001 rejected; 20,000,000 ok, 20,000,001 rejected; numbers 1000/1001; names
50,000/50,001), for JSON and Smile, reading and writing, exactly as 2.18.12 accepts and rejects.
Without this, a 600-deep Kafka message that 3.x accepted was skipped.

**Any mapper you build without `JsonMappers.builder()`** must set them on its *factory*. YAML,
CSV, XML, or a repo without a core dependency (mesh-datasets does this in its own
`Jackson2Defaults`) all need this:

```java
// YAML: use hitorro-core's YamlMappers (it does all of this plus the YAML 1.1 scalar typing).
// Only a repo without a core dependency builds its own, and then it must copy YamlMappers' parser:
YAMLFactory f = YAMLFactory.builder().configureForJackson2()            // factory-level Jackson 2 settings
        .enable(YAMLReadFeature.EMPTY_STRING_AS_NULL)                    // builder() leaves it off in 3.1.8!
        .streamReadConstraints(JsonMappers.JACKSON2_READ_CONSTRAINTS)
        .streamWriteConstraints(JsonMappers.JACKSON2_WRITE_CONSTRAINTS).build();
XxxMapper m = XxxMapper.builder(f).configureForJackson2()...build();    // mapper-level Jackson 2 settings
```

`XxxMapper.builder().configureForJackson2()` alone sets only the *mapper's* Jackson 2 features. The
factory's own (`TSFBuilder.configureForJackson2()`: fast double parser off, property-name interning
on) need `XxxFactory.builder().configureForJackson2()`, as above. YAML documents over about 3 MB are
rejected by snakeyaml's code point limit in both versions (unchanged). **YAML:** enable `YAMLReadFeature.EMPTY_STRING_AS_NULL` on the
YAMLFactory builder explicitly. Without it, 3.1.8 reads a bare `k:` as `""`; Jackson 2 read
`null`. Quoted `''`/`""` stay `""` in both. Unquoted YAML 1.1 scalars (`yes`/`on`/`~`/`0x1F`/`1_000`/`.5`)
also resolve differently in Jackson 3: see the YAML compat classes in hitorro-core (being added
by j3-util) and the measured matrix `~/hitorro-j3/tools/yaml11-scalars-2.21.8.txt` (37 of 74
scalars differ; `y`/`n` are strings in both). Golden tests that "accept" a
nesting-depth difference are wrong: remove the entry and use the core 4.0.0 that includes 362088f.

#### YAML: `com.hitorro.util.json.YamlMappers` (hitorro-core, required for any YAML)

Jackson 3's `YAMLParser` types plain (unquoted) scalars by YAML 1.2 (snakeyaml-engine's JSON schema,
hard-coded) and only `true`/`false` are booleans. Jackson 2 used YAML 1.1: `yes/no/on/off` (and
`Yes/YES/True/FALSE`...), `0x1F`, `017`, `0b101`, `1_000`, `+12`, `~`, `Null`, `.5` were booleans,
numbers and nulls (`y/n` were strings; `.inf/.nan` failed). With a plain Jackson 3 `YAMLMapper` they all
become strings, silently; `configureForJackson2()` doesn't help. `YamlMappers.builder()/yaml()/factory()`
install a parser with snakeyaml 2.5's YAML 1.1 resolution and Jackson 2.21's boolean words, plus
`configureForJackson2()`, `EMPTY_STRING_AS_NULL` and the 2.18 stream limits; it survives
`rebuild()/copy()`. Core pins 1650 read cases, 148 write cases and j3-core's shared 74-scalar matrix
(`tools/yaml11-scalars-2.21.8.txt`) against 2.21.8. Accepted, pinned differences (YAML 1.2 lexer):
NEL/U+2028/U+2029 are not line breaks (2.x wrote U+2028/U+2029 escaped as `\L`/`\P`, now raw), and
`[-]` is a syntax error. hitorro-mesh-datasets (no core dependency) carries an identical copy.

**`new ObjectMapper()` still compiles on Jackson 3 but has Jackson 3 defaults**, and OpenRewrite
leaves it alone. Grep for it, and for `new JsonMapper()` / `JsonMapper.builder()` /
`new YAMLMapper()`, in main **and** test code:

```bash
grep -rnE 'new (ObjectMapper|JsonMapper|YAMLMapper|SmileMapper|JsonFactory)\(|(Json|YAML|Smile)Mapper\.builder\(\)' src
```

Spring Boot apps: Boot 4's own auto-configured `JsonMapper` uses Boot's (Jackson 3) defaults.
**Decided by the user (2026-11-20): apps keep exactly today's REST/JSON format.**
**CORRECTION (j3-apps2):** today's app output comes from Boot's AUTO-CONFIGURED Jackson 2 mapper, NOT plain
Jackson 2 defaults: Boot writes dates as ISO strings (WRITE_DATES_AS_TIMESTAMPS off), ignores unknown properties,
registers jsr310/jdk8/parameter-names modules, and applies the app's `spring.jackson2.*` settings. So the app
customizer must reproduce Boot 4.1.3's jackson2 auto-configuration + the app's own settings, NOT JsonMappers.builder()
(that would turn dates into epoch numbers). The golden REST tests recorded from main are the judge.
Original note: configure Boot's auto-configured Jackson 3 `JsonMapper` with Jackson 2 defaults (e.g. a `JsonMapperBuilderCustomizer`
applying the same settings as `JsonMappers.builder()`: no alphabetical sorting, dates as timestamps,
the 2.x deserialization leniency), then drop the `spring-boot-jackson2` bridge and the
`preferred-json-mapper: jackson2` / `spring.jackson2.*` settings. Required tests per app: golden
tests that record the REST responses (and any stored JSON) from the CURRENT main build on Jackson 2,
and assert the migrated app returns byte-identical JSON (or semantically identical where order is
not deterministic); plus the full test suite vs baseline. HiTorro libraries never use Boot's mapper.

### 3.2 JsonNode accessors: `com.hitorro.util.json.JsonValues` (hitorro-core)

In Jackson 3 the value accessors **throw `JsonNodeException`** where Jackson 2 returned a
default. Measured against 2.18:

| Call | Jackson 2 | Jackson 3 |
|---|---|---|
| `textValue()` on a number/null/missing/object | `null` | throws |
| `longValue()`, `intValue()`, `doubleValue()`, `booleanValue()` on a string, null, missing, object or boolean | `0` / `false` | throws |
| `longValue()` / `intValue()` on `3.7` | `3` | throws |
| `asText()` on a null node | `"null"` | `""` |
| `asText()` on an object or array | `""` | throws |
| `asLong()`, `asInt()` on `"abc"` or a container | `0` | throws |
| `asInt()` on a boolean | `1`/`0` | throws |
| `asLong(7)` on BigDecimal `1e30` | wrapped long | `7` |
| `numberValue()` on a non-number | `null` | throws |

HiTorro reads loosely typed JSON everywhere, so **every such call in main code goes through
`JsonValues`**, which reproduces 2.18 exactly. `JsonValuesTest` checks this against 1,090
node × method results recorded from Jackson 2.18.

| 2.x call | 4.0.0 |
|---|---|
| `n.textValue()` (OpenRewrite turns it into `n.stringValue()`) | `JsonValues.textValue(n)` |
| `n.asText()` / `n.asText(d)` (OpenRewrite: `asString`) | `JsonValues.asText(n)` / `JsonValues.asText(n, d)` |
| `n.intValue()`, `longValue()`, `shortValue()`, `floatValue()`, `doubleValue()`, `decimalValue()`, `bigIntegerValue()`, `booleanValue()`, `numberValue()`, `binaryValue()` | `JsonValues.<same>(n)` |
| `n.asInt()`, `asLong()`, `asDouble()`, `asBoolean()` (with or without a default) | `JsonValues.<same>(n[, d])` |

**Don't do this by hand. Use the rewriter**, `~/hitorro-j3/tools/JsonValuesRewriter.java`.
It resolves types with javac, so only calls whose method belongs to `tools.jackson.databind.JsonNode`
are rewritten; `Integer.intValue()`, `BigDecimal.longValue()` and similar are left alone. It
handles nested calls, adds the import, and warns about method references
(`JsonNode::asText` → change to `JsonValues::asText` by hand; none existed in any HiTorro repo
in November 2026). Run it once the code compiles on Jackson 3:

```bash
CP=$(mvn -s ~/hitorro-j3/settings.xml -q dependency:build-classpath -Dmdep.outputFile=/dev/stdout)
java ~/hitorro-j3/tools/JsonValuesRewriter.java --cp "${CP}" src/main/java     # add src/test/java if you like
```

**Don't run the rewriter over a copy of `JsonValues` itself** (an app without a core dependency that
carries its own copy, e.g. hitorro-search-ui `json/`): it rewrites the copy's internal calls into
`com.hitorro.util.json.JsonValues...`. Copy the file after rewriting, or re-copy it (j3-apps2).
(zsh: write `"${CP}"`, not `"$CP:..."`. `$CP:t` is a zsh modifier and silently breaks the
classpath.) `--dry-run` lists the call sites without changing anything. Where a node's type is
already checked (`if (n.isString()) n.textValue()`) the rewrite is harmless, so leave it. Tests may
use Jackson 3 methods directly.

### 3.3 Exceptions

- `JsonProcessingException` → `tools.jackson.core.JacksonException`. It is **unchecked**
  (a RuntimeException). `JsonMappingException` → `tools.jackson.databind.DatabindException`.
  `JsonParseException` → `tools.jackson.core.exc.StreamReadException`.
- Remove `throws IOException` / `throws JsonProcessingException` that existed only for Jackson,
  and list each one under "Public API changes" in the PR. Keep `throws IOException` that also
  covers real I/O, or that is a published contract (see below).
- **A silent behaviour change**: `try { mapper.readValue(...) } catch (IOException e) { return null; }`
  still compiles when the try block also does I/O, but **it no longer catches parse errors**.
  - If the block only does Jackson calls, the compiler reports "IOException is never thrown";
    change the catch to `JacksonException`.
  - If the block does both, use `catch (IOException | JacksonException e)`.
  - Find these with `grep -n 'catch (IOException'` in every file that imports `tools.jackson`,
    and read each one.
- To keep a public `throws IOException` contract (e.g. "a malformed manifest is an
  IOException"), catch `JacksonException` and rethrow it as `new IOException(e.getMessage(), e)`.
  hitorro-mesh-datasets `ManifestLoader` does this, and a test pins it.

### 3.4 Pin it with tests (required for every repo)

Each repo adds a test that compares what it writes and reads with **golden output produced by
Jackson 2**. The test data must come from running the real 3.x code, not from an expectation
typed by hand. Two ways to get the 3.x code:
- **Published jars**: `mvn -s ~/hitorro-j3/settings.xml dependency:get -Dartifact=com.hitorro:<repo>:<3.x version>`
  lands it in `~/hitorro-j3/.m2`. hitorro-streams used this.
- **Original sources**: `git archive HEAD pom.xml src/main | tar -x -C <scratch>`, then
  `mvn -s ~/hitorro-j3/settings.xml compile` there and
  `dependency:build-classpath -Dmdep.outputFile=cp.txt`. hitorro-mesh-core and
  hitorro-mesh-datasets used this.

Write one small program as a template, with `PKG` standing for `com.fasterxml.jackson` or
`tools.jackson`. Compile it twice: against the 3.x classpath with Jackson 2 and against the new
code. Print `key=value` lines, `diff` the two outputs, and fix the code until there is no
difference. Then commit the Jackson 2 output as `src/test/resources/.../jackson2-*.txt` with a
JUnit test that recomputes each key. The generators used so far are in
`~/hitorro-j3/tools/*.java.txt`; copy one as a starting point. Cover:
- everything persisted or sent over the wire: beans, records, maps, JsonNode trees, files that
  sinks write, message codecs;
- reading data that 3.x wrote;
- behaviour on invalid input (returns null, stops, or throws which exception).

Things that are **the same in Jackson 2 and 3** (checked; don't "fix" them):
- `JsonNode.toString()` / `toPrettyString()` output, and `DefaultPrettyPrinter` output (but not past 500 levels of nesting, see §7).
- Reading `1.10` into a tree gives `DoubleNode 1.1` (also from Smile).
- A `Set` decodes to a `HashSet` (order is lost).
- `"x": null` into a `JsonNode` field gives a `NullNode`.
- Smile bytes are the same.

## 4. API rename table (actually hit in these four repos)

| Jackson 2 | Jackson 3 |
|---|---|
| `com.fasterxml.jackson.databind.*`, `com.fasterxml.jackson.core.*` | `tools.jackson.databind.*`, `tools.jackson.core.*` (annotations unchanged) |
| `com.fasterxml.jackson.core.JsonFactory` | `tools.jackson.core.json.JsonFactory` (prefer the mapper, see 3.1) |
| `JsonParseException` | `tools.jackson.core.exc.StreamReadException` |
| `JsonLocation` | `tools.jackson.core.TokenStreamLocation` |
| `JsonProcessingException` | `tools.jackson.core.JacksonException` (unchecked) |
| `node.fields()` | `node.properties().iterator()` (or iterate `properties()`) |
| `node.fieldNames()` | `node.propertyNames().iterator()` |
| `node.elements()` | `node.values().iterator()` |
| `node.isTextual()` | `node.isString()` |
| `node.isContainerNode()` | `node.isContainer()` |
| `JsonNodeFactory.instance.textNode(s)` / `TextNode` | `stringNode(s)` / `StringNode` |
| `objectNode.put(String, JsonNode)` | `objectNode.set(String, JsonNode)` (`put` with JsonNode is gone) |
| `parser.getCurrentToken()` / `getCurrentName()` | `parser.currentToken()` / `currentName()` |
| `parser.getText()` | `parser.getString()` (`getText()` still exists, deprecated) |
| `factory.createJsonParser(r)` | `mapper.createParser(r)` |
| `gen.writeFieldName(n)` | `gen.writeName(n)` |
| `gen.writeObjectFieldStart(n)` / `writeArrayFieldStart(n)` | `writeObjectPropertyStart(n)` / `writeArrayPropertyStart(n)` |
| `gen.writeStringField/NumberField/BooleanField/NullField` | `writeStringProperty/NumberProperty/BooleanProperty/NullProperty` |
| `gen.setPrettyPrinter(...)` | choose it on the `ObjectWriter` that creates the generator |
| `mapper.getFactory()` | `mapper.tokenStreamFactory()` (rarely needed) |
| `mapper.configure/enable/disable/registerModule` on an instance | builder methods (`JsonMappers.builder()...build()`); mappers are immutable |
| `new YAMLMapper().disable(F)` | `YamlMappers.builder().disable(F).build()` (hitorro-core; see 3.1 "YAML") |
| `JsonNode.textValue()/asText()` | still exist in 3.1 (deprecated aliases of `stringValue()/asString()`) **but throw**: use `JsonValues` |

Expected but **not hit yet** (each class or constant was confirmed to exist in the 3.1.8 jars;
the mapping comes from the Jackson 3 release notes):
- `JsonSerializer`/`JsonDeserializer` → `ValueSerializer`/`ValueDeserializer`.
- `SerializerProvider` → `SerializationContext`.
- `JsonGenerator.Feature.AUTO_CLOSE_TARGET` / `FLUSH_PASSED_TO_STREAM` → `StreamWriteFeature.*`
  (set on the builder). Hit in hitorro-basefile `JsonSink`: OpenRewrite turns it into
  `mapper.configure(StreamWriteFeature..., false)`, which doesn't compile on 3; build the mappers.
- Date features moved to `tools.jackson.databind.cfg.DateTimeFeature`.
- `ObjectNode.with(...)` → `withObject(...)`.

## 5. OpenRewrite: worth running, but check its work

```bash
mvn -s ~/hitorro-j3/settings.xml -B -q org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-jackson:RELEASE \
  -Drewrite.activeRecipes=org.openrewrite.java.jackson.UpgradeJackson_2_3 -Drewrite.exportDatatables=false
```

It moves imports and does `fields()`, `isTextual`, `put→set` (only sometimes), and
`textValue→stringValue`/`asText→asString`. The rewriter turns those back into `JsonValues`.
It **missed**:
- `textNode`, `fieldNames()`, `isContainerNode`, `put(String, JsonNode)` in several files;
- all the streaming renames (`getCurrentToken`, `JsonParseException`, `JsonLocation`, the
  `JsonFactory` package, generator `write*Field`);
- `new ObjectMapper()`;
- one file entirely (hitorro-core `HTMLUtil`: fully qualified names in the code).

It also rewrites the pom badly (see 2.7). It also needs **Jackson 2 on the compile classpath**: run it before
switching the pom to Jackson 3 (or with the original pom checked out), else it fails with
"package com.fasterxml.jackson.databind does not exist" (hit in hitorro-jsontypesystem; basefile only
worked because hadoop brought Jackson 2). Commit no plugin config. After it runs, these sed
renames cleared most of what was left in streams (BSD sed on macOS; feed files through
`xargs`, because zsh doesn't word-split `$FILES`):

```bash
grep -rlE 'tools\.jackson' src | xargs sed -i '' -E \
  -e 's/\.getCurrentToken\(\)/.currentToken()/g' -e 's/\.getCurrentName\(\)/.currentName()/g' \
  -e 's/JsonNodeFactory\.instance\.textNode\(/JsonNodeFactory.instance.stringNode(/g' \
  -e 's/^import tools\.jackson\.core\.JsonParseException;/import tools.jackson.core.exc.StreamReadException;/' \
  -e 's/[[:<:]]JsonParseException[[:>:]]/StreamReadException/g' \
  -e 's/^import tools\.jackson\.core\.JsonLocation;/import tools.jackson.core.TokenStreamLocation;/' \
  -e 's/[[:<:]]JsonLocation[[:>:]]/TokenStreamLocation/g' \
  -e 's/^import tools\.jackson\.core\.JsonFactory;/import tools.jackson.core.json.JsonFactory;/' \
  -e 's/\.writeFieldName\(/.writeName(/g' -e 's/\.writeObjectFieldStart\(/.writeObjectPropertyStart(/g' \
  -e 's/\.writeArrayFieldStart\(/.writeArrayPropertyStart(/g' -e 's/\.writeStringField\(/.writeStringProperty(/g' \
  -e 's/\.writeNumberField\(/.writeNumberProperty(/g' -e 's/\.writeBooleanField\(/.writeBooleanProperty(/g' \
  -e 's/\.fieldNames\(\)/.propertyNames().iterator()/g' -e 's/\.isContainerNode\(\)/.isContainer()/g'
```

BSD sed doesn't turn `\n` in a replacement into a newline; use python for multi-line edits.
Fix `put(String, JsonNode)` by hand on the lines the compiler reports ("no suitable method found
for put").

In hitorro-jvssql OpenRewrite *did* touch the mappers: it rewrote `new ObjectMapper()` to
`new JsonMapper()` and `new ObjectMapper().enable(X)` to `JsonMapper.builder().enable(X).build()`.
Both have Jackson 3 defaults; replace them with `JsonMappers.json()` / `JsonMappers.builder()`.

## 6. Procedure per repo

```bash
cd ~/hitorro-j3/<repo>        # branch j3/jackson3
export DOCKER_HOST=unix:///Users/chris/.rd/docker.sock TESTCONTAINERS_RYUK_DISABLED=true
mvn -s ~/hitorro-j3/settings.xml -B -fae test -Dmaven.test.failure.ignore=true > ~/hitorro-j3/baseline/<repo>.log  # 1. baseline
#    record failing test names in ~/hitorro-j3/baseline/<repo>.txt
#    2. pom (section 2)   3. OpenRewrite + sed (5)   4. mvn ... test-compile until clean
#    5. mappers (3.1)     6. catch blocks (3.3)       7. JsonValuesRewriter on src/main/java (3.2)
#    8. golden tests (3.4)
mvn -s ~/hitorro-j3/settings.xml -B install            # tests must match the baseline; puts 4.0.0 in ~/hitorro-j3/.m2
mvn -s ~/hitorro-j3/settings.xml dependency:tree | grep -i jackson
git add pom.xml src ...       # source only: never target/, data/, node_modules/ (hitorro-core commits target/)
```

Commit as "4.0.0: Jackson 3", with the `Co-Authored-By` line. Push `j3/jackson3` and run
`gh pr create --draft --base <default branch> --title "4.0.0: Jackson 3"`. The body covers what
changed, public API changes, format decisions and the tests that pin them, and tests vs
baseline. Then append a row to `~/hitorro-j3/STATUS.md`. Never merge, never publish to
hitorro-maven, never build without `-s ~/hitorro-j3/settings.xml`.

Repos with `master` as default branch: hitorro-dms, hitorro-mesh-pipelines,
hitorro-mesh-agent-pipelines, hitorro-mesh-pipelines-{jvstype,kvstore,lucene,sqlite}.

## 7. Other gotchas

- Jackson 3 mappers are immutable. A field such as `protected ObjectMapper mapper` that subclasses
  configure (e.g. streams `Json2StringMapper`) can no longer be changed in place; build a new one.
- hitorro-streams' `JSONIterator`/`HTJSONParser` turn BIG_INTEGER into an `int` and BIG_DECIMAL
  into a `long` (an old quirk). The quirk is kept and pinned by a test; don't "fix" it in the
  migration.
- Some hitorro-core tests write to `~/hitorro-fs/config`.
- Building updates hitorro-core's committed `target/` classes. Don't stage them
  (`git checkout -- target` before committing if you like).
- `JsonValues` throws `NullPointerException` for a `null` node, exactly as `null.textValue()`
  did. It does not hide null references.
- `mapper.writeValue(OutputStream/Writer, x)` wraps the stream's `IOException` in the unchecked
  `tools.jackson.core.exc.JacksonIOException`. A method with a `throws IOException` contract for
  write failures should `catch (JacksonIOException e) { throw e.getCause(); }` (`getCause()` is
  typed `IOException`). hitorro-basefile `BaseFile.writeJson` does this; a test pins it.
- A Smile mapper writing to a `Writer` throws `UnsupportedOperationException` in both 2 and 3
  (hitorro-basefile `JsonSink` smile mode never worked; pinned, not fixed).
- hitorro-core 3.1.0 (already on the 4.0.0 base) dropped `hadoop-client`. A module that got Hadoop
  jars through core loses them: hitorro-streams-parquet's test could no longer *read* Parquet
  (`NoClassDefFoundError: org/apache/hadoop/mapreduce/lib/input/FileInputFormat`, needed by
  parquet-hadoop's reader). It now declares `hadoop-mapreduce-client-core` (test scope, YARN
  client/reload4j/Jetty excluded). If a downstream module reads Parquet, it must declare it too.
- hitorro-gittools and hitorro-luceneviewer also commit `target/`: stage `pom.xml src` explicitly.
- `ArrayNode.set(index, node)` out of range throws `JsonNodeException` (Jackson 3) instead of
  `IndexOutOfBoundsException`. hitorro-core `PAContext.setObjectOrArray` hits it, e.g. JVS
  `addLangText` on a doc without the array (it failed in 3.x too; pinned in jsontypesystem).
- Repos with committed `target/` (hitorro-core, hitorro-jsontypesystem): after building,
  `git checkout -- target && git clean -fdq target` before committing.
- hitorro-jsontypesystem tests read `../config` (hitorro-all layout) and the pom's
  `sync-type-configs` copies `../config/types` into `${hitorro.runtime.config.dir}` (default
  `../config`). In an isolated checkout `demoArticle` fails (baseline too). To run with config, copy
  `hitorro-all/config` next to a scratch copy of the repo and pass
  `-Dhitorro.runtime.config.dir=<scratch>` so nothing is written into hitorro-all.
- Jackson 3 exception messages for byte/stream input report `byte offset: #22` where Jackson 2 said
  `line: 1, column: 23`. Don't pin raw exception messages in golden tests; strip the location.
- `JsonMapper.builderWithJackson2Defaults()` keeps `FAIL_ON_EMPTY_BEANS` and 2.x date handling, but
  java.time is always available in Jackson 3: a 2.x mapper *without* JavaTimeModule threw
  `InvalidDefinitionException` on `Instant` etc., the 4.0.0 one writes timestamps (decimal seconds,
  `LocalDate` as an array). hitorro-util `Http` hit this; accepted and pinned as a deliberate difference.
- hitorro-util's build (like jsontypesystem's) copies `config/` into `${hitorro.runtime.config.dir}`
  (default `../config`), so building it in the workspace creates `~/hitorro-j3/config`.
- hitorro-base used `org.apache.commons.collections` (3.x) that came through hadoop-client from
  hitorro-core 3.0.x; with core 4.0.0 (no Hadoop) it no longer compiles. Declare
  `commons-collections:commons-collections:3.2.2`. Expect the same for other Hadoop-era transitive
  jars (commons-cli, commons-configuration, guava...) in repos still on core 3.0.x.
- Some repos pin HiTorro versions through a property (`<hitorro.version>3.0.2</hitorro.version>` in
  hitorro-index and siblings); bumping only explicit `<version>` tags leaves util 3.0.2 (and Jackson 2)
  on the classpath, with confusing "com.fasterxml JsonNode cannot be converted" errors.
- **Nesting depth: Jackson 3's default is 500 levels, Jackson 2.18's was 1000**, for reading and for
  writing a tree. Fixed in hitorro-core 4.0.0 (commit 362088f): `JsonMappers` applies the 2.18 limits
  (`JACKSON2_READ_CONSTRAINTS` / `JACKSON2_WRITE_CONSTRAINTS`). A mapper built any other way keeps
  Jackson 3's 500. The hitorro-streams-kafka/-nats golden tests pin depths 400/600/1200.
- calcite-core (through hitorro-jvssql) brings Jackson 2 (2.18.6). A BOM import in jvssql's pom does not
  pin it for consumers, so every module that depends on jvssql (hitorro-mesh-agent, -driver, ...)
  needs its own `com.fasterxml.jackson:jackson-bom` 2.21.8 import. With Jackson 2 on the classpath,
  a forgotten `com.fasterxml.jackson.databind` import still compiles: grep for it.
- Same in Jackson 2 and 3 (checked in hitorro-streams-nats): `writeValueAsBytes` escapes non-BMP
  characters as `\uD83D\uDE00` where `writeValueAsString` writes them raw; byte input with a
  UTF-16/UTF-8 BOM is auto-detected the same way; invalid UTF-8 and Latin-1 bytes fail in both.
- To pin a class whose encode/decode is inline (a sink's `add`, a source's iterator), move that code
  unchanged into a package-private static helper the class calls. Have the Jackson 2 generator call
  the 3.x class's own private `MAPPER` via reflection. (hitorro-streams-kafka/-nats did this.)
- Golden generators: some HiTorro code prints blank lines to stdout (hitorro-jsonts-mongo: 42 of them),
  so strip empty lines from the generator output before counting keys. Values built with
  `Date.toString()` depend on the default time zone: set UTC inside `compute()` and restore it.
- hitorro-jsonts-mongo's tests need MongoDB on 127.0.0.1:27017 (errors on main too without it): run
  `docker run -d --rm --name j3-mongo-test -p 127.0.0.1:27017:27017 mongo:7` for baseline and branch.
- **fabric8 kubernetes-client 6.13.x breaks on Jackson 2.19+**: serializing a resource with unknown fields
  (`additionalProperties`) throws `JsonMappingException` (NPE "keySerializer is null" in `AnyGetterWriter`).
  Reading still works. So a module with fabric8 must **not** take the 2.21.8 Jackson 2 pin: hitorro-mesh-k8s
  keeps 2.18.12, and a golden test round-trips a PodList through fabric8 to guard it. The same applies to any
  app that bundles fabric8 6.x (check `dependency:tree` for `io.fabric8`).
- Don't `git checkout -- pom.xml` to undo a probe edit while the 4.0.0 pom edits are still uncommitted: it
  reverts all of them. Commit first, or undo the probe with the same sed in reverse.
- **`JsonNode.toString()` / `toPrettyString()` fail past 500 levels on Jackson 3** (`StreamConstraintsException`,
  write `maxNestingDepth` 500 of Jackson's internal node serializer; `JsonMappers` does not reach it). Jackson 2.18
  printed up to 1000. Reading a 600-deep doc with `JsonMappers.json()` works; only `toString()` throws. Golden
  generators that print trees with `toString()` see a false difference: print with `JsonMappers.json().writeValueAsString(n)`.
  Main code that persists or sends `node.toString()` of deep trees must switch to the mapper (found in hitorro-objretrieval's golden test; its main code doesn't).
  Also: a **POJO node** inside `toString()` is written with Jackson 3 defaults (properties sorted, dates as ISO
  strings), unlike Jackson 2 and `JsonMappers`. Below 500 levels, with no POJO nodes, the output is byte-identical to
  `JsonMappers.json().writeValueAsString(n)` (pretty: `writerWithDefaultPrettyPrinter()`). Find call sites with
  `~/hitorro-j3/tools/JsonNodeToStringFinder.java` (javac-typed: `toString`, `toPrettyString`, `+` concat,
  `String.valueOf`, `append`/format args). The audit in `AUDIT-openrewrite.md` fixed 17 sites in 8 repos.
- **YAML scalar typing changed in Jackson 3 (silent).** tools.jackson `YAMLParser` hard-codes
  snakeyaml-engine's `JsonScalarResolver` and only `true`/`false` booleans, so unquoted `yes/no/on/off/y/n`,
  `0x1F`, `017`, `0b1`, `1_000`, `~`, `.5` became strings (Jackson 2: booleans/numbers/null).
  `configureForJackson2()` doesn't change it. Fix: hitorro-core `YamlMappers` (section 3.1).
- **`YAMLFactory.builder()` (with or without `configureForJackson2()`) leaves `EMPTY_STRING_AS_NULL` off**
  in 3.1.8, while `new YAMLFactory()` and Jackson 2 have it on: `v:` reads as `""` instead of null
  (YamlMappers and the section 3.1 snippet enable it).
- OpenRewrite can **drop mapper configuration**: in hitorro-mesh-pipelines it turned
  `new YAMLMapper().disable(FAIL_ON_UNKNOWN_PROPERTIES)` into a bare `new YAMLMapper()`. Diff removed
  `.disable/.enable/.configure` lines after running it.
- DB golden tests (hitorro-basedms): a generator without Jackson types compiles unchanged against the 3.x jar and 4.0.0, so
  record raw rows (JDBC, every table) + what 3.x reads back, then on 4.0.0 write-and-compare and wipe/insert/read-back. Set
  the default time zone to UTC (TIMESTAMP columns hold JVM local time); HT-serialized PSO payloads need their classes in the
  TypeManager (`addTypeIfAbsent`) or they are written as null. (Correction: basedms 3.1.2's pom IS published in hitorro-maven, checked; a
  local copy fetched as a bare jar lacks it. Resolve it normally, or use main's classpath with the jar.)

- **JUnit 4 tests silently don't run** in a repo whose test path gets JUnit 5 from hitorro-core: core's `groovy-all`
  brings `groovy-test-junit5` → `junit-jupiter-api/engine` 5.9.2 (compile/runtime), so surefire picks the JUnit Platform
  and "Tests run: 0" for JUnit 4 classes. Write new tests in JUnit 5 and declare `org.junit.jupiter:junit-jupiter`
  (test scope), or add `junit-vintage-engine` (hit in hitorro-logdigest).

- **Spring Boot 4.1.3 has `spring.jackson.use-jackson2-defaults`** (mapper `configureForJackson2()` plus Boot's old
  Jackson 2 defaults: ISO dates, FAIL_ON_UNKNOWN_PROPERTIES off, DEFAULT_VIEW_INCLUSION off) and
  `spring.jackson.factory.constraints.read/write.*` for the stream limits (defaults 500 / 100M). The factory-level
  `configureForJackson2()` has no property: add a `JsonFactoryBuilderCustomizer`. hitorro-spring-boot 4.0.0 sets all of
  this (lowest-precedence env defaults + `HitorroJacksonAutoConfiguration`), so apps on the starter need nothing.
- **App golden tests (j3-apps2, hitorro-jvs-example-springboot):** (1) A bare `new ObjectMapper()` in an app (NDJSON
  `StreamingResponseBody` writers, outgoing HTTP bodies) had *plain* Jackson 2 defaults, not Boot's: replace it with
  `JsonMappers.json()`, not Boot's mapper, or dates/unknown-property handling change on that path. (2) Responses built from
  `Map.of(...)` change key order between JVM runs on Jackson 2 too (salted iteration): record main 2-3 times and
  compare those sections ignoring key order only. (3) A JVS/library error message that embeds a Jackson exception
  message (`com.fasterxml...JsonParseException ... line: 1, column: 2`) now reads `tools.jackson.core.exc.StreamReadException
  ... byte offset: #UNKNOWN`; accepted and masked in that one section. (4) A `JsonFactoryBuilderCustomizer` with
  `@Order(LOWEST_PRECEDENCE)` setting `JsonMappers.JACKSON2_*_CONSTRAINTS` runs after Boot's own (pinned by a test).
- **Apps: Jackson exception text in error bodies differs** (j3-apps2). Handlers that return `e.getMessage()`
  (a generic `@ExceptionHandler(Exception.class)`, or a library error passed through) expose Jackson's own wording,
  which changed: `JsonParseException ... line: 1, column: 2` -> `StreamReadException ... byte offset`, "Cannot construct
  instance of `LinkedHashMap`..." -> "Cannot deserialize value of type...", and `withArray()` on an object node throws
  `JsonNodeException` instead of `UnsupportedOperationException`. Status and body shape stay the same; golden tests
  mask only that text (hitorro-jvs-example-springboot, hitorro-search-ui). Boot's own `/error` JSON is unchanged.
- **Actuator has its own isolated Jackson 3 mapper** (`management.endpoints.jackson.isolated-json-mapper`, default true)
  with Jackson 3 defaults, so `/actuator/health` turns `{"status":"UP","groups":[...]}` into `{"groups":[...],"status":"UP"}`
  (alphabetical). `spring.jackson.use-jackson2-defaults` doesn't reach it; set `isolated-json-mapper: false` so actuator
  uses Boot's configured mapper (hitorro-pr-bench golden). springdoc 3.0 (`/api-docs`) output was identical without changes.
- **`Locale` is written as a language tag on Jackson 3** (`"fr-CA"`, `"ja-JP-u-ca-japanese-x-lvariant-JP"`); Jackson 2
  wrote `toString()` (`"fr_CA"`). No feature switches it; map keys are still `toString()`, reading accepts both. Found by
  the hitorro-spring-boot REST golden; the starter registers a `ToStringSerializer` for Locale on Boot's mapper.
  Superseded: core d27ea01's `Jackson2JdkModule` restores it in `JsonMappers`; the starter now registers that module on
  Boot's mapper instead of its own serializer.
- REST golden tests across a Boot/Jackson switch: write the test without Jackson types (return `Object`, build nodes via
  `JVS.read`), record it on main with `-Dgolden.record=<file>` in a `git archive` copy, assert on the branch. Mask
  execution times, timestamps, identity hashes and stack frames; bodies built with `Map.of` change key order between JVM
  runs (also on main), compare those order-insensitively.
- **Actuator JSON is a second mapper (apps).** Boot 4's isolated actuator mapper
  (`JacksonEndpointAutoConfiguration`) is a plain Jackson 3 `JsonMapper.builder()` + NON_NULL: it **sorts properties**
  (`/actuator/health` → `{"groups":..,"status":"UP"}`) and `spring.jackson.use-jackson2-defaults` doesn't reach it.
  Boot's Jackson 2 one was `Jackson2ObjectMapperBuilder.json()` + ISO dates/durations + NON_NULL. Fix (no
  `@ConditionalOnMissingBean` on Boot's bean): `management.endpoints.jackson.isolated-json-mapper: false` plus your own
  `EndpointJsonMapper` bean (`JsonMappers.builder()` + disable `DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS` /
  `WRITE_DURATIONS_AS_TIMESTAMPS`, `FAIL_ON_UNKNOWN_PROPERTIES`, `DEFAULT_VIEW_INCLUSION`, NON_NULL inclusion). See
  hitorro-mesh-driver-app `Jackson2CompatConfig`. Apps on the hitorro-spring-boot starter should check theirs too.
- Golden REST for apps whose `main` jar doesn't start (Boot 4 optional-deps bug): record main from `target/classes` +
  `dependency:build-classpath` instead of the fat jar. A cluster harness (NATS in docker, several app JVMs) with typed
  placeholders and order-insensitive comparison learned from several main runs: hitorro-mesh-driver-app `src/test/golden`.

- **springdoc/swagger-core documents Jackson 3's `JsonNode` as a bean** (properties `array`, `empty`, `null`, `float`, ...)
  where it showed Jackson 2's as the free-form schema `{}`. Apps with springdoc: register a `ModelConverter` bean that
  resolves any `tools.jackson.databind.JsonNode` to `context.defineModel("JsonNode", new Schema<>())` + a `$ref`
  (hitorro-example-springboot `OpenApiConfig`); `/api-docs` is then byte-identical. Compare `/api-docs` main vs branch.
- App test profiles default `hitorro.ht-bin/ht-home` to `/Users/chris/hitorro` / `/Users/chris/hthome`: running an app's
  tests without `HT_BIN`/`HT_HOME` set writes startup logs into `~/hthome/logs`. Set both env vars (and `-D`) to a
  scratch copy of `~/hitorro/config` + `data` for baseline and branch.
- HiTorro's `ServiceContext` and `AIServiceRegistry` are JVM-global: a `@SpringBootTest` golden test's output depends on
  the test classes that ran before it in the same JVM, and a context pointing Ollama elsewhere changes later classes'
  `@EnabledIf(AIServiceRegistry.isAvailable)`. Run the golden in its own surefire execution and restore the registry.
- **Actuator health component order is random on Jackson 3.** `IndicatedHealthDescriptor` (a component with
  `show-details`) has getters only (`getStatus` inherited, `getDetails`). Jackson 2 wrote `status` first;
  Jackson 3 orders getter-only properties by the JVM's method order, which changes between runs (seen on 1 run
  in 3). Pin it on the endpoint mapper: `.addMixIn(IndicatedHealthDescriptor.class, Order.class)` with
  `@JsonPropertyOrder({"status","details"})` (hitorro-fleet-mail-analytics `Jackson2CompatConfig`). The same can
  hit any getter-only class you serialize; a REST golden with several runs of the new build catches it.
- An app without hitorro-core still needs core's mapper settings: a local copy of `JsonMappers`' builder
  (`builderWithJackson2Defaults()` factory + 2.18 constraints + `configureForJackson2()`) and of `JsonValues`
  (run the rewriter with its HELPER constant changed, and keep the copy itself out of the rewrite).

## 8. Public API changes by repo (for consumers)

- **hitorro-basefile 4.0.0**: package rename of all Jackson types in signatures; `JsonSink.mapper`
  (protected) is a shared immutable mapper (assign, don't configure); new protected `JsonSink.smile`.
  No throws changes; `BaseFile.writeJson` still throws the stream's `IOException`.
- **hitorro-jsontypesystem 4.0.0** (javap diff, complete): package rename of all Jackson types in
  signatures; `JVSVariableResolver.resolveVariableAux(TextNode, JVS)` → `(StringNode, JVS)`. Nothing
  added/removed, no throws changes. Behaviour: `TypeJsonLoader.load` parse error = `IOException`
  with `StreamReadException` cause (was `JsonParseException`, itself an IOException); `JVS.addLangText`
  failure class `IndexOutOfBoundsException` → `JsonNodeException`. Nodes JVS returns are Jackson 3
  nodes: consumers must use `JsonValues` instead of `textValue()/asText()/longValue()` on them.
- **hitorro-util 4.0.0** (javap diff, complete): only the package rename of Jackson types in
  signatures; no throws changes. Behaviour: `JsonFileEntityStore` failures are a plain `IOException`
  with the `JacksonException` as cause (was the Jackson exception itself); `Http` failures are
  `UncheckedIOException` whose cause is an `IOException` carrying the `JacksonException`; `Http` now
  serializes java.time (3.x failed).
- **hitorro-base 4.0.0** (javap diff, complete): only the package rename. Now declares
  commons-collections 3.2.2 (was transitive via Hadoop).
- **hitorro-kvstore 4.0.0**: package rename; `TypedKVStore(KVStore, Class, ObjectMapper)` takes a Jackson 3
  mapper; pass `JsonMappers.json()`/`JsonMappers.builder()...build()` to keep the stored format (a plain
  Jackson 3 `new ObjectMapper()` would change it). Stored bytes and reading are unchanged (pinned).
- **hitorro-index 4.0.0** (javap diff, complete): only the package rename (`JVSLuceneIndexWriter.indexDocuments(List<JVS>, List<JsonNode>)`,
  `LuceneProjectionContext.addField(String, JsonNode, ...)`, `FacetResult.toJVS()` etc.). Index contents unchanged (pinned).
- **hitorro-features 4.0.0**: package rename only (`JsonNode` in `MappingFunction.init`, `Feature.init`,
  `FeatureExtractor.init`/`props`, `ExtractorDefinition`, ...). No throws changes.
- **hitorro-jvssql 4.0.0** (javap diff, complete): package rename only (`PreparedQuery.asIterator/execute`,
  `withLateDataSink`, `ExternalMergeSort.sort`, `RexEvaluator`, ...). Result rows and structured UDF
  arguments are Jackson 3 nodes: read them with `JsonValues`. Brings Jackson 2 via calcite (see §7).
- **hitorro-streams-kafka / hitorro-streams-nats 4.0.0** (javap diff, complete): package rename only. The
  jvssql sinks' `writeRow` still throws `IOException` when a row can't be written (`JacksonException` is
  wrapped).
- **hitorro-mesh-agent 4.0.0**: no public Jackson types; no API change. **hitorro-mesh-driver 4.0.0**:
  package rename only (`ShufflePlacement.bucketFor`, `QueryHandle.nextRow/collect`).
- **hitorro-dedupe 4.0.0**: pom only, no API change.
- **hitorro-jsonts-mongo 4.0.0** (javap diff, complete): only the package rename. BSON written/read and queries unchanged (pinned).
- **hitorro-text-core 4.0.0** (javap diff, complete): package rename only (`JsonNode` in `init`/`execute`, `ArrayNode`/`ObjectNode` from `ExtractPOS`, `Json2Sentences`, `NERMarkupMapper.apply`, `TFRowVisitor.getRow`). No throws changes.
- **hitorro-mesh-orion, -streaming-kafka, -streaming-nats, -examples, -k8s 4.0.0** (javap diff, complete): no
  Jackson types in their public API; no API change. hitorro-mesh-k8s keeps Jackson 2 at 2.18.12 (fabric8, see §7).
- **hitorro-objretrieval 4.0.0** (javap diff, complete): only the package rename. Object-store bytes, wire stream, Solr posts and query parameters unchanged (pinned).
- **hitorro-mesh-pipelines 4.0.0** (javap diff, complete): package rename only (YAML via core's `YamlMappers`).
  `JobSpecYaml.parse` failures are a plain `IOException` with the JacksonException cause.
- **hitorro-core 4.0.0** (5d669de): added `com.hitorro.util.json.YamlMappers` (`builder()`, `yaml()`, `factory()`);
  `jackson-dataformat-yaml` optional.
- **hitorro-retrieval 4.0.0** (javap diff, complete): only the package rename (`DocumentStore.get` returns `Result<tools.jackson...JsonNode>`). Behaviour: a malformed remote search/stream response is an `IOException` with the `JacksonException` cause. YAML cluster configs keep Jackson 2 typing (core `YamlMappers.yaml()`).
- **hitorro-basedms 4.0.0** (javap diff, complete): package rename only. Stored rows unchanged and 3.1.2 rows read back the same on H2/PostgreSQL/MySQL (pinned).
- **hitorro-jsonsql 4.0.0** (javap diff, complete): package rename only. Result rows / `ObjectLatch` values are Jackson 3 nodes (read with `JsonValues`).
- **hitorro-mesh-agent-pipelines, -pipelines-jvstype, -pipelines-kvstore, -pipelines-lucene, -pipelines-sqlite 4.0.0**
  (javap diff, complete): no API changes beyond the package rename.
- **hitorro-analysis 4.0.0** (javap diff, complete): only the package rename (`SentimentUtil.getRawValues()` returns `AbstractIterator<tools.jackson...ObjectNode>`, `TermVectorsGenerator.setInfo(ObjectNode)`, `LDACommand.execute(..., JsonNode, ...)`). Output unchanged (pinned; vectorizer part needs the data dir).
- **hitorro-text-persistence 4.0.0** (javap diff, complete): package rename only. Brings Jackson 2 via Solr (objretrieval): consumers need their own `com.fasterxml.jackson:jackson-bom` 2.21.8 import.
- **hitorro-logdigest 4.0.0** (javap diff, complete): only the package rename. Binary log-line files unchanged (pinned).
- **hitorro-baseui 4.0.0**: pom only, no API change (no Jackson types; JSON via Tapestry JSONObject).
- **hitorro-conversation 4.0.0** (javap diff, complete): package rename only. Brings Jackson 2 via Solr (pin 2.21.8 in consumers).
- **hitorro-dataaquisition 4.0.0** (javap diff, complete): package rename only. Brings Jackson 2 via Solr (pin 2.21.8 in consumers).
- **hitorro-test 4.0.0** (javap diff, complete): package rename only.
- **hitorro-spring-boot 4.0.0** (javap diff): package rename (`SpringDatabaseConfigProvider.getDatabaseConfig/getHibernateConfig`, `SpringBootCommandLine.reloadJVSProps` return Jackson 3 nodes) + new `HitorroJacksonAutoConfiguration`. Behaviour: no Jackson 2 bridge; `preferred-json-mapper` no longer defaulted (apps that set `=jackson2` must drop it); REST format unchanged (pinned).
- **hitorro-spring-boot 4.0.0 (update 9f8ed23)**: registers core's `Jackson2JdkModule` on Boot's mapper; defaults `management.endpoints.jackson.isolated-json-mapper=false` and provides a Jackson 2-format `EndpointJsonMapper` (`HitorroEndpointJacksonAutoConfiguration`), so apps on the starter get Jackson 2 actuator JSON without their own config.
