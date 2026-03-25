# 数据质量检查 Skill

## 概述
自动化数据质量检查和验证，确保数据处理管道的可靠性。

## 触发条件
- 数据采集完成时
- 数据清洗前后
- 定期数据质量巡检
- 数据异常检测时

## 检查维度

### 1. 完整性检查
- 必填字段非空验证
- 记录数量一致性
- 数据覆盖度检查

### 2. 准确性检查
- 数据类型验证
- 值域范围检查
- 格式规范验证

### 3. 一致性检查
- 跨表数据一致性
- 时间序列连续性
- 业务规则一致性

### 4. 及时性检查
- 数据新鲜度
- 处理延迟监控
- 更新频率检查

## 实现模式

### Dagster Asset 中的检查
```python
import dagster as dg
import pandas as pd
from datetime import datetime, timedelta


@dg.asset_check(
    asset="raw_market_data",
    description="检查市场数据的完整性",
)
def check_market_data_completeness(
    context: dg.AssetCheckExecutionContext,
    raw_market_data: pd.DataFrame,
) -> dg.AssetCheckResult:
    """检查市场数据的完整性。"""
    missing_count = raw_market_data.isnull().sum().sum()
    total_cells = raw_market_data.size
    missing_rate = missing_count / total_cells
    
    return dg.AssetCheckResult(
        passed=missing_rate < 0.01,
        metadata={
            "missing_count": dg.MetadataValue.int(missing_count),
            "missing_rate": dg.MetadataValue.float(missing_rate),
            "total_cells": dg.MetadataValue.int(total_cells),
        }
    )


@dg.asset_check(
    asset="raw_market_data",
    description="检查价格数据的合理性",
)
def check_price_range(
    context: dg.AssetCheckExecutionContext,
    raw_market_data: pd.DataFrame,
) -> dg.AssetCheckResult:
    """检查价格数据是否在合理范围内。"""
    if "price" not in raw_market_data.columns:
        return dg.AssetCheckResult(
            passed=False,
            metadata={"error": dg.MetadataValue.text("Missing price column")}
        )
    
    invalid_prices = raw_market_data[
        (raw_market_data["price"] <= 0) | (raw_market_data["price"] > 100000)
    ]
    
    return dg.AssetCheckResult(
        passed=len(invalid_prices) == 0,
        metadata={
            "invalid_count": dg.MetadataValue.int(len(invalid_prices)),
            "price_min": dg.MetadataValue.float(raw_market_data["price"].min()),
            "price_max": dg.MetadataValue.float(raw_market_data["price"].max()),
        }
    )
```

### 数据验证工具类
```python
from dataclasses import dataclass
from typing import Any
import pandas as pd


@dataclass
class QualityCheckResult:
    check_name: str
    passed: bool
    message: str
    metadata: dict[str, Any]


class DataQualityChecker:
    """数据质量检查器。"""
    
    def __init__(self, df: pd.DataFrame):
        self.df = df
        self.results: list[QualityCheckResult] = []
    
    def check_null_values(
        self, 
        columns: list[str], 
        threshold: float = 0.01
    ) -> "DataQualityChecker":
        """检查空值比例。"""
        for col in columns:
            if col not in self.df.columns:
                self.results.append(QualityCheckResult(
                    check_name=f"null_check_{col}",
                    passed=False,
                    message=f"Column {col} not found",
                    metadata={"column": col}
                ))
                continue
            
            null_rate = self.df[col].isnull().mean()
            self.results.append(QualityCheckResult(
                check_name=f"null_check_{col}",
                passed=null_rate < threshold,
                message=f"Null rate: {null_rate:.2%}",
                metadata={"column": col, "null_rate": null_rate}
            ))
        
        return self
    
    def check_unique_values(
        self, 
        columns: list[str]
    ) -> "DataQualityChecker":
        """检查唯一值。"""
        for col in columns:
            if col not in self.df.columns:
                continue
            
            unique_count = self.df[col].nunique()
            total_count = len(self.df)
            
            self.results.append(QualityCheckResult(
                check_name=f"unique_check_{col}",
                passed=True,
                message=f"Unique values: {unique_count}/{total_count}",
                metadata={
                    "column": col,
                    "unique_count": unique_count,
                    "total_count": total_count
                }
            ))
        
        return self
    
    def check_value_range(
        self,
        column: str,
        min_value: float | None = None,
        max_value: float | None = None
    ) -> "DataQualityChecker":
        """检查值域范围。"""
        if column not in self.df.columns:
            self.results.append(QualityCheckResult(
                check_name=f"range_check_{column}",
                passed=False,
                message=f"Column {column} not found",
                metadata={"column": column}
            ))
            return self
        
        series = self.df[column]
        invalid_mask = pd.Series([False] * len(series))
        
        if min_value is not None:
            invalid_mask |= series < min_value
        if max_value is not None:
            invalid_mask |= series > max_value
        
        invalid_count = invalid_mask.sum()
        
        self.results.append(QualityCheckResult(
            check_name=f"range_check_{column}",
            passed=invalid_count == 0,
            message=f"Invalid values: {invalid_count}",
            metadata={
                "column": column,
                "invalid_count": invalid_count,
                "min_value": min_value,
                "max_value": max_value
            }
        ))
        
        return self
    
    def get_results(self) -> list[QualityCheckResult]:
        """获取所有检查结果。"""
        return self.results
    
    def all_passed(self) -> bool:
        """检查是否所有检查都通过。"""
        return all(result.passed for result in self.results)
```

## 集成到 Dagster

### 在 Asset 中使用检查器
```python
@dg.asset(
    group_name="validated",
    description="经过质量检查的市场数据",
)
def validated_market_data(
    context: dg.AssetExecutionContext,
    raw_market_data: pd.DataFrame,
) -> dg.MaterializeResult:
    """验证市场数据质量。"""
    checker = DataQualityChecker(raw_market_data)
    
    # 执行质量检查
    checker.check_null_values(["symbol", "price", "volume"])
    checker.check_value_range("price", min_value=0, max_value=100000)
    checker.check_value_range("volume", min_value=0)
    
    results = checker.get_results()
    
    # 记录检查结果
    for result in results:
        if not result.passed:
            context.log.error(
                f"Quality check failed: {result.check_name}",
                extra=result.metadata
            )
    
    if not checker.all_passed():
        raise ValueError("Data quality checks failed")
    
    return dg.MaterializeResult(
        metadata={
            "checks_passed": dg.MetadataValue.int(
                sum(1 for r in results if r.passed)
            ),
            "checks_total": dg.MetadataValue.int(len(results)),
            "validation_time": dg.MetadataValue.text(str(datetime.now())),
        }
    )
```

## 监控和报告

### 质量指标跟踪
- 检查通过率
- 检查失败原因分布
- 质量趋势分析

### 告警规则
- 单次检查失败
- 连续失败次数
- 质量指标下降

## 最佳实践

### 检查策略
- 分层检查：采集层、清洗层、存储层
- 渐进式验证：简单到复杂
- 性能考虑：避免过度检查

### 错误处理
- 记录详细错误信息
- 支持检查跳过选项
- 提供修复建议

### 可维护性
- 检查规则配置化
- 支持动态添加检查
- 版本化检查规则
