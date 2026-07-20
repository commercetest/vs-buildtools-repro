# vs-buildtools-repro

Minimal, self-contained reproduction for the Visual Studio Build Tools installer
**hanging** inside a Windows Server Core container after the **July 2026**
cumulative update.

- Confirmed on **Server 2019 / `ltsc2019`, build 17763.9020 (KB5099538)** — the
  installer self-extracts then blocks on a local RPC reply (`LpcReply`, ~0 CPU,
  no network). Works on the prior build **17763.8511 (KB5078752)**.
- Same failure family as **[microsoft/Windows-Containers#641](https://github.com/microsoft/Windows-Containers/issues/641)**
  (Azure Data Factory SHIR broke on the same 17763.8511 → 17763.9020 step) — a
  second, unrelated app failing on the same update.

## Why this repo targets Server 2022

Windows containers only run on a Windows host, and the *exact* case is
`ltsc2019`. But:
- GitHub **retired the `windows-2019` runner** (2025‑06‑30), so there's no
  hosted Server 2019 host anymore.
- Hosted `windows-2022` runners can't run an `ltsc2019` container (that needs
  Hyper‑V isolation → nested virtualization, unavailable on hosted runners).

So this workflow runs on **`windows-2022`** with **`ltsc2022`** containers
(process isolation, no nested virt) to test whether the **same regression is
present on Server 2022**. See `.github/workflows/repro.yml` for how to read the
A/B result.

## Run it

Push this repo to GitHub and the workflow runs automatically (or trigger it via
the **Actions** tab → *vs-buildtools-repro* → *Run workflow*). No secrets needed.

## Interpreting results

| current (patched) base | dated pre‑July base | meaning |
|---|---|---|
| **times out** | **succeeds** | regression present on Server 2022 too — reproduced on hosted CI |
| succeeds | succeeds | Server 2022 unaffected → bug is Server 2019‑specific (needs a Server 2019 host) |
| times out | times out | inconclusive for this hosted setup |

If the dated tag `4.8-20260512-windowsservercore-ltsc2022` doesn't exist, pick a
valid pre‑July‑2026 dated tag from
<https://mcr.microsoft.com/v2/dotnet/framework/runtime/tags/list> and update the
matrix.

## Faithful (Server 2019) reproduction

For the exact `ltsc2019` case with full IPC evidence (thread `WaitReason =
LpcReply`, empty `netstat`), run on a **Server 2019** host (a self-hosted runner
or a cloud Server 2019 VM) with process isolation:

```
docker build --no-cache \
  --build-arg BASE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019 \
  -t vsrepro:broken .
```
…then, while it hangs, from a second shell:
```
docker ps
docker top <id>
docker exec <id> powershell -c "(Get-Process vs_buildtools).Threads | Group-Object WaitReason | Select Count,Name"
docker exec <id> netstat -ano
```
