#!/usr/bin/env bash
set -euo pipefail

# opencode-config-template setup script
# Sets up global opencode configuration and optionally creates project-specific config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OPENCODE_DIR="$HOME/.config/opencode"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
用法: $(basename "$0") [选项]

设置 opencode 全局配置和项目配置。

选项:
  --link-global         使用符号链接安装全局配置（推荐，自动同步更新）
  --copy-global         复制全局配置（独立副本，不自动更新）
  --project-name NAME   创建项目特定的 AGENTS.md（可选）
  --project-dir DIR     项目目录路径（与 --project-name 配合使用）
  --backup              安装前备份已有配置
  --dry-run             仅显示将执行的操作，不实际执行
  -h, --help            显示此帮助信息

示例:
  # 使用符号链接安装全局配置
  $(basename "$0") --link-global

  # 复制全局配置并备份已有配置
  $(basename "$0") --copy-global --backup

  # 安装全局配置并创建项目配置
  $(basename "$0") --link-global --project-name my-project --project-dir ~/my-project

EOF
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

backup_existing() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] 将备份 $target → $backup"
        else
            mv "$target" "$backup"
            log_info "已备份 $target → $backup"
        fi
    fi
}

install_global_link() {
    mkdir -p "$OPENCODE_DIR"

    # Link AGENTS.md
    local agents_src="$REPO_DIR/AGENTS.md"
    local agents_dst="$OPENCODE_DIR/AGENTS.md"
    if [[ "$DO_BACKUP" == "true" ]]; then backup_existing "$agents_dst"; fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] ln -sf $agents_src $agents_dst"
    else
        ln -sf "$agents_src" "$agents_dst"
        log_info "已链接 AGENTS.md → $agents_dst"
    fi

    # Link skills/
    local skills_src="$REPO_DIR/skills"
    local skills_dst="$OPENCODE_DIR/skills"
    if [[ "$DO_BACKUP" == "true" ]]; then backup_existing "$skills_dst"; fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] ln -sf $skills_src $skills_dst"
    else
        ln -sf "$skills_src" "$skills_dst"
        log_info "已链接 skills/ → $skills_dst"
    fi
}

install_global_copy() {
    mkdir -p "$OPENCODE_DIR"

    # Copy AGENTS.md
    local agents_src="$REPO_DIR/AGENTS.md"
    local agents_dst="$OPENCODE_DIR/AGENTS.md"
    if [[ "$DO_BACKUP" == "true" ]]; then backup_existing "$agents_dst"; fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] cp $agents_src $agents_dst"
    else
        cp "$agents_src" "$agents_dst"
        log_info "已复制 AGENTS.md → $agents_dst"
    fi

    # Copy skills/
    local skills_src="$REPO_DIR/skills"
    local skills_dst="$OPENCODE_DIR/skills"
    if [[ "$DO_BACKUP" == "true" ]]; then backup_existing "$skills_dst"; fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] cp -r $skills_src $skills_dst"
    else
        cp -r "$skills_src" "$skills_dst"
        log_info "已复制 skills/ → $skills_dst"
    fi
}

setup_project() {
    local project_name="$1"
    local project_dir="$2"

    if [[ ! -d "$project_dir" ]]; then
        log_error "项目目录不存在: $project_dir"
        exit 1
    fi

    local template_src="$REPO_DIR/templates/project-agents.md.template"
    local agents_dst="$project_dir/AGENTS.md"

    if [[ ! -f "$template_src" ]]; then
        log_error "模板文件不存在: $template_src"
        exit 1
    fi

    if [[ -f "$agents_dst" ]]; then
        if [[ "$DO_BACKUP" == "true" ]]; then
            backup_existing "$agents_dst"
        else
            log_warn "项目 AGENTS.md 已存在: $agents_dst（使用 --backup 备份）"
            return
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] 将从模板创建 $agents_dst（替换 {{PROJECT_NAME}} → $project_name）"
    else
        sed "s/{{PROJECT_NAME}}/$project_name/g" "$template_src" > "$agents_dst"
        log_info "已创建项目 AGENTS.md: $agents_dst"
        log_warn "请编辑 $agents_dst 填写其他占位符（{{PROJECT_DESCRIPTION}} 等）"
    fi
}

# Parse arguments
MODE=""
PROJECT_NAME=""
PROJECT_DIR=""
DO_BACKUP="false"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --link-global)  MODE="link"; shift ;;
        --copy-global)  MODE="copy"; shift ;;
        --project-name) PROJECT_NAME="$2"; shift 2 ;;
        --project-dir) PROJECT_DIR="$2"; shift 2 ;;
        --backup)       DO_BACKUP="true"; shift ;;
        --dry-run)      DRY_RUN="true"; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              log_error "未知选项: $1"; usage; exit 1 ;;
    esac
done

# Validate
if [[ -z "$MODE" && -z "$PROJECT_NAME" ]]; then
    log_error "请指定 --link-global 或 --copy-global，或使用 --project-name 创建项目配置"
    usage
    exit 1
fi

# Execute
if [[ -n "$MODE" ]]; then
    log_info "开始安装全局配置（模式: $MODE）..."
    if [[ "$MODE" == "link" ]]; then
        install_global_link
    else
        install_global_copy
    fi
    log_info "全局配置安装完成！"
fi

if [[ -n "$PROJECT_NAME" ]]; then
    if [[ -z "$PROJECT_DIR" ]]; then
        log_error "--project-name 需要配合 --project-dir 使用"
        exit 1
    fi
    log_info "开始创建项目配置: $PROJECT_NAME..."
    setup_project "$PROJECT_NAME" "$PROJECT_DIR"
fi

log_info "完成！"
