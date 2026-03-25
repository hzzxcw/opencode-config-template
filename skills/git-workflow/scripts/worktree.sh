#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKTREES_BASE="$(dirname "$REPO_DIR")"
GITHUB_REPO=$(gh repo view --json owner,name --jq '.owner.login + "/" + .name' 2>/dev/null || echo "owner/repo")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cmd_list() {
    log_info "Project: $REPO_DIR"
    echo ""
    log_info "Main worktree:"
    cd "$REPO_DIR"
    echo "  Path: $REPO_DIR"
    echo "  Branch: $(git branch --show-current)"
    echo ""
    log_info "Feature worktrees:"
    for wt in $(git worktree list --porcelain | grep -B1 "^worktree" | grep -v "^worktree" | awk '{print $2}'); do
        if [ "$wt" != "$REPO_DIR" ]; then
            wt_name=$(basename "$wt")
            wt_branch=$(cd "$wt" && git branch --show-current 2>/dev/null || echo "detached")
            echo "  $wt_name"
            echo "    Path: $wt"
            echo "    Branch: $wt_branch"
            echo ""
        fi
    done
}

cmd_issues() {
    log_info "Open issues on $GITHUB_REPO:"
    echo ""
    gh issue list --state open --json number,title,labels --jq '
        .[] | "#\(.number) - \(.title)" + 
        (if (.labels | length) > 0 then " [" + (.labels | map(.name) | join(", ")) + "]" else "" end)
    ' | while read line; do
        echo "  $line"
    done
}

cmd_start() {
    local issue_number="$1"
    if [ -z "$issue_number" ]; then
        log_error "Usage: $0 start <issue_number>"
        exit 1
    fi
    
    local issue_info=$(gh issue view "$issue_number" --json number,title --jq '{number: .number, title: .title}')
    local issue_title=$(echo "$issue_info" | jq -r '.title')
    local project_name=$(basename "$REPO_DIR")
    local branch_name="feature/issue-${issue_number}-$(echo "$issue_title" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-50)"
    local worktree_path="$WORKTREES_BASE/${project_name}-feature/issue-${issue_number}-$(echo "$issue_title" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)"
    
    if [ -d "$worktree_path" ]; then
        log_warn "Worktree already exists: $worktree_path"
        cd "$worktree_path"
        log_success "Ready at: $worktree_path"
        return
    fi
    
    log_info "Creating worktree for issue #$issue_number..."
    log_info "Branch: $branch_name"
    log_info "Path: $worktree_path"
    
    cd "$REPO_DIR"
    git worktree add -b "$branch_name" "$worktree_path" develop
    cd "$worktree_path"
    
    log_success "Worktree created!"
    echo ""
    log_info "Next steps:"
    echo "  1. cd $worktree_path"
    echo "  2. Implement the feature"
    echo "  3. Run tests: uv run pytest"
    echo "  4. Finish: $0 done"
}

cmd_all() {
    log_info "Fetching all open issues..."
    echo ""
    
    local issues=$(gh issue list --state open --json number,title --jq '.[] | @base64')
    
    if [ -z "$issues" ]; then
        log_warn "No open issues found"
        return
    fi
    
    local count=$(echo "$issues" | wc -l | tr -d ' ')
    log_info "Found $count open issues"
    echo ""
    
    echo "Run the following commands to process all issues in parallel:"
    echo ""
    
    echo "$issues" | while read encoded; do
        local issue=$(echo "$encoded" | base64 -d)
        local number=$(echo "$issue" | jq -r '.number')
        local title=$(echo "$issue" | jq -r '.title')
        echo "  #${number}: ${title}"
        echo "    git worktree add -b feature/issue-${number} ../${project_name}-feature/issue-${number} develop"
        echo ""
    done
    
    echo ""
    log_info "Tip: Use this skill to spawn parallel subagents for each issue"
}

cmd_done() {
    local branch_name=$(git branch --show-current)
    
    if [ -z "$branch_name" ] || [[ "$branch_name" != feature/* ]]; then
        log_error "Must run from a feature worktree"
        exit 1
    fi
    
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_error "Uncommitted changes. Commit first."
        git status --short
        exit 1
    fi
    
    local commits_ahead=$(git log --oneline develop..HEAD 2>/dev/null | wc -l | tr -d ' ')
    if [ "$commits_ahead" -eq 0 ]; then
        log_warn "No commits to push"
        return
    fi
    
    log_info "Pushing branch..."
    git push -u upstream "$branch_name"
    
    local issue_num=$(echo "$branch_name" | grep -oE '[0-9]+' | head -1)
    local pr_title=$(echo "$branch_name" | sed 's/feature\/issue-[0-9]*-//' | tr '-' ' ' | sed 's/.*/\u&/')
    
    log_info "Creating PR..."
    gh pr create \
        --base develop \
        --head "$branch_name" \
        --title "[Feature] $pr_title" \
        --body "## Summary
TODO: Describe the feature.

## Changes
- TODO: List changes

## Testing
- [ ] Tests pass
- [ ] Code reviewed

Closes #$issue_num"
    
    log_success "PR created: $(gh pr view --json url --jq '.url')"
}

cmd_switch() {
    local target="$1"
    if [ -z "$target" ]; then
        log_error "Usage: $0 switch <name>"
        exit 1
    fi
    
    local project_name=$(basename "$REPO_DIR")
    local worktree_path="$WORKTREES_BASE/${project_name}-feature/$target"
    
    if [ ! -d "$worktree_path" ]; then
        log_error "Worktree not found: $worktree_path"
        exit 1
    fi
    
    cd "$worktree_path"
    log_success "Switched to: $worktree_path"
}

cmd_help() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  list                    List all worktrees"
    echo "  issues                  List open GitHub issues"
    echo "  start <issue_number>    Create worktree for issue"
    echo "  all                     Show all issues (for parallel processing)"
    echo "  done                    Finish worktree (commit, push, PR)"
    echo "  switch <name>           Switch to worktree"
    echo "  help                    Show this help"
}

case "${1:-help}" in
    list)   cmd_list ;;
    issues) cmd_issues ;;
    start)  cmd_start "$2" ;;
    all)    cmd_all ;;
    done)   cmd_done ;;
    switch) cmd_switch "$2" ;;
    help|--help|-h) cmd_help ;;
    *)      log_error "Unknown: $1"; cmd_help; exit 1 ;;
esac
