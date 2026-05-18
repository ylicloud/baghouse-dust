# BridgeService 模块设计 v1

## 1. 定位

BridgeService 是平台的数据桥接与同步服务，运行在现场 Windows 11 mini 主机上，目标框架统一为 `.NET 10`。

它的职责不是替代 WinCC 或 Kepware 的底层采集能力，而是：

- 从 Kepware OPC UA 读取平台需要的数据；
- 按平台统一模型进行标准化；
- 将实时快照、历史数据、设备状态和平台报警写入 SQL Server；
- 为 Web、手机端、报表和后续通知功能提供稳定的数据来源。

## 2. 设计原则

### 2.1 不重复造底层采集轮子

BridgeService 不负责：

- 直接连接 PLC 进行多协议采集；
- 重建 Kepware 的驱动层、扫描周期和通信管理；
- 替代 WinCC 现场报警与归档体系。

BridgeService 只负责平台侧同步与标准化。

### 2.2 配置驱动

BridgeService 的设备、点位、报警、快照周期、历史策略尽量通过配置或数据库定义，不通过硬编码实现。

### 2.3 单向主数据流

第一阶段建议只实现单向数据流：

```text
Kepware OPC UA -> BridgeService -> SQL Server -> Web / 手机端
```

暂不实现平台直接写回 PLC 的控制链路。

### 2.4 可恢复和可追踪

BridgeService 需要具备：

- 断线重连；
- 失败重试；
- 同步游标；
- 幂等写入；
- 运行日志；
- 健康检查。

## 3. 部署与运行方式

BridgeService 建议使用 `.NET 10 Worker Service` 开发，并部署为 Windows Service。

运行要求：

- 与 Kepware 和 SQL Server 网络可达；
- 使用独立服务账号或专用本地账号运行；
- 启动后自动连接 OPC UA 并进入同步循环；
- 服务重启后能从最近游标恢复。

## 4. 模块划分

建议目录结构如下：

```text
IndustrialMonitor.BridgeService/
├─ Workers/
├─ OpcUa/
├─ Sync/
├─ Alarming/
├─ Persistence/
├─ Diagnostics/
├─ Configuration/
└─ Program.cs
```

### 4.1 Workers

职责：

- 托管整个服务生命周期；
- 服务启动时加载配置；
- 控制各子模块启动顺序；
- 响应停止、取消和重启。

建议核心类：

- `BridgeWorker`
- `StartupOrchestrator`
- `ShutdownCoordinator`

### 4.2 OpcUa

职责：

- 负责与 Kepware OPC UA 建立连接；
- 建立会话、订阅和节点读取；
- 管理证书和会话重连；
- 输出统一的数据采集事件。

建议核心类：

- `OpcUaSessionFactory`
- `OpcUaConnectionManager`
- `OpcUaSubscriptionManager`
- `OpcUaNodeReader`
- `OpcUaCertificateService`

建议接口：

- `IOpcUaClient`
- `IOpcUaSessionManager`
- `IOpcUaSubscriptionService`

### 4.3 Sync

职责：

- 执行快照同步和历史写入；
- 控制点位分组、批量写库；
- 维护同步游标和幂等机制；
- 决定哪些点位写快照，哪些写历史。

建议核心类：

- `SnapshotSyncService`
- `HistorySyncService`
- `TagValueNormalizer`
- `SyncCheckpointService`
- `BatchPersistenceCoordinator`

建议接口：

- `ISnapshotSyncService`
- `IHistorySyncService`
- `ISyncCheckpointStore`

### 4.4 Alarming

职责：

- 根据平台报警定义计算报警事件；
- 生成报警产生、恢复、确认相关记录；
- 管理报警状态机；
- 为后续通知模块提供事件来源。

建议核心类：

- `AlarmEvaluationService`
- `AlarmStateMachine`
- `AlarmEventFactory`
- `AlarmRecoveryEvaluator`

建议接口：

- `IAlarmEvaluationService`
- `IAlarmEventWriter`

### 4.5 Persistence

职责：

- 屏蔽数据库访问细节；
- 提供快照、历史、报警、设备状态、同步游标的写入能力；
- 承担事务边界和批量写入。

建议核心类：

- `PlatformDbContext`
- `TagSnapshotRepository`
- `TagHistoryRepository`
- `AlarmEventRepository`
- `DeviceStatusRepository`
- `SyncCheckpointRepository`

### 4.6 Diagnostics

职责：

- 输出结构化日志；
- 提供服务运行指标；
- 记录同步失败、重连、数据质量异常；
- 生成可用于页面或运维的健康状态。

建议核心类：

- `BridgeHealthService`
- `BridgeMetricsCollector`
- `StructuredLogScopeFactory`
- `ErrorClassifier`

### 4.7 Configuration

职责：

- 读取 appsettings、JSON 模板和数据库配置；
- 把设备、点位、报警和同步策略装配成运行时对象；
- 支持后续热更新扩展。

建议核心类：

- `DeviceDefinitionProvider`
- `TagDefinitionProvider`
- `AlarmDefinitionProvider`
- `BridgeOptionsValidator`

## 5. 运行流程

### 5.1 启动流程

```text
服务启动
  -> 加载配置
  -> 校验数据库连接
  -> 初始化 OPC UA 客户端
  -> 建立会话
  -> 建立订阅
  -> 启动快照/历史/报警同步任务
  -> 持续运行
```

### 5.2 数据处理主流程

```text
OPC UA 数据到达
  -> 节点映射到平台 TagDefinition
  -> 值类型标准化
  -> 质量码过滤
  -> 写 TagSnapshots
  -> 根据策略写 TagHistory
  -> 更新 DeviceStatusSnapshots
  -> 执行报警规则计算
  -> 记录 SyncCheckpoint
```

### 5.3 停止流程

```text
收到停止信号
  -> 停止接收新任务
  -> 刷新批量写入缓存
  -> 保存同步游标
  -> 关闭 OPC UA 会话
  -> 服务退出
```

## 6. 同步策略

BridgeService 不重复 Kepware 的底层扫描策略，但需要实现平台侧同步策略。

### 6.1 点位分类

建议把点位分为三类：

1. **快照点位**
   - 用于总览页和手机首页；
   - 只保留最新值。

2. **历史点位**
   - 用于趋势和报表；
   - 按变化或按固定周期落历史。

3. **报警源点位**
   - 用于平台级报警规则判断；
   - 需要较高及时性。

### 6.2 同步模式

建议采用：

- **数据变化订阅**：用于重要状态位和关键模拟量；
- **周期快照**：用于总览页和不频繁变化的展示数据；
- **条件入历史**：通过 `ArchiveEnabled` 和 `Deadband` 控制写库。

### 6.3 建议的默认策略

- 报警相关点位：订阅 + 实时判断
- 运行状态点位：订阅 + 5 秒快照
- 一般趋势点位：变化写入或 10 秒快照入历史
- 统计类点位：30 秒或 60 秒快照

## 7. 同步游标与幂等

### 7.1 为什么需要游标

BridgeService 写库时需要防止：

- 服务重启后重复写入；
- 处理失败后漏数据；
- 批量写入时乱序。

### 7.2 建议的游标模型

每个同步任务维护一条 `SyncCheckpoints` 记录：

- `SyncKey`
- `LastSourceTimestamp`
- `LastSequence`
- `LastStatus`
- `LastError`
- `UpdatedAt`

### 7.3 幂等建议

建议使用以下策略之一：

1. 快照表按主键覆盖；
2. 历史表按 `TagId + SourceTimestamp + Value` 做唯一性约束或业务去重；
3. 报警事件按“报警定义 + 状态切换时间”去重。

## 8. 设备状态聚合

BridgeService 需要产出设备级状态，供 Web 快速查询，而不是每次现算。

建议聚合字段：

- `RunStatus`
- `FaultStatus`
- `AlarmLevel`
- `IsOnline`
- `LastSeenAt`
- `UpdatedAt`

建议由 `DeviceStatusProjector` 完成设备状态投影。

## 9. 报警处理策略

第一阶段建议采用轻量平台报警，不直接复制 WinCC 全量报警体系。

### 9.1 推荐纳入平台报警的类别

- 设备离线
- 通信质量异常
- 关键故障位
- 关键模拟量超上限
- 关键模拟量超下限

### 9.2 第一阶段不建议纳入的平台报警类别

- 极复杂联锁报警
- 需要多点位时序计算的高级工艺报警
- 完全替代 WinCC 的全量报警画面逻辑

## 10. 错误处理与重试

### 10.1 OPC UA 连接异常

策略建议：

- 短间隔快速重试若干次；
- 超过阈值后进入退避重连；
- 写健康日志并标记服务降级状态。

### 10.2 数据库写入异常

策略建议：

- 当前批次失败时记录日志；
- 不立即推进游标；
- 允许下轮重试；
- 避免因单条脏数据导致整个服务崩溃。

### 10.3 配置异常

策略建议：

- 启动前严格校验；
- 对缺失节点、重复编码、无效周期直接阻止服务启动。

## 11. 健康检查

建议暴露 BridgeService 的内部健康状态，供后续 Web 页面或运维查看。

建议项：

- OPC UA 会话是否在线
- 最后一次成功同步时间
- 最近错误信息
- 当前订阅数
- 当前设备在线数
- 当前批量写入耗时

## 12. 与 Web 的边界

BridgeService 和 Web 建议为两个独立项目，但共享统一的数据模型和数据库。

边界如下：

- BridgeService：负责数据进入平台
- Web：负责数据展示、查询、权限和报表

第一阶段不建议让 Web 直接管理 OPC UA 连接。

## 13. 第一阶段最小实现清单

建议第一阶段 BridgeService 至少实现以下能力：

1. 读取设备与点位配置
2. 连接 Kepware OPC UA
3. 建立关键点位订阅
4. 写入 `TagSnapshots`
5. 写入 `TagHistory`
6. 更新 `DeviceStatusSnapshots`
7. 写入 `AlarmEvents`
8. 维护 `SyncCheckpoints`
9. 输出结构化日志

## 14. 当前版本定版建议

BridgeService v1 建议定版为：

- 基于 `.NET 10 Worker Service`
- 作为独立 Windows Service 运行
- 从 Kepware OPC UA 读取数据
- 采用“订阅 + 周期快照”的平台同步模式
- 将数据写入 SQL Server 平台库
- 先实现轻量平台报警与设备状态投影
