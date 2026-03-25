# OpenCode 配置模板仓库

统一管理 [opencode](https://opencode.ai) 的全局开发规范（AGENTS.md）和 Skills 配置文件。

## 这是什么？

这个仓库是一个**模板仓库**，用于：
- 集中管理全局开发规范和 Skills 配置
- 为新项目提供标准化的配置模板
- 通过 Git 版本控制追踪配置变更

## 目录结构

```
opencode-config-template/
├── AGENTS.md                              # 全局通用开发规范
├── projects/                              # 项目特定配置
│   └── quant-data-pipeline/
│       └── AGENTS.md                      # 量化数据项目专属规范
├── skills/                                # opencode Skills
│   ├── dagster-expert/                    # Dagster 专家 skill
│   ├── dignified-python/                  # Python 编码标准 skill
│   ├── git-workflow/                      # Git 工作流 skill
│   ├── data-quality-checker.md            # 数据质量检查 skill
│   └── skill-creator/                     # Skill 创建工具
├── scripts/
│   └── setup-project.sh                   # 项目初始化脚本
├── templates/                             # 配置模板
│   ├── project-agents.md.template         # 项目 AGENTS.md 模板
│   └── opencode.json.template             # opencode 配置模板
└── README.md                              # 本文件
```

## 配置层级

```
全局规范 (AGENTS.md)          ← 通用 Python/Git/测试/安全标准
    ↓ 继承
项目规范 (projects/*/AGENTS.md) ← 项目特有规范（框架、数据库等）
    ↓ 增强
Skills (skills/*)              ← 领域专家知识（Dagster、Python 等）
```

- **全局规范**: 适用于所有 Python 项目的通用标准
- **项目规范**: 仅包含项目特有的规范，通过引用继承全局规范
- **Skills**: 提供特定领域的专家指导，由 opencode 自动加载

## 快速开始

### 1. 克隆仓库

```bash
git clone <repo-url> ~/opencode-config-template
```

### 2. 安装全局配置

**方式一：符号链接（推荐）** — 自动同步更新

```bash
bash ~/opencode-config-template/scripts/setup-project.sh --link-global
```

**方式二：复制** — 独立副本

```bash
bash ~/opencode-config-template/scripts/setup-project.sh --copy-global
```

### 3. 为新项目创建配置（可选）

```bash
bash ~/opencode-config-template/scripts/setup-project.sh \
  --link-global \
  --project-name my-new-project \
  --project-dir ~/my-new-project
```

### 4. 备份已有配置

```bash
bash ~/opencode-config-template/scripts/setup-project.sh --link-global --backup
```

## Skills 说明

| Skill | 说明 | 适用场景 |
|-------|------|----------|
| `dagster-expert` | Dagster 框架专家指导 | Asset 定义、dg CLI、自动化 |
| `dignified-python` | Python 编码标准 | 类型注解、异常处理、代码审查 |
| `git-workflow` | Git 工作流管理 | 分支策略、worktree、PR 流程 |
| `data-quality-checker` | 数据质量检查 | 完整性、准确性、一致性验证 |
| `skill-creator` | Skill 创建工具 | 创建和优化自定义 skill |

## 如何添加新 Skill

1. 在 `skills/` 目录下创建新目录或文件
2. 编写 `SKILL.md`（包含 frontmatter 和内容）
3. 运行安装脚本更新全局配置
4. 提交到 Git

## 如何添加新项目配置

1. 在 `projects/` 下创建项目目录：
   ```bash
   mkdir -p projects/my-new-project
   ```
2. 从模板创建项目 AGENTS.md：
   ```bash
   cp templates/project-agents.md.template projects/my-new-project/AGENTS.md
   ```
3. 编辑文件，替换 `{{PLACEHOLDER}}` 占位符
4. 提交到 Git

## 许可证

私有仓库，仅供个人使用。
