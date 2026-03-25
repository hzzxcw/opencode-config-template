---
name: git-workflow
description: Git branching strategy and worktree management. Use when users mention "worktree", "feature branch", "create PR", "development workflow", "start issue", "finish feature", "git flow", "process all issues", "loop through issues", or need to set up a Git repository with main/develop/feature branching. Also triggers when users want to manage multiple feature branches, initialize a new project with Git, or need guidance on branch naming conventions. This skill provides worktree management scripts and enforces a consistent Git workflow across all projects.
---

# Git Workflow Skill

This skill enforces a consistent Git workflow using worktrees and GitHub issues.

## Branch Strategy

```
main (production)
  └── develop (integration)
        └── feature/issue-{number}-{description}
```

---

## MANDATORY RULES

### NO Direct Commits to develop/main

**NEVER commit directly to `develop` or `main` branches.**

All code changes must:
1. Be made in a feature branch (e.g., `feature/issue-{number}`)
2. Go through Pull Request review
3. Be merged via PR only

**Why:** Direct commits bypass code review, break the audit trail, and cause synchronization issues with remote branches.

**Wrong:** `git checkout develop && git add -A && git commit && git push`
**Correct:** Create feature branch → implement → PR → merge

---

### Data Availability Rule (CRITICAL)

**In financial data ETL pipelines, NEVER use mock/fallback data when API is unavailable.**

If the external data source (e.g., national statistics bureau, exchange API, financial data provider) is unavailable:

1. **STOP development immediately**
2. **Report the issue to the user clearly**
3. **Do NOT create mock data as a workaround**
4. **Document the error and expected behavior**

**Why:** Mock data in financial pipelines is dangerous - it can silently pass validation, produce incorrect analysis, and lead to bad investment decisions. Data integrity is non-negotiable.

**Wrong approach:**
```python
# ❌ NEVER DO THIS
except Exception as e:
    return _generate_mock_data(context)  # Dangerous!
```

**Correct approach:**
```python
# ✅ DO THIS
except requests.RequestException as e:
    context.log.error(f"Failed to fetch data: {e}")
    raise  # Stop and report the error
```

---

### Language Requirements

**ALL git-related content MUST be in English:**

| Element | Language | Example |
|---------|----------|---------|
| Branch name | English | `feature/issue-1-add-macro-data-assets` |
| Commit message | English | `feat: add industrial value added asset` |
| PR title | English | `[Feature] Add macro economic data assets` |
| PR body | English | Use English for all descriptions |

**WHY:** English is the universal language for git collaboration. Chinese in branch names or commit messages causes encoding issues, makes git log unreadable, and complicates code review for international collaborators.

---

## Agent Loop: Process All Open Issues

When user says "process all issues", "handle all open issues", or "loop through issues", follow this agent loop:

### Step 1: Fetch All Open Issues

```bash
gh issue list --state open --json number,title
```

### Step 2: For Each Issue, in PARALLEL

Spawn parallel subagents (one per issue) to maximize throughput:

```
TASK: Issue #{number}
WORKTREE: ../{project}-feature/issue-{number}/
BRANCH: feature/issue-{number}-{english_description}

1. Create worktree from develop:
   git worktree add -b "feature/issue-{number}-{english_description}" "../{project}-feature/issue-{number}" develop

2. Implement the feature in worktree

3. Run tests: uv run pytest

4. Run validation: uv run dg check defs

5. Commit (ALL IN ENGLISH):
   git add -A && git commit -m "feat: add {english description}

Closes #{number}"

6. Push: git push upstream feature/issue-{number}

7. Create PR (ALL IN ENGLISH):
   gh pr create --base develop --head feature/issue-{number} --title "[Feature] {english title}" --body "## Summary
{English description}

## Changes
- {English bullet points}

## Testing
- [x] Tests pass
- [x] Code reviewed

Closes #{number}"
```

### Step 3: Report Results

After all subagents complete, report:
- List of PRs created with URLs
- List of issues closed

---

## Manual Workflow (Single Issue)

### 1. Initialize Repository

If project is not a Git repository:

```bash
git init -b main
git add .gitignore
git commit -m "chore: add gitignore"
git checkout -b develop
git commit -m "feat: add initial project structure"
gh repo create {repo-name} --public --source=. --push --remote upstream
git checkout main && git merge develop -m "Merge develop into main"
git push upstream main && git checkout develop
```

### 2. Check Pending Issues

```bash
gh issue list --state open
```

### 3. Start Feature Development

```bash
# Create worktree (branch name in English)
git worktree add -b "feature/issue-{number}-{english-description}" "../{project}-feature/issue-{number}" develop

# Navigate and implement
cd ../{project}-feature/issue-{number}
```

### 4. Complete Feature

```bash
# Ensure tests pass and code committed
git push -u upstream feature/issue-{number}

# PR in English
gh pr create \
  --base develop \
  --head "feature/issue-{number}" \
  --title "[Feature] {English title}" \
  --body "Closes #{number}"
```

### 5. Clean Up Merged Worktrees

```bash
git worktree prune
git push upstream --delete feature/issue-{number}
```

---

## Worktree Management Script

Use `scripts/worktree.sh` for automated operations:

```bash
./scripts/worktree.sh list           # List all worktrees
./scripts/worktree.sh issues         # List open GitHub issues
./scripts/worktree.sh start {num}    # Create worktree for issue
./scripts/worktree.sh done           # Finish current worktree
./scripts/worktree.sh switch {name}  # Switch to worktree
```

---

## Key Conventions

| Convention | Pattern | Example |
|------------|---------|---------|
| Branch naming | `feature/issue-{number}-{english-description}` | `feature/issue-1-add-macro-data-assets` |
| Worktree location | `../{project}-feature/issue-{number}` | `../quant-data-pipeline-feature/issue-1` |
| Commit message | `{type}: {english description}` | `feat: add industrial value added asset` |
| PR title | `[Feature] {english title}` | `[Feature] Add macro economic data assets` |

### Commit Type Prefix

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `chore` | Maintenance, deps |
| `docs` | Documentation |
| `refactor` | Code refactoring |
| `test` | Tests |

---

## Worktree Directory Structure

```
/parent/
├── {project}/                        # Main repo (develop)
│   ├── scripts/worktree.sh
│   └── ...
└── {project}-feature/               # Feature worktrees
    ├── issue-1/
    ├── issue-2/
    └── ...
```
