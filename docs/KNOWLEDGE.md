# HiTorro: working knowledge

What has been learned working across the HiTorro repositories: how they fit together, how
to build, test and release them, and the traps already met. It is for people and agents
picking up work here. Keep it current: when you learn something non-obvious, add it.

- How the repos depend on each other, layer by layer: [DEPENDENCIES.md](DEPENDENCIES.md)
  (generated; regenerate after changing any pom, see below).
- Build commands and module overview: [../CLAUDE.md](../CLAUDE.md).

## 1. How the repositories fit together

- **One GitHub repo per module.** `geekychris/hitorro-all` (this repo) is an umbrella:
  each `hitorro-*` directory inside a checkout of it is its own git repository, cloned by
  `checkout-modules.sh`. There are 56 module repos.
- **The root pom (`hitorro-root`) only aggregates library modules.** Modules do not use it
  as their parent, so each module pom pins its own dependency versions. A version change
  means editing every module pom, not the root.
- **Version properties as well as `<version>` tags.** Poms refer to HiTorro versions
  through properties too (`hitorro-core.version`, `hitorro.util.version`, …). A bump that
  changes only `<version>` tags leaves the old version in use. A build whose `~/.m2`
  still holds the old version hides the miss, so check with an empty local repository
  (3.0.2 had to be republished for four modules because of this).
- **Default branch.** Most repos use `main`. These use `master`: hitorro-dms,
  hitorro-mesh-pipelines, hitorro-mesh-agent-pipelines and the four
  hitorro-mesh-pipelines-* repos (jvstype, kvstore, lucene, sqlite).
- **Repo names that differ from artifact names.** `hitorro-dms` publishes
  `hitorro-nosqldms-*`; `hitorro-spring-boot` publishes `hitorro-spring-boot-parent`,
  `-autoconfigure` and `-starter`. DEPENDENCIES.md lists every multi-artifact repo.
- **Applications** (Spring Boot, not consumed by other repos): hitorro-example-springboot,
  hitorro-jvs-example-springboot, hitorro-mesh-driver-app, hitorro-mesh-agent-app,
  hitorro-fleet-retrieval, hitorro-fleet-mail-analytics, hitorro-search-ui,
  hitorro-pr-bench, hitorro-dms.
- **Some repos commit build output and data**: `target/`, `data/` (RocksDB, H2),
  `node_modules/`, `dist/`. Stage source files only. Checkouts of those repos are slow.

## 2. Publishing: hitorro-maven

Releases go to `geekychris/hitorro-maven`, a Maven repository kept in git.

- **Consumers read it two ways:** over HTTPS as
  `https://raw.githubusercontent.com/geekychris/hitorro-maven/main`, or as a local
  checkout at `file://${user.home}/code/hitorro-maven`. A local checkout that is behind
  `origin/main` gives a stale view; pull it first.
- **Publishing changes what every consumer resolves.** Decide and announce a release
  before pushing it. Never overwrite a published version: release a new one.
- **How to publish one artifact:**
  1. Build the jar with tests passing.
  2. In a worktree of hitorro-maven `origin/main`, copy the jar and pom to
     `com/hitorro/<artifact>/<version>/<artifact>-<version>.{jar,pom}`.
  3. Add the version to `com/hitorro/<artifact>/maven-metadata.xml` (`<latest>`,
     `<release>`, `<versions>`, `<lastUpdated>`), or create that file for a new artifact.
     md5/sha1 files are gitignored.
  4. Commit as `<version>: <what changed> (<repo>#<pr>)` and push the branch to `main`.
- **Never `mvn install` a version that is already published.** It replaces the copy in
  `~/.m2` with your local build, and every other build on the machine then uses it.
  Restore from hitorro-maven if it happens. To build an app against unpublished
  libraries, use an isolated local repository (`-Dmaven.repo.local=…`).
- **Prove a release is complete** by building the consumers with an empty local
  repository and only hitorro-maven plus Maven Central available. A pass with a warm
  `~/.m2` proves nothing.

## 3. Releasing across layers

- Release in **layer order** from [DEPENDENCIES.md](DEPENDENCIES.md): a repo can only move
  to a new version of a dependency once that version is published.
- The **Affects** column says how much a release can break. hitorro-core reaches 53
  repos, hitorro-streams 50, hitorro-basefile 45 and hitorro-jsontypesystem 43.
- Bump every module of a multi-module repo together, plus the consumers' version
  properties.
- Libraries mixed across a breaking major version (for example 3.x and a 4.x that changes
  the JSON library) do not run together in one app; move an app's whole set at once.
- **Regenerate the dependency map** after changing poms, from fresh checkouts of every
  repo side by side:

  ```bash
  python3 scripts/dependency-map.py <dir-with-all-hitorro-repos> --maven ~/code/hitorro-maven
  ```

## 4. Technology state (November 2026)

- **Java 21.** Spring Boot **4.1.3** (Spring Framework 7.0.11) in every application and
  in hitorro-spring-boot; the move from 3.5 fixed Spring advisories that have no fix in
  Spring 6.2.
- **Boot 4 moved code into separate modules.** Use `spring-boot-starter-webmvc`,
  `spring-boot-webmvc-test`, `spring-boot-resttestclient`, the Flyway starter and
  `spring-boot-h2console`. Health classes are in `org.springframework.boot.health.contributor`.
  Use `@MockitoBean` instead of `@MockBean`.
- **Jackson 3 (HiTorro 4.0.0, November 2026).** Every HiTorro library is on Jackson 3
  (`tools.jackson` 3.1.8, the version Boot 4.1.3 manages; annotations stay
  `com.fasterxml.jackson.annotation` 2.21) and **keeps Jackson 2's formats**: what was written
  or accepted on 3.x still is. The full migration notes are in [JACKSON3.md](JACKSON3.md);
  the rules that matter day to day:
  - **Mappers come from hitorro-core, never `new ObjectMapper()`** (that compiles but has
    Jackson 3 defaults: sorted properties, ISO dates, unknown properties ignored, …).
    `JsonMappers.json()` / `builder()` / `smile()` give Jackson 2's defaults
    (`builderWithJackson2Defaults`), Jackson 2.18's stream limits (nesting 1000 for reading and
    writing, strings 20M; Jackson 3 lowered nesting to 500) and `Jackson2JdkModule`.
  - **YAML: `YamlMappers.yaml()` / `builder()`** (needs `jackson-dataformat-yaml`; optional in
    core). Jackson 3 types unquoted scalars by YAML 1.2, so `yes/on/0x1F/017/1_000/+12/~/.5`
    would silently become strings; YamlMappers keeps YAML 1.1 typing as in Jackson 2, plus
    `EMPTY_STRING_AS_NULL` (`YAMLFactory.builder()` turns it off) and the stream limits.
  - **`Jackson2JdkModule`** keeps Jackson 2's `Locale` (`"fr_CA"`, not `"fr-CA"`), `Month` and
    `byte[]`-tree behaviour. Every mapper not built from those builders must add it.
  - **`JsonNode` accessors through `JsonValues`** (`textValue`, `asText`, `asLong`, …): Jackson 3's
    accessors throw where Jackson 2 returned a default.
  - **Exceptions are unchecked** (`JacksonException`). Methods whose contract is `IOException`
    wrap them; `catch (IOException e)` around Jackson calls no longer catches parse errors.
  - **Don't persist or send `JsonNode.toString()`**: on Jackson 3 it throws past 500 levels of
    nesting (Jackson 2: 1000) and writes POJO nodes with Jackson 3 defaults. Write with
    `JsonMappers.json().writeValueAsString(node)`.
  - **Allowed Jackson 2 on the classpath:** only through third parties that need it (Hadoop,
    Avro, Solr, Calcite, Jena, fabric8, swagger-core/springdoc, structured-logging-java), pinned
    to 2.21.8 with `com.fasterxml.jackson:jackson-bom`; fabric8 6.x stays at 2.18.12 (it breaks
    on 2.19+). The integration check (`tools/integration-build.sh` in the migration workspace)
    fails anything else.
- **Spring Boot apps on Jackson 3, REST/JSON format unchanged.** The `spring-boot-jackson2`
  bridge and `preferred-json-mapper: jackson2` / `spring.jackson2.*` are gone. Instead:
  - `spring.jackson.use-jackson2-defaults: true` (Jackson 2's defaults plus Boot's old ones:
    ISO dates, unknown properties ignored, default view off) and
    `spring.jackson.factory.constraints.read/write.max-nesting-depth: 1000`,
    `read.max-string-length: 20000000`; the factory-level `configureForJackson2()` needs a
    `JsonFactoryBuilderCustomizer`, and Boot's mapper needs `Jackson2JdkModule`.
  - **Actuator has its own mapper** that sorts keys (`/actuator/health` →
    `{"groups":…,"status":"UP"}`): set `management.endpoints.jackson.isolated-json-mapper: false`
    and provide a `@Primary` `EndpointJsonMapper` in Jackson 2's format (status before details).
  - hitorro-spring-boot's starter (`HitorroJacksonAutoConfiguration`) does all of this; apps
    without the starter carry the same configuration (e.g. hitorro-mesh-driver-app
    `Jackson2CompatConfig`). A bare `new ObjectMapper()` inside an app becomes `JsonMappers.json()`.
  - springdoc documents Jackson 3's `JsonNode` as a bean: register a `ModelConverter` that maps it
    to the free-form schema `{}`.
- **Golden tests are the proof of format.** Each migrated repo has a golden test comparing what
  it writes, reads and sends (files, wire messages, REST responses, Lucene fields, BSON, YAML)
  with output recorded from the last Jackson 2 release, generated by running the real 3.x code,
  not typed by hand. Record apps on `main` (`-Dgolden.record`), several runs, to find
  run-dependent values; mask times, ids and hashes; compare `Map.of` bodies order-insensitively;
  keep each accepted difference in its own file with the reason.
- **Hibernate 7.4** (required by Boot 4). hitorro-basedms 3.1.x is ported to it:
  interceptor and MERGE listener, `persist` / `merge` / `remove`, version sync after
  merge, indexes declared in `@Table(indexes = …)`.
- **Spring AI 2.0.3** with Ollama (`spring.ai.ollama.chat.model`, e.g. `llama3.2`). Always
  set `spring.http.clients.connect-timeout` / `read-timeout` and `spring.ai.retry.*`: the
  default of 10 retries turns an unreachable Ollama into a hang of several minutes.
- **Logging.** hitorro-core declares `slf4j-reload4j` (it used to arrive through
  Hadoop). Spring Boot apps must exclude it from HiTorro dependencies (it fights logback)
  and add `log4j-over-slf4j` where HiTorro calls the log4j 1 API.

## 5. File systems and S3 (hitorro-basefile)

- **Hadoop is optional.** Since 3.1.0, S3 is served by the AWS SDK v2 directly (`S3File`,
  `S3Path`, `S3MultipartOutputStream`, `HTS3FileSystem`), with no Hadoop dependency. The
  Hadoop file systems are used only when Hadoop is on the class path
  (`BaseFileSystem.HADOOP_AVAILABLE`); otherwise those protocols resolve to
  `UnavailableFileSystem` with a clear error.
- **S3-compatible stores** (MinIO, SeaweedFS, Ceph, other clouds' S3 endpoints) go through
  `S3CompatibleFileSystem`: path-style addressing and checksums only when required.
  `MinioProtocolAdapter` gives one file system per bucket.
- **Configuration**: `s3://` and `s3a://` URLs; endpoint from the `hitorro.s3.endpoint`
  system property or `HITORRO_S3_ENDPOINT`; per-URL settings with the `@@` inline syntax
  (`S3PropertyFactory`).
- **New protocols are plug-ins.** Implement `ProtocolAdapter` and list it in
  `META-INF/services` (ServiceLoader); see `TestMemProtocol` in the tests.
- **AWS SDK ≥ 2.30 checksums corrupt objects** on SeaweedFS and some MinIO/Ceph
  versions (the aws-chunked CRC trailer is stored as part of the object). Set
  `requestChecksumCalculation` and `responseChecksumValidation` to `WHEN_REQUIRED` for
  any non-AWS endpoint.
- **S3 "directories" differ between stores.** On SeaweedFS a HEAD on a directory
  returns an object, and directory markers survive deletes. `isDir` checks children and
  the marker; deletes remove markers deepest first.
- **Jetty from Hadoop and Solr.** Hadoop (even 3.5) brings Jetty 9.4 and Solr 9 brings
  Jetty 10; both are end of life with known vulnerabilities and no public fixes. Exclude
  `org.eclipse.jetty:*` from those dependencies (hitorro-objretrieval,
  hitorro-streams-parquet) rather than pinning versions.
- **hitorro-mesh-agent-app** still reads Parquet through Hadoop's S3A: keep `hadoop-aws`
  and `hadoop-common` on the same version (3.4.3), and use the individual AWS SDK modules
  (s3, s3-transfer-manager, sts) instead of the 690 MB bundle.

## 6. Databases (hitorro-basedms)

- Tested on **H2, PostgreSQL 17 and MySQL 8.4** (Testcontainers matrix since 3.1.2).
- **Index names must be unique per schema** on PostgreSQL and H2. basedms names them per
  table (`user_t_name_idx`, `content_guid_idx`); reused names meant indexes were silently
  not created. `NamingConsistencyTest` guards this.
- **Two SessionFactories.** basedms builds its own Hibernate SessionFactory
  (`HibernateService`) next to Spring's. Settings that change naming or quoting must
  match in both: `hibernate.globally_quoted_identifiers` must stay off in the apps'
  Postgres profile. hitorro-spring-boot's `SpringDatabaseConfigProvider` does not yet
  pass Spring's naming and quoting settings to basedms (open).
- Apps on PostgreSQL need `org.postgresql:postgresql` at runtime scope.
- Known old bug: `RssFeedIn.upgradeAllInstances` writes columns that are not persisted.

## 7. Testing

- **Testcontainers 2.0.5** with Rancher Desktop on the Mac needs
  `DOCKER_HOST=unix://$HOME/.rd/docker.sock` and `TESTCONTAINERS_RYUK_DISABLED=true`.
- MinIO images could not be pulled; S3 tests use SeaweedFS (`chrislusf/seaweedfs:3.99`)
  with an `s3.json` identity (unsigned requests are refused).
- hitorro-example-springboot tests need per-context KV store and Lucene directories.
  About 34 of its tests fail on `main`; compare failing-test sets with `main` (exact
  test names, line by line) rather than counting.
- Some tests write to `~/hitorro-fs/config`; remove it after a run.
- `hitorro.kvstore.path` must be absolute or under a writable directory: the example app
  uses `${HT_HOME:.}/data/kvstore`.

## 8. Working practices

- **Work in worktrees or fresh clones**, not in a checkout where someone has uncommitted
  work.
- **Branch builds for review** run as cloud-stack sandboxes (`deploy/hitorro/sandbox.sh`
  in cloud-stack; see its docs/SANDBOXES.md).
- **Vulnerability scanning.** cloud-stack's vulnerability registry scans each repo's own
  poms. It does not follow dependencies through internal `com.hitorro` libraries, so a
  vulnerable library that arrives through a HiTorro dependency shows up only in the repo
  that declares it. Its inventory step rewrites poms in place, so only run it on a copy.
- **Pull requests**: one per repo; library PRs merge and publish before the consumers
  that need them.
