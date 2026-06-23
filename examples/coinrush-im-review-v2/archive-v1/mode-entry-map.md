# 高风险入口识别

> 大项目审计前先跑一轮，产出审计地图。

```text
不要直接报告问题。识别项目中的高风险入口和核心状态对象，作为后续审计地图。

输出：

1. 公网 HTTP / WebSocket / callback 入口
2. RPC 入口
3. job / worker / 定时任务入口
4. destructive tools / scripts
5. 核心 MySQL 表和 Redis key
6. 核心状态字段和状态流转路径
7. 资金 / 结算 / 支付 / 礼物相关路径
8. 权限 / 鉴权 / 角色判断路径
9. 关键外部依赖和配置项
10. 发布 / migration / compose / CI 入口

每个入口给出：文件路径、函数名、触发方式、涉及的核心状态、建议优先审计主题。
```
