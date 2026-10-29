---
name: create-pr
description: Prepare scoped changes and open a review-ready draft pull request for jr-coa/cypress-realworld-app-demo. Use when asked to create, open, or submit a PR. Includes local self-review, appropriate project checks, a scoped commit and push, and an evidence-based description; excludes merging and ongoing CI or review iteration unless requested.
---

# Create a draft PR

## Project defaults and authorization

- Work in the existing fork checkout. After setup, source `/workspace/.tools/rwa-env.sh` and use
  `$RWA_REPO_DIR` rather than assuming its folder name. Read applicable `AGENTS.md` files if present.
  Use [cloud-development](../cloud-development/SKILL.md) for runtime setup.
- The intended repository is **`jr-coa/cypress-realworld-app-demo`**, with base branch **`develop`**.
  Verify the current origin and default branch before acting. The inherited `package.json`
  repository field still names the original project; it must not select the PR destination.
- Push the feature branch to the fork's `origin`. Target the original `cypress-io` repository only
  if the user explicitly requests an upstream PR. Keep its `upstream` remote intact.
- An actual request to create/open a PR authorizes the scoped branch, commit, push, and draft PR.
  Merely editing this skill does not. Do not merge or publish a release without authorization. Push directly to `develop` only when the user explicitly requests it.
- Each cloud task is already isolated. Do not create a Git worktree unless explicitly requested.
  Preserve unrelated user changes and local commits; do not reset, clean, or auto-stash them away.

Prefer connected GitHub/SCM tools for PR metadata, creation, labels, and updates when their actual
capabilities support the operation. Use local Git for branches, staging, commits, and pushes.
`gh` is an available fallback; discover tools at invocation time rather than assuming tool names
or limitations. Briefly report a CLI fallback when it is used.

## Workflow

1. **Establish scope and base.** Read the user's requested outcome and inspect status, staged and
   unstaged diffs, untracked files, and commits ahead of the intended base. Fetch `origin develop`
   and compute the merge base with `origin/develop` unless the user selected another base. Inspect
   both `git diff <merge-base> HEAD` and uncommitted changes; neither alone shows the whole task.
   Account for every file intended for this PR. Leave unrelated changes untouched. Ask only if a
   real scope ambiguity prevents safe progress.
2. **Complete the change and its docs.** Fix in-scope defects and update affected README instructions,
   examples, API explanations, or skills in the same PR when appropriate. Do not automatically
   open a separate docs PR or depend on skills that are absent from this project.
3. **Format the intended files.** Use the installed project Prettier on explicit supported paths.
   Do not run the repository's broad `yarn prettier` write command for a small change. Review the
   formatting diff and exclude unrelated churn. This project does not use `gofmt` or `oxfmt`.
4. **Run appropriate validation.** Follow [verification.md](references/verification.md), the current
   package scripts, and the affected CI workflow. Use [writing-tests](../writing-tests/SKILL.md)
   when adding tests. Record actual commands and outcomes, including existing skips and unrun
   Cypress checks. Diagnose failures before classifying them as environment limitations.
5. **Review the final diff.** Use [code-review](../code-review/SKILL.md) in local, read-only mode.
   This self-review must not post GitHub comments or submit a formal review. Fix objective,
   in-scope findings and rerun affected checks. Review any subsequent code changes. Do not hide
   unresolved critical/high correctness findings in a supposedly ready PR; ask about a genuine
   product decision or an explicitly requested acceptance of known risk when necessary.
6. **Create a scoped branch and commit.** If the current branch is already appropriate, reuse it.
   Otherwise choose a descriptive branch such as `codex/describe-change` and validate it with
   `git check-ref-format --branch`. Stage explicit paths and inspect `git diff --cached` before
   committing. Use the configured Git author identity and a concise Conventional Commit title,
   matching this repository's existing style. Do not invent co-authors or change global Git config.
7. **Push and open a draft.** Push only the authorized feature branch to `origin`. Read the current
   PR first if one already exists and update it instead of creating a duplicate. Use a repository
   PR template if one has since been added; otherwise use the included
   [description template](references/pr-description-template.md). Set the repository and base
   explicitly, and verify the returned PR URL and head commit. Do not fabricate a PR link.
8. **Report the outcome.** Give the PR link, branch, base, concrete resulting behavior, validation
   evidence, documentation status, and remaining gaps. Read initial CI status for the pushed SHA
   and distinguish pending, passed, failed, and unavailable checks. Ongoing review/CI follow-through
   and merging require that scope to be requested; do not promise that pending checks are green.

## Description quality

Lead with the concrete problem, its consequence, and the resulting behavior. Explain compatibility,
fallbacks, and reviewer-relevant risk when they matter. A reviewer should understand the first two
paragraphs without reconstructing intent from filenames or commit history.

Summarize what was verified before listing commands. Use a short list or a collapsed details block
for long evidence. Add a diagram only when it clarifies a meaningful flow or contract. Keep review
focus to the few decisions or invariants that actually need judgment. Omit sections that add no
information; do not mechanically enumerate the diff, add invented release-note requirements, or
describe unexecuted checks as successful.

Documentation-only and skill-only PRs need relevant formatting, link/path checks, and syntax checks
for changed runnable examples or scripts. They do not automatically need an application build or
browser suite. A draft may record an honest environment-only validation gap; it must remain clearly
unverified for that behavior. An actual failing assertion is not an environment gap.

## Issues, labels, and repository policy

- Link issues supplied by the user or clearly associated with the change. Verify their repository
  and relevance. Do not guess a Linear identifier from branch digits or search unrelated teams.
  This project has no established Linear or Notion dependency in its checked-in workflow.
- No PR template, PR-title lint workflow, mandatory changelog labels, or changelog generator was
  present when this skill was adapted. Recheck current repository policy instead of assuming one.
- Apply existing labels only when supported by actual repository policy or a user request. Do not
  create a `changelog:*` taxonomy, infer in-progress features from unrelated PR clusters, or require
  a label-confirmation ceremony. Preserve existing labels that remain appropriate.
- If a label or title needs correction, update the metadata. Do not amend a commit or force-push
  solely to synchronize it with a guessed label. Prefer additional commits for follow-up fixes;
  history rewriting requires explicit authorization and must preserve other contributors' work.

## GitHub CLI fallback

Use existing GitHub authentication and the platform's HTTPS Git proxy. Read access, API access,
and push permission are separate. An unset `GH_TOKEN`/`GITHUB_TOKEN` does not prove that Git access
is missing. Do not extract credentials, source another project's token helper, or request a token
merely because a CLI requests login. Verify the operation that is needed and report a concrete
authorization blocker if existing supported authentication cannot perform it.

Write the exact PR body to a temporary file and use structured tool arguments or `--body-file`:

```bash
gh pr create --repo jr-coa/cypress-realworld-app-demo \
  --base develop --head "$branch" --draft \
  --title "$title" --body-file "$body_file"
```

Values above are prepared by the current task. Preserve literal newlines and use proper shell
quoting. Do not put credentials in command text, descriptions, logs, or saved instructions.

## Completion checks

- The final staged/committed scope matches the user's request; generated outputs have a reason.
- Relevant checks were completed and accurately reported; database and custom auth configuration
  were preserved. No unrelated source, lockfile, or fixture changes slipped into the commit.
- The final self-review has no concealed critical/high correctness finding.
- The draft PR targets the intended fork/base and its head matches the pushed commit.
- The description explains the problem, behavior, evidence, compatibility, and material gaps.
- The final response distinguishes a created PR from a pushed branch or a failed API operation.
