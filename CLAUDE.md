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

The final stage exists for a security reason, not a size reason: the `golang`
image inherits `buildpack-deps` (curl, openssh-client, git, subversion, gnupg),
and a single-stage build published every one of those OS packages. **Do not
collapse the stages back into one.**

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

- `go.sum` is not copied into the build stage; `go get` resolves dependencies
  unverified against the proxy, so builds are neither reproducible nor
  supply-chain protected. Fix: `COPY go.sum .` + `go mod download`.
- [GE4-24379](https://jira.germanedge.com/browse/GE4-24379) — architectural
  decision pending on whether `go-exporter` stays standalone or moves into
  `ge-ubuntu-generic`. Java images do not use it at all.
