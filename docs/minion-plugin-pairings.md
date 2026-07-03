# Minion ↔ Plugin Pairings

Recommended pairings between the minion roles and external integrations
(plugins, MCP connectors / "connectors", and skills). All pairings are
**conditional on presence**: use the integration **if it is present in the
operating environment**, and fall back to native repo surfaces and tools if it
is not. No specific integration is required to exist, and the template
hard-wires no specific vendor — these are guidance, and they degrade gracefully
where a plugin is absent or not yet inventoried. Once an integration **is**
present and inventoried in `minions/capabilities.md`, though, using it where it
fits the task — within charter limits — is an obligation, not a suggestion
(see MEMORY.md, Capability Inventory).

## Principles

- **Treat a plugin as an *engine the minion calls*, not a parallel role.** Some
  plugins ship agents that overlap a minion (e.g. a code-reviewer agent vs `CM`/
  `SM`, an architecture agent vs `AM`). Have the owning minion *call* the
  high-quality engine; do not let it fork ownership of the lane.
- **Access ≠ use.** A minion that has access to a skill/connector can *discover*
  it (capabilities surface by their description) but will only *reliably* use it
  when its charter says to. That is why every role charter carries a
  capability-utilization obligation: when a capability inventoried in
  `minions/capabilities.md` fits the task and the charter permits its use,
  using it is an obligation, not a suggestion — hand-rolling what a listed
  capability already does is a review finding (see MEMORY.md, Capability
  Inventory).
- **Stay in lane and keep the guardrail.** A pairing must not expand a role past
  its charter. `RM` using a research connector is still recommend-only; `PM`
  updating an issue tracker is still coordination, not product code.
- **Evidence discipline carries through.** When a minion calls a plugin (or a
  nested agent), it folds the returned evidence into its own packet with sources
  and confidence tags — it does not pass up a bare conclusion.

## Recommended pairings by role

Conditional — apply only where the integration exists.

| Minion | Pairing (if present) | Use it for |
| --- | --- | --- |
| `PM` | Issue tracker / planning (Linear, Jira, ClickUp, Monday; planning skills) | Read/update issues, sprints, roadmap, stakeholder updates — coordination only |
| `AM` | System-design / architecture skills; an architecture-blueprint agent | Structural analysis and design exploration — AM still owns the decision |
| `CM` | Error-tracking connector (e.g. Sentry); debugging / test skills; a code-explorer or code-review agent | Error context, root-cause tracing, test strategy, deeper review — CM still verifies |
| `SM` | A security scanner (e.g. Semgrep: SAST, secrets, supply-chain) | Reachable-risk and secrets findings to ground the security review |
| `DM` | Documentation skills; a docs/notes connector (e.g. Notion) | Doc generation/sync against source truth |
| `OM` | Observability / incident connectors (e.g. Datadog, Sentry); deploy/incident skills | Runtime truth, health, incident triage, deploy posture |
| `RM` | A web-research / web-data integration (e.g. Nimble) alongside `deep-research` | Live web, company, and competitive data — recommend-only still applies |

## Activating a pairing

**Unrestricted minions** (every role except `RM`) inherit all session skills and
connectors by default, so a pairing activates as soon as:

1. the integration is present in the environment, and
2. the minion's charter tells it to use it (the confirmed `PM` and `RM` lines are
   already in their charters).

The capability's row in `minions/capabilities.md` is the record that
condition 1 holds — pairings activate per that inventory.

**Restricted minions** (currently only `RM`, which has a `tools:` allowlist) must
*also* have the capability added to that allowlist, or they cannot reach it even
when it is present. For the Claude projection (`.claude/agents/rm.md`):

- allow a skill: add `Skill(<plugin>:<skill>)` — e.g. `Skill(nimble:nimble-web-expert)`
- allow a connector's tools: add `mcp__<plugin>_<server>__*` — e.g. `mcp__plugin_nimble_nimble__*`
- keep it scoped (named skills/servers, not blanket `Skill`/`mcp__*`) so the
  read-only, recommend-only guardrail stays intact.

A whitelist entry for a skill/server that is absent simply means the minion can't
invoke it — no error — so scoped entries are safe to ship and degrade gracefully.

## Portability

These pairings ship in the template as recommendations. A downstream project
that uses a different stack should adjust the conditional charter lines to its
own integrations (or rely on the fallbacks). Do not assume any specific plugin is
present; the value is the *mapping* (which kind of integration serves which
role), not the vendor.
