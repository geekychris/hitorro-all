#!/usr/bin/env python3
"""Generate docs/DEPENDENCIES.md: how the HiTorro repos depend on each other.

Usage:
    python3 scripts/dependency-map.py [MODULES_DIR] [--maven HITORRO_MAVEN_CHECKOUT] [--out FILE]

MODULES_DIR holds the hitorro-* repos side by side (default: this repo's root, where
checkout-modules.sh puts them). Use fresh checkouts of each repo's default branch:
the map reflects whatever is on disk. --maven reads the latest published version of
each artifact from origin/main of a hitorro-maven checkout (it runs `git fetch`).

Layer 0 depends on no other HiTorro repo; layer N depends only on layers below N.
Release in layer order: a repo can only move to a new version of a dependency once
that dependency is published.
"""
import argparse, os, re, subprocess, sys
import xml.etree.ElementTree as ET
from collections import defaultdict

NS = {"m": "http://maven.apache.org/POM/4.0.0"}
SKIP = {"target", "node_modules", ".git", "data", "dist", "src", ".idea"}


def text(el, path):
    x = el.find(path, NS)
    return x.text.strip() if x is not None and x.text else None


def scan(root):
    repos, owner = {}, {}
    for repo in sorted(os.listdir(root)):
        rdir = os.path.join(root, repo)
        if not repo.startswith("hitorro-") or not os.path.isfile(os.path.join(rdir, "pom.xml")):
            continue
        info = dict(arts=[], deps=set(), version=None, boot=None, jackson=0, kind="library")
        for dp, dn, fn in os.walk(rdir):
            dn[:] = [d for d in dn if d not in SKIP]
            if "pom.xml" not in fn:
                continue
            p = os.path.join(dp, "pom.xml")
            try:
                t = ET.parse(p).getroot()
            except ET.ParseError:
                continue
            if dp == rdir:
                info["version"] = text(t, "m:version") or text(t, "m:parent/m:version")
            if text(t, "m:parent/m:artifactId") == "spring-boot-starter-parent":
                info["boot"] = text(t, "m:parent/m:version")
            for d in t.iterfind(".//m:dependencyManagement//m:dependency", NS):
                if text(d, "m:artifactId") == "spring-boot-dependencies":
                    v = text(d, "m:version") or ""
                    if v.startswith("${"):
                        v = text(t, "m:properties/m:" + v[2:-1]) or v
                    info["boot"] = v
            for pl in t.iterfind(".//m:plugin", NS):
                if text(pl, "m:artifactId") == "spring-boot-maven-plugin":
                    info["kind"] = "app"
            info["arts"].append(text(t, "m:artifactId"))
            for d in t.iterfind(".//m:dependency", NS):
                if (text(d, "m:groupId") or "").startswith("com.hitorro"):
                    info["deps"].add(text(d, "m:artifactId"))
        for dp, dn, fn in os.walk(rdir):
            dn[:] = [d for d in dn if d not in SKIP - {"src"}]
            if "/src/main/" not in dp + "/":
                continue
            for f in fn:
                if f.endswith(".java"):
                    try:
                        # Jackson 2 proper: com.fasterxml.jackson.annotation is shared with Jackson 3
                        if re.search(r"com\.fasterxml\.jackson\.(?!annotation\b)", open(os.path.join(dp, f), errors="ignore").read()):
                            info["jackson"] += 1
                    except OSError:
                        pass
        repos[repo] = info
        for a in info["arts"]:
            owner[a] = repo
    for repo, info in repos.items():
        info["needs"] = sorted({owner[a] for a in info["deps"] if a in owner and owner[a] != repo})
        info["unknown"] = sorted(a for a in info["deps"] if a not in owner)
    return repos


def layers(repos):
    out = {}

    def depth(r, path=()):
        if r in out:
            return out[r]
        if r in path:
            sys.exit("dependency cycle: " + " -> ".join(path + (r,)))
        out[r] = 0 if not repos[r]["needs"] else 1 + max(depth(x, path + (r,)) for x in repos[r]["needs"])
        return out[r]

    for r in repos:
        depth(r)
    return out


def published(maven, artifacts):
    if not maven:
        return {}
    subprocess.run(["git", "-C", maven, "fetch", "-q", "origin"], check=False)
    got = {}
    for a in artifacts:
        r = subprocess.run(["git", "-C", maven, "show", f"origin/main:com/hitorro/{a}/maven-metadata.xml"],
                           capture_output=True, text=True)
        m = re.search(r"<release>([^<]+)</release>", r.stdout) or re.search(r"<latest>([^<]+)</latest>", r.stdout)
        if m:
            got[a] = m.group(1)
    return got


def main():
    ap = argparse.ArgumentParser()
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("root", nargs="?", default=here)
    ap.add_argument("--maven")
    ap.add_argument("--out", default=os.path.join(here, "docs", "DEPENDENCIES.md"))
    a = ap.parse_args()

    repos = scan(a.root)
    lay = layers(repos)
    users = defaultdict(set)
    for r, info in repos.items():
        for n in info["needs"]:
            users[n].add(r)
    allpub = published(a.maven, sorted({x for i in repos.values() for x in i["arts"]}))
    pub = {}
    for r, i in repos.items():
        for x in [r] + i["arts"]:
            if x in allpub:
                pub[r] = allpub[x]; break

    def closure(r):
        seen, todo = set(), [r]
        while todo:
            for u in users[todo.pop()]:
                if u not in seen:
                    seen.add(u); todo.append(u)
        return seen

    L = []
    L.append("# HiTorro repository dependencies\n")
    L.append("Generated by `python3 scripts/dependency-map.py` — do not edit by hand. "
             "Background and procedures: [KNOWLEDGE.md](KNOWLEDGE.md).\n")
    L.append("- **Layer**: 0 depends on no other HiTorro repo; layer N depends only on lower layers. "
             "Release in layer order.")
    L.append("- **Needs**: the HiTorro repos it declares in its poms.")
    L.append("- **Affects**: how many repos depend on it directly or indirectly (what a release of it can break).")
    L.append("- **Jackson**: main-source files using Jackson 2 (`com.fasterxml.jackson`, except the annotations Jackson 3 shares).")
    if pub:
        L.append("- **Published**: latest version in hitorro-maven `origin/main`.")
    L.append("")
    hdr = "| Layer | Repo | Kind | Version | " + ("Published | " if pub else "") + "Boot | Jackson | Affects | Needs |"
    L.append(hdr)
    L.append("|" + "|".join(["---"] * (hdr.count("|") - 1)) + "|")
    for r in sorted(repos, key=lambda x: (lay[x], x)):
        i = repos[r]
        row = [str(lay[r]), r, i["kind"], i["version"] or "?"]
        if pub:
            row.append(pub.get(r, "—"))
        row += [i["boot"] or "—", str(i["jackson"]), str(len(closure(r))), ", ".join(x.replace("hitorro-", "") for x in i["needs"]) or "—"]
        L.append("| " + " | ".join(row) + " |")
    multi = {r: i["arts"] for r, i in repos.items() if len(i["arts"]) > 1}
    if multi:
        L.append("\n## Repos that publish several artifacts\n")
        for r, arts in sorted(multi.items()):
            L.append(f"- **{r}**: " + ", ".join(f"`{x}`" for x in arts))
    unknown = {r: i["unknown"] for r, i in repos.items() if i["unknown"]}
    if unknown:
        L.append("\n## Internal artifacts no scanned repo publishes\n")
        for r, u in sorted(unknown.items()):
            L.append(f"- **{r}** needs " + ", ".join(f"`{x}`" for x in u))
    with open(a.out, "w") as f:
        f.write("\n".join(L) + "\n")
    print(f"wrote {a.out}: {len(repos)} repos, {max(lay.values()) + 1} layers")


if __name__ == "__main__":
    main()
