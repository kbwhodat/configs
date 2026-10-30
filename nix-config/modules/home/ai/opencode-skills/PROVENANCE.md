# Vendored OpenCode skills

Markdown-only skills copied from the ECC catalogue
(https://github.com/affaan-m/everything-claude-code, MIT, see `LICENSE.ecc`)
at commit `b38be6a7f6350964d59328b52f0624e1d1d552d1` on 2026-10-30.

They are installed as on-demand global skills through
`programs.opencode.skills` in `../opencode.nix`, which links each directory to
`~/.config/opencode/skills/<name>/`. The directory name is the skill ID.
OpenCode V2 discovers them without the ECC plugin.

This file and `LICENSE.ecc` are intentionally not linked: a root-level `*.md`
inside `~/.config/opencode/skills/` would itself be read as a skill.

## Included (reviewed full text, usable as-is)

| Skill | Why |
|---|---|
| python-patterns | Python release/evidence tooling idioms |
| error-handling | Structured failures, bounded retries, Python and JS |
| api-design | HTTP semantics, error contracts, versioning |
| contract-first | One authoritative boundary artifact for Worker/lab APIs |
| make-interfaces-feel-better | Framework-neutral UI polish checklist |
| latency-critical-systems | Freshness vs speed, hot-path mapping, live readbacks |
| benchmark-optimization-loop | Baseline-first, one-hypothesis performance variants |
| data-throughput-accelerator | Throughput work with correctness accounting |
| content-hash-cache-pattern | Stdlib Python content-addressed cache |
| issue-review | Evidence-bound issue triage against pinned SHAs |
| mcp-dependency-review | Static review of mutable MCP package references |
| terminal-ops | Smallest proving command, changed/verified/committed distinction |

## From other sources

| Skill | Source |
|---|---|
| systematic-debugging | obra/superpowers (MIT, `LICENSE.superpowers`), commit `917e5f5` (2026-04-06), copied from the Claude Code marketplace cache `~/.claude/plugins/marketplaces/superpowers-dev/skills/systematic-debugging`. Its reference to `superpowers:test-driven-development` points at a skill that is deliberately not installed. |
| verification-before-completion | obra/superpowers, same commit and cache. Referenced by systematic-debugging; complements the project's `verify-before-report`. |
| workers-best-practices, wrangler | cloudflare/skills (Apache-2.0, `LICENSE.cloudflare`), commit `ed2d6ba`, 2026-10-30. Retrieval-first guidance for the `services/live-poc` Worker. `wrangler` nudges toward the `cf` CLI for new projects; this project has `wrangler.toml`, so it stays on Wrangler. |
| promql, dashboarding | grafana/skills `skills/grafana-core/` (Apache-2.0, `LICENSE.grafana`), commit `8fb72a5`, 2026-10-30. For lab Prometheus queries and per-lab Grafana dashboards. `dashboarding` pushes via the Grafana HTTP API and needs a token; read-only authoring works without one. |
| playwright-best-practices | Currents Software (MIT, `LICENSE.md` inside the skill dir), copied from uzh-bf/klicker-uzh `.agents/skills/playwright-best-practices` at `e82bd86`, 2026-10-30. 61 files; `SKILL.md` is an index, the references load on demand. Replaces the ECC `e2e-testing` candidate. |
| postmortem-writing | wshobson/agents `plugins/incident-response/skills/postmortem-writing` (MIT, `LICENSE.wshobson`), commit `0874a27`, 2026-10-30. Blameless postmortem structure, timelines, action items. For scenario authoring and learner-facing postmortem templates. |
| k8s-namespace-troubleshooting | foxj77/claude-code-skills (MIT, `LICENSE.foxj77`), commit `34f05a8`, 2026-10-30. Unmodified: its Phase 5 already presents mutating kubectl commands as recommendations and says not to run them. Its MCP section names flux-operator tools that are not installed here; it falls back to kubectl. Namespace-scoped kubectl investigation; matches the per-session k3s namespaces. Read-only diagnosis; any `kubectl` against a live lab still goes through coordinator authority. |
| bro | `inputs.bro-skill` flake input, referenced directly from `opencode.nix` (not copied here). |

Not vendored after review: wimpysworld `nix` skill (no frontmatter, so never
advertised, and built around mcp-nixos tools that are disabled here);
secondsky `cloudflare-workers-security` and `cloudflare-workers-testing`
(Zod and Vitest assumptions); claude-dev-suite `esbuild` (thin, depends on a
docs MCP); grafana `alerting-irm`, `k6`, cloudflare `web-perf`, and
chaostoolkit `chaostoolkit-experiment` (situational, add on demand).

## Reviewed but deliberately not vendored yet

Need adaptation before use (assume pytest, React, Claude hooks, or add
approval gates): e2e-testing, frontend-a11y, frontend-design-direction,
python-testing (project uses unittest), security-review, change-impact,
test-collaboration. Task-specific references worth adding on demand:
dashboard-builder, kubernetes-patterns, network-interface-health,
postgres/mysql/redis-patterns, seo, hexagonal-architecture,
living-docs-governance. ECC's `deep-research` collides with the installed
skill of the same ID and must not be added.

To refresh a skill, copy `skills/<name>/SKILL.md` from the upstream commit you
reviewed and update the commit hash above.
