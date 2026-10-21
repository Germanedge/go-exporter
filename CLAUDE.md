# go-exporter

Prometheus metrics exporter shipped as a **base image**, not as a running
service. Consumers pull the binary out via multi-stage copy (see `README.md`);
nothing here is ever started from this image.

## Layout

| File | Purpose |
| --- | --- |
| `main.go` | the whole exporter — `/metrics` and `/service-name` endpoints |
| `Dockerfile` | `golang` build stage → `FROM scratch` final stage |
| `service.json` | release metadata; `base_images[].version` must track the `Dockerfile` tag |
| `azure-pipelines.yml` | extends `azure-pipelines-docker-template.yml` from `Germanedge/azure-pipelines-templates` |

## Build

Default port 9132, set via env in `ge-ubuntu-base`; override with
`GO_EXPORTER_PORT`. Built with `CGO_ENABLED=0` — the binary must stay fully
static, since the final stage is `scratch` and offers no libc, no shell, and no
CA bundle.

Three properties of the `Dockerfile` are load-bearing. Each exists for a reason
that is not obvious from reading it:

- **The final `FROM scratch` stage is a security boundary, not a size
  optimisation.** The `golang` image inherits `buildpack-deps` (curl,
  openssh-client, git, subversion, gnupg), and a single-stage build published
  every one of those OS packages. **Do not collapse the stages back into one.**
- **`GOFLAGS=-mod=readonly` plus `COPY go.mod go.sum` plus `go mod download`**
  is what makes the committed lockfile authoritative. The previous
  `go get <module path>` resolved dependencies fresh inside the image, which
  silently discarded `go.sum` and made Dependabot's gomod PRs cosmetic.
- **`-trimpath`** keeps builds byte-reproducible across checkouts. Dropping it
  reintroduces embedded local paths.

The build context is an allowlist in `.dockerignore` — exactly the three files
the build copies. Adding a source file means adding it there too.

### What `scratch` does and does not provide

The image is a transport container: consumers `COPY --from` the binary into
their own image and run it there, so `scratch` is not the exporter's runtime.
It is runnable on its own anyway — `ENTRYPOINT` is declared for that reason.

Nothing is currently missing. `CGO_ENABLED=0` makes the binary fully static, so
no libc or dynamic linker is needed, and the pure-Go DNS resolver needs no
`nsswitch.conf`. The `ProcessCollector` that `client_golang` registers into the
default registry reads `/proc/self/*`, but `/proc` is mounted by the container
runtime rather than supplied by the image, so it works under `scratch` too.

**The one thing to watch:** `scratch` has no CA bundle. `main.go` only calls
`http.ListenAndServe` — plain HTTP, inbound only — so none is needed today. The
moment anything here makes an outbound HTTPS call or serves TLS, certificate
verification fails with `x509: certificate signed by unknown authority`, and
the fix is to carry the bundle over from the build stage:

```dockerfile
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
```

The same applies to `time.LoadLocation`, which would need
`/usr/share/zoneinfo`, or to anything expecting `/tmp` or `/etc/passwd`.

## Security

CVE handling and the full finding history live in
**[`docs/security-issues.md`](docs/security-issues.md)** — grouped by root
cause, with advisory links, Jira keys and the fix per group.

Two rules follow from that document, and they decide where a fix belongs:

- **Impact path contains `/github.com/golang/go`** → the CVE is compiled into
  the binary. Only a `golang` build-stage bump fixes it. Verify against the
  OSV Go database before bumping, since Xray lags:
  `curl -s -X POST -d '{"package":{"name":"stdlib","ecosystem":"Go"},"version":"1.27.3"}' https://api.osv.dev/v1/query`
- **Any OS package (curl, openssh, git, …)** → build stage only, already
  excluded by the `scratch` stage. Close as not-applicable; do not bump Go for it.

`go-exporter` has no Jira project. Findings arrive as `ge-ubuntu` Xray tickets
whose description carries an impact path through `/usr/bin/go-exporter/`:

```
project = GE4 AND labels = "ge-ubuntu" AND resolution = Unresolved
```

Jira is at `https://jira.germanedge.com` (Server/DC, REST API v2, bearer token).
Credentials live in `D:\germanedge\iac\tf-aws-533267348045-development\.env`
as `JIRA_PAT` / `JIRA_URL` — never echo or commit them.

## Known open items

- **`go mod tidy` has never been run against the current dependency set.**
  `gorilla/mux` was removed as a provably unused direct requirement, but the
  indirect block still lists `matttproud/golang_protobuf_extensions/v2` and
  `grafana/regexp`, which look like leftovers from older
  `prometheus/client_golang` releases. Verifying that needs a Go toolchain:
  run `go mod tidy` and review the diff — do not hand-edit the indirect block,
  since removing a genuinely needed indirect breaks the build only at
  `go mod download` time.
- The two Azure pipelines pin `GoTool@0` to Go **1.25.0** while the image
  builds with **1.27.3**, so tests and SonarQube run against a different stdlib
  than the one that ships. `service.json:base_images` is filled by CI and needs
  no manual edit, but these two pins still drift by hand.
- [GE4-24379](https://jira.germanedge.com/browse/GE4-24379) — architectural
  decision pending on whether `go-exporter` stays standalone or moves into
  `ge-ubuntu-generic`. Java images do not use it at all.
