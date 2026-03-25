> **模板仓库说明**: 这是通用开发规范的基础配置文件。项目特定的规范（如 Dagster、数据质量等）请参考 `projects/<project-name>/AGENTS.md`。

# 全局开发规范

## 核心原则

### 代码质量
- **可读性优先**：代码是写给人看的，顺便让机器执行
- **单一职责**：每个函数、类、模块只做一件事
- **防御性编程**：假设一切都会出错，做好异常处理
- **DRY 原则**：不要重复自己，但也不要过度抽象

### 开发流程
- **测试驱动**：先写测试，再写实现（至少对于关键逻辑）
- **小步快跑**：频繁提交，每次提交都是可工作的状态
- **代码审查**：所有代码必须经过审查才能合并
- **文档同步**：代码变更时同步更新文档

## Python 规范

### 版本和工具
- Python 版本：3.12+（优先使用最新稳定版）
- 包管理：根据项目类型选择
  - 数据科学/Dagster：uv
  - 通用项目：pixi 或 uv
  - 简单脚本：pip + venv
- 代码格式化：black
- 导入排序：isort
- 静态检查：pyright 或 mypy

### 代码风格
```python
# 类型注解：使用 Python 3.10+ 语法
def process_data(items: list[str], limit: int = 100) -> dict[str, int]:
    """处理数据并返回统计信息。
    
    Args:
        items: 待处理的字符串列表
        limit: 处理数量限制
    
    Returns:
        包含统计信息的字典
    
    Raises:
        ValueError: 当 items 为空时
    """
    if not items:
        raise ValueError("items cannot be empty")
    
    return {"count": len(items[:limit])}

# 字符串格式化：优先使用 f-string
name = "Alice"
message = f"Hello, {name}!"

# 异常处理：具体异常，不要裸露的 except
try:
    result = risky_operation()
except ValueError as e:
    logger.error(f"Value error: {e}")
    raise
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    raise
```

### 导入规范
```python
# 标准库
import os
import sys
from pathlib import Path
from datetime import datetime

# 第三方库
import pandas as pd
import numpy as np

# 本地模块
from myproject.utils import helper_function
from myproject.models import User
```

## Git 规范

### 提交信息
```
<type>(<scope>): <subject>

<body>

<footer>
```

类型（type）：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链相关

示例：
```
feat(pipeline): add market data ingestion asset

- Implement real-time market data collection
- Add data validation and quality checks
- Include metadata tracking

Closes #123
```

### 分支策略
- `main`: 生产分支，始终保持可部署
- `develop`: 开发分支，集成所有功能
- `feature/*`: 功能分支，从 develop 创建
- `hotfix/*`: 紧急修复，从 main 创建

### 工作流
1. 从最新 develop 创建 feature 分支
2. 在 feature 分支上开发
3. 定期 rebase 到 develop
4. 完成后提交 PR 到 develop
5. 代码审查通过后合并
6. 定期从 develop 合并到 main

## 工具配置

### pyproject.toml 标准配置
```toml
[project]
name = "my-project"
requires-python = ">=3.12"
version = "0.1.0"
dependencies = [
    # 项目依赖
]

[dependency-groups]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "isort>=5.0.0",
    "pyright>=1.1.0",
]

[tool.black]
line-length = 88
target-version = ['py312']

[tool.isort]
profile = "black"
multi_line_output = 3

[tool.pyright]
pythonVersion = "3.12"
typeCheckingMode = "strict"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --tb=short"
```

### pre-commit 配置
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
```

## 环境管理

### 虚拟环境
- 每个项目独立虚拟环境
- 使用 `uv` 或 `pixi` 管理
- 不要提交 `.venv` 目录
- 明确记录 Python 版本要求

### 环境变量
```python
# 使用 python-dotenv
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
API_KEY = os.getenv("API_KEY")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is required")
```

### 配置文件
- 敏感信息：环境变量
- 应用配置：TOML 或 YAML
- 用户配置：JSON
- 不要提交敏感信息到版本控制

## 文档规范

### 代码文档
- 所有公共 API 必须有 docstring
- 使用 Google 风格 docstring
- 包含类型信息（即使有类型注解）
- 提供使用示例

### 项目文档
- README.md：项目概述、快速开始
- CHANGELOG.md：版本变更记录
- CONTRIBUTING.md：贡献指南
- API 文档：自动生成（如 mkdocs）

## 测试规范

### 测试结构
```
tests/
├── unit/              # 单元测试
├── integration/       # 集成测试
├── e2e/              # 端到端测试
├── fixtures/         # 测试数据
└── conftest.py       # pytest 配置
```

### 测试原则
- 每个测试只测一个行为
- 测试命名：`test_<功能>_<条件>_<预期结果>`
- 使用 fixture 管理测试数据
- Mock 外部依赖

### 测试示例
```python
import pytest
from myproject.calculator import Calculator

@pytest.fixture
def calculator():
    return Calculator()

def test_add_two_positive_numbers_returns_sum(calculator):
    result = calculator.add(2, 3)
    assert result == 5

def test_add_negative_numbers_returns_sum(calculator):
    result = calculator.add(-2, -3)
    assert result == -5

def test_divide_by_zero_raises_error(calculator):
    with pytest.raises(ValueError, match="Cannot divide by zero"):
        calculator.divide(10, 0)
```

## 安全规范

### 代码安全
- 输入验证：永远不要信任用户输入
- SQL 注入：使用参数化查询
- XSS：输出编码
- 敏感数据：加密存储和传输

### 依赖安全
- 定期更新依赖
- 使用 `pip audit` 或 `safety` 检查漏洞
- 锁定依赖版本（uv.lock, pixi.lock）

### 密钥管理
- 使用密钥管理服务（如 AWS Secrets Manager）
- 不要硬编码密钥
- 不要提交密钥到版本控制
- 定期轮换密钥

## 性能规范

### 代码性能
- 使用性能分析工具（cProfile, py-spy）
- 避免过早优化
- 关注热点代码
- 使用适当的数据结构

### 数据库性能
- 使用连接池
- 批量操作
- 索引优化
- 查询分析

## 监控和日志

### 日志规范
```python
import logging
import structlog

# 配置结构化日志
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
)

logger = structlog.get_logger()

# 使用示例
logger.info("Processing started", asset_key="market_data", rows=1000)
logger.error("Processing failed", error=str(e), asset_key="market_data")
```

### 监控指标
- 响应时间
- 错误率
- 资源使用率
- 业务指标

## 故障处理

### 错误处理
```python
# 具体异常处理
try:
    result = operation()
except SpecificError as e:
    logger.error(f"Specific error: {e}")
    # 处理特定错误
    raise
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    # 处理未预期错误
    raise

# 重试机制
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
def flaky_operation():
    return external_api_call()
```

### 降级策略
- 识别核心功能
- 实现降级方案
- 监控降级状态
- 自动恢复机制

## 参考资源

- [Python 官方文档](https://docs.python.org/3/)
- [PEP 8 风格指南](https://pep8.org/)
- [Google Python 风格指南](https://google.github.io/styleguide/pyguide.html)
- [Git 最佳实践](https://bestpractices.coreinfrastructure.org/)
- [OWASP 安全指南](https://owasp.org/www-project-top-ten/)
