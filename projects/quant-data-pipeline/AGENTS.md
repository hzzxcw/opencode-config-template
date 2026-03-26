# 量化投资数据开发规范

> 通用开发规范请参考 [全局开发规范](../../AGENTS.md)。
> Dagster 相关规范由 `dagster-expert` skill 提供，Python 编码标准由 `dignified-python` skill 提供，数据质量检查由 `data-quality-checker` skill 提供。

## 项目概述

基于 Dagster 的量化投资数据处理项目，采用多 code locations 架构，支持：
- 数据采集 → 清洗 → 存储 → 分析
- 实时行情处理
- 多种数据源集成（Doris, PostgreSQL）

## 项目结构

```
quant-data-pipeline/
├── deployments/          # 部署配置
├── projects/
│   └── core/            # 核心数据处理项目（code location）
│       ├── src/
│       │   └── core/
│       │       ├── definitions.py    # Dagster 定义入口
│       │       └── defs/            # 资产定义目录
│       │           └── *.py         # 具体资产实现
│       ├── tests/                   # 测试文件
│       └── pyproject.toml          # 项目配置
└── dg.toml              # workspace 配置
```

## 数据库集成

### PostgreSQL
- 使用 `dagster-postgres` 集成
- 配置连接池
- 使用参数化查询防止 SQL 注入

### Doris
- 使用 JDBC 或 REST API
- 批量写入优化
- 查询性能监控

## 开发流程

1. 查看 GitHub Issues 待办任务
2. 创建 feature worktree 开始开发
3. 实现功能、添加测试
4. Code review 和合并

## 扩展指南

### 添加新的 code location
1. 在 `projects/` 下创建新项目
2. 更新 `dg.toml` 配置
3. 定义新的资产和依赖

### 集成新数据源
1. 查阅 Dagster 集成库
2. 选择合适的集成方式
3. 实现数据源连接
4. 添加质量检查

## 常用命令

```bash
# 启动开发服务器
uv run dg dev

# 列出所有定义
uv run dg list defs

# 运行测试
uv run pytest

# 代码检查
uv run dg check defs

# 材料化资产
uv run dg launch --assets asset_name
```

## 故障排除

### 常见问题
1. 依赖缺失：运行 `uv sync` 更新依赖
2. 资产加载失败：检查 `definitions.py` 配置
3. 连接问题：验证数据库配置

### 调试技巧
- 使用 `context.log` 记录调试信息
- 查看 Dagster UI 中的日志
- 使用 `dg check defs` 验证定义

## 参考资源

- [Dagster 官方文档](https://docs.dagster.io)
- [Dagster 集成库](https://docs.dagster.io/integrations)
- [Python 类型注解](https://docs.python.org/3/library/typing.html)
- [Doris 官方文档](https://doris.apache.org)
