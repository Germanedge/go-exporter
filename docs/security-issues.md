# Security Issues

Tracked CVEs for `go-exporter`, grouped by root cause. Details are not duplicated
here — follow the advisory links.

**Two attack surfaces, two different fixes:**

| Layer | Where Xray sees it | Fixed by |
| --- | --- | --- |
| **OS packages** | Debian packages inherited from `buildpack-deps` via the `golang` image | final `FROM scratch` stage — the build stage is discarded and never published |
| **Go stdlib / toolchain** | compiled into the binary, impact path `/usr/bin/go-exporter/github.com/golang/go` | bumping the `golang` build-stage tag |

`go-exporter` has no Jira project of its own. Findings surface as `ge-ubuntu`
Xray tickets whose *Impact Path* contains `/usr/bin/go-exporter/`.
JQL: `project = GE4 AND labels = "ge-ubuntu" AND resolution = Unresolved`.

---

## 1. curl — credential leak on handle/connection reuse

**Severity:** Critical (CVSS 9.8 / 9.1) · **Jira:** none
**CVEs:** [CVE-2026-19931](https://curl.se/docs/CVE-2026-19931.html),
[CVE-2026-11856](https://curl.se/docs/CVE-2026-11856.html),
[CVE-2026-9079](https://curl.se/docs/CVE-2026-9079.html),
[CVE-2026-8927](https://curl.se/docs/CVE-2026-8927.html)

libcurl carries Negotiate/Digest/proxy credentials across an origin or proxy
switch, sending `Authorization:` / `Proxy-Authorization:` to the wrong host.

**Fix:** none needed in curl. `curl` comes from `buildpack-deps:trixie-curl`
underneath the `golang` image and only ever existed in the build stage. The
`FROM scratch` final stage stops publishing it. Debian trixie ships 8.14.1 and
has these postponed; upstream fixes land in 8.21.0/8.22.0 — so neither a rebuild
nor a Go bump would have helped.

## 2. curl — HTTP/2 use-after-free

**Severity:** Critical (CVSS 9.8 / 9.1) · **Jira:** none
**CVEs:** [CVE-2026-10536](https://curl.se/docs/CVE-2026-10536.html),
[CVE-2026-18924](https://curl.se/docs/CVE-2026-18924.html)

UAF via `CURLOPT_STREAM_DEPENDS` + `curl_easy_reset()`/`cleanup()`, and via
HTTP/2 Server Push on shared connections.

**Fix:** same as group 1 — removed with the build stage.

## 3. curl — credential and cookie scope

**Severity:** Critical (CVSS 9.1) · **Jira:** none
**CVEs:** [CVE-2026-8926](https://curl.se/docs/CVE-2026-8926.html),
[CVE-2026-8924](https://curl.se/docs/CVE-2026-8924.html)

`.netrc` lookup can return another user's password; cookie parsing allows
"super cookies" past the Public Suffix List check.

**Fix:** same as group 1 — removed with the build stage.

## 4. OpenSSH — client use-after-free

**Severity:** Critical (CVSS 9.4 NVD / 7.7 MITRE) · **Jira:** none
**CVE:** [CVE-2026-60002](https://www.openssh.org/releasenotes.html#10.4p1)

Client-side UAF when a server swaps its host key during key re-exchange.

**Fix:** `openssh-client` comes from `buildpack-deps:trixie-scm`, build stage
only. Removed by the `FROM scratch` stage. Debian trixie ships 10.0p1 and has it
postponed; upstream fix is OpenSSH 10.4.

---

## 5. Go net/http — HTTP/2 DoS and protocol handling

**Severity:** Critical / High · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64493](https://jira.germanedge.com/browse/GE4-64493) +
[GE4-64489](https://jira.germanedge.com/browse/GE4-64489) (dup),
[GE4-64479](https://jira.germanedge.com/browse/GE4-64479),
[GE4-64487](https://jira.germanedge.com/browse/GE4-64487),
[GE4-64478](https://jira.germanedge.com/browse/GE4-64478),
[GE4-64485](https://jira.germanedge.com/browse/GE4-64485),
[GE4-64491](https://jira.germanedge.com/browse/GE4-64491)
**CVEs:** CVE-2026-78663 ([GO-2026-6612](https://pkg.go.dev/vuln/GO-2026-6612)),
CVE-2026-78659 ([6603](https://pkg.go.dev/vuln/GO-2026-6603)),
CVE-2026-78660 ([6610](https://pkg.go.dev/vuln/GO-2026-6610)),
CVE-2026-78667 ([6609](https://pkg.go.dev/vuln/GO-2026-6609)),
CVE-2026-78669 ([6611](https://pkg.go.dev/vuln/GO-2026-6611)),
CVE-2026-97032 ([6617](https://pkg.go.dev/vuln/GO-2026-6617))

Double flow-control refund, Trailer-header memory exhaustion, malformed framing
headers accepted, unbounded Range parsing, CPU burn on window changes, HPACK
encoder race. **Fix:** build-stage bump to `golang:1.27.3`.

## 6. Go net/http — HTTP/1 connection desynchronization

**Severity:** High · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64483](https://jira.germanedge.com/browse/GE4-64483),
[GE4-64481](https://jira.germanedge.com/browse/GE4-64481)
**CVEs:** CVE-2026-56866 ([GO-2026-6605](https://pkg.go.dev/vuln/GO-2026-6605)),
CVE-2026-94439 ([GO-2026-6613](https://pkg.go.dev/vuln/GO-2026-6613))

Client desync after a rejected CONNECT; server desync after a 2xx CONNECT
response. **Fix:** build-stage bump to `golang:1.27.3`.

## 7. Go html/template — context tracking

**Severity:** High · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64486](https://jira.germanedge.com/browse/GE4-64486),
[GE4-64488](https://jira.germanedge.com/browse/GE4-64488)
**CVEs:** CVE-2026-94448 ([GO-2026-6599](https://pkg.go.dev/vuln/GO-2026-6599)),
CVE-2026-97030 ([GO-2026-6600](https://pkg.go.dev/vuln/GO-2026-6600))

Context tracking reset across consecutive template expressions; `yield` not
recognized as a regexp-preceder keyword. **Fix:** build-stage bump to
`golang:1.27.3`. Not reachable from this codebase — `go-exporter` does not use
`html/template` — but Xray flags it from the linked stdlib regardless.

## 8. Go crypto/tls — malformed ECH outer extensions

**Severity:** High · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64446](https://jira.germanedge.com/browse/GE4-64446)
**CVE:** CVE-2026-97031 ([GO-2026-6607](https://pkg.go.dev/vuln/GO-2026-6607))

Malformed ECH outer extension references are not rejected.
**Fix:** build-stage bump to `golang:1.27.3`.

## 9. Go net/textproto, mime — MIME memory limit bypass

**Severity:** High · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64490](https://jira.germanedge.com/browse/GE4-64490)
**CVE:** CVE-2026-94440 ([GO-2026-6608](https://pkg.go.dev/vuln/GO-2026-6608))

Memory limit can be bypassed when parsing MIME headers.
**Fix:** build-stage bump to `golang:1.27.3`.

## 10. Go os — Root.Mkdir junction escape (Windows)

**Severity:** Critical · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64492](https://jira.germanedge.com/browse/GE4-64492) +
[GE4-64484](https://jira.germanedge.com/browse/GE4-64484) (dup)
**CVE:** CVE-2026-56857 ([GO-2026-6604](https://pkg.go.dev/vuln/GO-2026-6604))

`Root.Mkdir`/`MkdirAll` can create a directory outside the root when the final
path component is a junction. **Fix:** build-stage bump to `golang:1.27.3`.
Windows-only and `go-exporter` ships as a Linux container — practically not
exploitable here, but the stdlib version is what Xray matches on.

## 11. Go cmd/go — checksum verification bypass

**Severity:** High · **Fixed in:** Go 1.27.2
**Jira:** [GE4-64482](https://jira.germanedge.com/browse/GE4-64482),
[GE4-64480](https://jira.germanedge.com/browse/GE4-64480)
**CVEs:** CVE-2026-94444 ([GO-2026-6601](https://pkg.go.dev/vuln/GO-2026-6601)),
CVE-2026-94447 ([GO-2026-6602](https://pkg.go.dev/vuln/GO-2026-6602))

Checksum-database bypass for `golang.org/fips140` and `golang.org/toolchain`.
Affects the `toolchain` module (the build tool), not the runtime binary.
**Fix:** build-stage bump to `golang:1.27.3`.

## 12. Go crypto/x509 — compromised intermediate certificates

**Severity:** see advisory · **Fixed in:** Go **1.27.3** · **Jira:** none yet
**CVE:** CVE-2026-111943 ([GO-2026-6809](https://pkg.go.dev/vuln/GO-2026-6809))

Compromised intermediate CA certificates are still trusted.

**Not yet reported by Xray** — found while verifying the other groups. This is
the sole reason the build stage targets **1.27.3 and not 1.27.2**: every other
Go finding above is closed by 1.27.2, this one is not. A Jira ticket will appear
on the next scan.

## 13. golang.org/x/net/idna — stale finding

**Severity:** Critical · **Jira:** [GE4-59026](https://jira.germanedge.com/browse/GE4-59026)
**CVE:** CVE-2026-39821

`ToASCII`/`ToUnicode` wrongly accept ASCII-only Punycode-encoded labels.

**No fix needed — verify and close.** The ticket is pinned to an older image
(`sha256:93cc08f2…`, current is `sha256:f151ea3d…`) and `golang.org/x/net` is
not in `go.sum` at all, directly or transitively.
