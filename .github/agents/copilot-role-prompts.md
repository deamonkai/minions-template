# Copilot Role Prompt Pack

Use these prompts directly in GitHub Copilot Chat when working in this template.

## PM Prompts

- Use the pm agent to turn this request into scope, acceptance criteria, blockers, and next owner. Do not assign implementation until blockers are explicit.
- Use the pm agent to review this milestone draft. Return findings first: blockers, risks, open questions, accepted progress.
- Use the pm agent to produce a go or no-go recommendation for this stage gate with evidence and Operator action needed.

## AM Prompts

- Use the am agent to challenge this design. Focus on boundaries, data flow, dependencies, and tradeoffs.
- Use the am agent to assess whether this change is architecture-significant or implementation-only, and explain why.
- Use the am agent to produce implementation constraints for cm, including validation requirements.

## CM Prompts

- Use the cm agent to investigate this failing test. Do not edit files yet. Return root cause, evidence, likely fix, and next owner.
- Use the cm agent to implement this approved change, update tests, and report evidence plus docs impact.
- Use the cm agent to review this diff for regression risk and missing tests.

## SM Prompts

- Use the sm agent to review this change for reachable security risk. Return severity, reachability, exploitability, and hardening requirements.
- Use the sm agent to check this auth or access-control flow for bypass risk and logging gaps.
- Use the sm agent to review this input-handling path for injection, traversal, and unsafe deserialization risk.

## DM Prompts

- Use the dm agent to check README and docs for drift against current behavior. Return findings and exact files to update.
- Use the dm agent to update docs for this merged change. Keep claims source-verified and include operator-facing impact.
- Use the dm agent to audit onboarding and runbook docs for missing steps and ambiguous instructions.

## OM Prompts

- Use the om agent to validate deploy and rollback posture for this release candidate. Report gaps before any runtime action.
- Use the om agent to verify runtime health evidence for this service: deployed vs running vs healthy.
- Use the om agent to produce an incident response checklist for this failure mode with stabilization-first sequencing.

## RM Prompts

- Use the rm agent to research this build or tooling blocker in depth. Lead with vendor documentation, then corroborating sources, and return ranked options plus a recommendation.
- Use the rm agent to compare these implementation options against vendor guidance and project constraints. Return tradeoffs and the best next step.
- Use the rm agent to scout non-obvious paths to unblock this issue. Separate verified evidence from inference and identify the next owner.

## Multi-Role Prompts

- Use pm, am, and sm to review this plan in parallel. Consolidate conflicts, blockers, and next owners.
- Use cm and sm to review this proposed implementation in parallel, then provide a merged recommendation.
- Use am, cm, dm, and om to prepare release readiness notes with explicit evidence gaps.
- Use pm and rm to triage this blocker: pm should frame gate impact and ownership while rm delivers vendor-grounded options and a recommended next step.

## Model Selection Rubric (Copilot)

Default: keep Copilot on Auto.

Use stronger reasoning when the task has deep ambiguity, significant tradeoffs, or high consequence.

- pm:
	- Auto: scope shaping, milestone checks, concise gate summaries
	- Higher reasoning: conflicting constraints, messy multi-owner plans, go/no-go decisions with weak evidence
- am:
	- Auto: design sanity checks, boundary confirmations, dependency scans
	- Higher reasoning: architecture redesign, tradeoff-heavy decisions, cross-system boundary shifts
- cm:
	- Auto: routine fixes, straightforward refactors, single-file test updates
	- Higher reasoning: flaky or nondeterministic failures, complex root-cause analysis, broad regressions
- sm:
	- Auto: baseline review of obvious auth/input/secrets issues
	- Higher reasoning: exploitability analysis, chained attack paths, nuanced risk acceptance decisions
- dm:
	- Auto: doc cleanup, drift checks, runbook wording improvements
	- Higher reasoning: policy-heavy documentation, ambiguous behavior reconciliation, broad doc restructuring
- om:
	- Auto: checklists, deployment-readiness verification, standard health validation
	- Higher reasoning: incident triage with unclear runtime truth, rollback strategy under partial failure
- rm:
	- Auto: straightforward vendor-doc lookups, single-source confirmation, lightweight option summaries
	- Higher reasoning: ambiguous/conflicting sources, multi-option tradeoff analysis, non-obvious unblock strategies

Escalate to higher reasoning if any of these appear:

- More than one plausible root cause after first-pass investigation
- High-impact decision with incomplete or conflicting evidence
- Cross-role disagreement that changes scope, risk, or release posture

De-escalate back to Auto when:

- The task is deterministic and mostly mechanical
- You are applying an already-approved plan with low ambiguity
- You are doing repetitive edits or straightforward formatting/doc sync

## Control Prompts

- Review-only mode: Do not edit files or run commands. Investigate and report findings with evidence.
- Edit mode: You may edit files, but keep changes minimal and aligned to the approved scope.
- Runtime-safe mode: Do not deploy, restart services, or run destructive commands. Report what is missing for safe execution.
