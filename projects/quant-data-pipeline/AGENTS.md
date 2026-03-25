> **项目配置说明**: 这是 quant-data-pipeline 项目的专属开发规范。通用开发规范（Python 风格、Git 规范、测试标准、安全规范等）请参考 [全局开发规范](../../AGENTS.md)。

## 项目概述

这是一个基于 Dagster 的量化投资数据处理项目，采用多 code locations 架构，支持：
- 数据采集 → 清洗 → 存储 → 分析
- 实时行情处理
- 多种数据源集成（Doris, PostgreSQL）

## 代码规范

### Python 代码风格
- Python 版本：3.12+
- 包管理：uv（Dagster 官方推荐）
- 代码风格：遵循 PEP 8
- 类型注解：使用 Python 3.10+ 类型语法（`list[str]` 而非 `List[str]`）
- 字符串格式化：优先使用 f-string

### Dagster 最佳实践

#### Asset 定义
- 使用 `@dg.asset` 装饰器定义资产
- 每个 asset 职责单一，逻辑清晰
- 添加详细的 docstring 作为描述
- 使用 `group_name` 组织相关资产

#### 数据处理模式
```python
@dg.asset(
    group_name="raw_data",
    description="原始数据描述",
)
def raw_data_asset(context: dg.AssetExecutionContext) -> dg.MaterializeResult:
    """处理原始数据。
    
    Args:
        context: Dagster 执行上下文
    
    Returns:
        MaterializeResult: 包含处理结果和元数据
    """
    # 数据处理逻辑
    context.log.info("开始处理数据")
    
    return dg.MaterializeResult(
        metadata={
            "row_count": dg.MetadataValue.int(row_count),
            "processing_time": dg.MetadataValue.text(str(datetime.now())),
        }
    )
```

#### 依赖管理
- 参数依赖：用于 Dagster 管理的资产
- `deps=` 依赖：用于外部或非 Python 资产
- 避免循环依赖

## 数据质量

### 验证规则
- 必填字段检查
- 数据类型验证
- 值域范围检查
- 时间序列连续性验证

### 错误处理
- 使用 `try-except` 捕获异常
- 记录详细的错误日志
- 返回有意义的错误信息
- 避免静默失败

### 元数据记录
- 记录数据行数
- 记录处理时间
- 记录数据样本
- 记录质量指标

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

详细流程请参考 [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

### 概述
1. 查看 GitHub Issues 待办任务
2. 创建 feature worktree 开始开发
3. 实现功能、添加测试
4. Code review 和合并

### 代码审查
- 检查代码规范
- 验证数据质量逻辑
- 确保安全性
- 性能评估

## 安全规范

### 数据安全
- 敏感数据加密存储
- 访问权限控制
- 审计日志记录

### 代码安全
- 避免硬编码凭证
- 使用环境变量
- 定期更新依赖

## 监控和日志

### 日志规范
- 使用 Dagster 内置日志系统
- 记录关键操作
- 包含上下文信息（asset key, run ID）

### 监控指标
- 数据处理成功率
- 处理延迟
- 数据质量分数
- 资源使用率

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

## Skills 使用指南

### 已安装的 Skills

本项目使用以下 opencode skills：

- **dagster-expert**: Dagster 官方 skill，包含：
  - Asset 定义和依赖管理
  - 自动化（Schedules、Sensors、Declarative Automation）
  - 组件和集成（40+ 工具集成）
  - CLI 命令参考（dg dev、dg launch、dg scaffold）
  - 项目结构和配置

- **dignified-python**: Python 生产级编码标准，包含：
  - Python 3.10-3.13 版本特性
  - 类型注解规范
  - 异常处理最佳实践
  - 路径操作和 ABC 接口

- **data-quality-checker**: 量化数据质量检查（本项目专用），包含：
  - 完整性、准确性、一致性检查
  - Dagster Asset Check 集成
  - 质量指标监控

### 使用方式

在开发时，opencode 会自动加载相关 skills。对于 Dagster 相关问题：
1. 先查阅 `dagster-expert` skill 的参考文档
2. 使用 `dg` CLI 命令而不是手动创建文件
3. 遵循 skill 中的集成工作流

## 参考资源

- [Dagster 官方文档](https://docs.dagster.io)
- [Dagster 集成库](https://docs.dagster.io/integrations)
- [Python 类型注解](https://docs.python.org/3/library/typing.html)
- [Doris 官方文档](https://doris.apache.org)
