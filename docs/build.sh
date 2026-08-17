#!/usr/bin/env bash
# Render the whole HiTorro doc set to HTML + PDF.
#
# Strategy:
#   1. If native `asciidoctor` + `asciidoctor-pdf` are on PATH, use them
#      (fast — < 1s for the book, no JVM warm-up).
#   2. Else if `docker` is on PATH, use the asciidoctor/docker-asciidoctor
#      image (works without a local Ruby install).
#   3. Else fall back to Maven + asciidoctorj-pdf (slowest, ~40s startup,
#      but works with just JDK — invoke via  mvn -f docs/pom.xml package).
#
# Outputs:
#   docs/target/generated-docs/{html,pdf}/hitorro-book.{html,pdf}
#
# Flags:
#   --pdf-only    skip HTML
#   --html-only   skip PDF
#   --serve       after render, serve the html output via `python3 -m http.server 9090`
set -euo pipefail
cd "$(dirname "$0")"

WANT_HTML=1
WANT_PDF=1
SERVE=0
for a in "$@"; do
    case "$a" in
        --pdf-only)  WANT_HTML=0 ;;
        --html-only) WANT_PDF=0 ;;
        --serve)     SERVE=1 ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "unknown arg: $a — try --help" >&2; exit 2 ;;
    esac
done

BOOK="hitorro-book.adoc"
OUT="target/generated-docs"
HTML_OUT="$OUT/html"
PDF_OUT="$OUT/pdf"
mkdir -p "$HTML_OUT" "$PDF_OUT"

info() { printf "\033[1;34m→\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$*"; }

# Common attributes — must match docs/pom.xml so both paths render identically.
ATTRS=(
    -a source-highlighter=rouge
    -a icons=font
    -a sectnums
    -a sectanchors
    -a toc=left
    -a toclevels=3
    -a docinfo=shared
    -a revdate="$(date +%Y-%m-%d)"
)

render_native() {
    if [[ $WANT_HTML -eq 1 ]]; then
        info "asciidoctor → HTML"
        asciidoctor "${ATTRS[@]}" -b html5 -D "$HTML_OUT" "$BOOK"
        ok "$HTML_OUT/${BOOK%.adoc}.html"
    fi
    if [[ $WANT_PDF -eq 1 ]]; then
        info "asciidoctor-pdf → PDF"
        asciidoctor-pdf "${ATTRS[@]}" -D "$PDF_OUT" "$BOOK"
        ok "$PDF_OUT/${BOOK%.adoc}.pdf"
    fi
}

render_docker() {
    local repo_root
    repo_root=$(cd .. && pwd)   # so include::../hitorro-*/docs/... resolves
    local image="asciidoctor/docker-asciidoctor:latest"
    info "pulling $image (first run only)"
    docker pull -q "$image" >/dev/null
    if [[ $WANT_HTML -eq 1 ]]; then
        info "asciidoctor (docker) → HTML"
        docker run --rm -v "$repo_root":/documents/ "$image" \
            asciidoctor "${ATTRS[@]}" -b html5 \
                -D "docs/$HTML_OUT" "docs/$BOOK"
        ok "$HTML_OUT/${BOOK%.adoc}.html"
    fi
    if [[ $WANT_PDF -eq 1 ]]; then
        info "asciidoctor-pdf (docker) → PDF"
        docker run --rm -v "$repo_root":/documents/ "$image" \
            asciidoctor-pdf "${ATTRS[@]}" \
                -D "docs/$PDF_OUT" "docs/$BOOK"
        ok "$PDF_OUT/${BOOK%.adoc}.pdf"
    fi
}

render_maven() {
    local profile=""
    [[ $WANT_HTML -eq 0 ]] && profile="-Ppdf-only"
    [[ $WANT_PDF  -eq 0 ]] && profile="-Phtml-only"
    info "mvn -f pom.xml package $profile"
    mvn -f pom.xml package $profile
    ok "$(pwd)/target/generated-docs"
}

if command -v asciidoctor >/dev/null 2>&1 \
   && { [[ $WANT_PDF -eq 0 ]] || command -v asciidoctor-pdf >/dev/null 2>&1; }; then
    render_native
elif command -v docker >/dev/null 2>&1; then
    render_docker
else
    render_maven
fi

if [[ $SERVE -eq 1 && $WANT_HTML -eq 1 ]]; then
    info "serving on http://localhost:9090/${BOOK%.adoc}.html — Ctrl+C to stop"
    cd "$HTML_OUT"
    python3 -m http.server 9090
fi
