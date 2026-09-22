# MoonChsrc architecture

MoonChsrc 将领域逻辑、系统副作用和命令行入口分开，目标是让新增 recipe
不需要修改 CLI 或中央分发器。

## 数据流

```text
CLI arguments
    │
    ▼
dispatch_cli ──► Show
    │
    ├──────────► Execute(ChangePlan)
    │                  │
    │                  ▼
    │             native executor
    │                  │
    │          capture current source
    │                  │
    │          redact + persist snapshot
    │                  │
    │          execute commands in order
    │                  │
    │          rollback on partial failure
    │
    └──────────► RestoreLatest
                       │
                load matching snapshot
                       │
                  plan_restore

    ├──────────► MeasureTarget
    │                  │
    │          concurrent HTTPS probes
    │                  │
    │          timeout + stable ranking
    │
    └──────────► AutoSelect
                       │
                 measure + choose fastest
                       │
                 Execute(ChangePlan)
```

## 包职责

- 根包：公开类型、recipe 注册、纯计划生成、CLI 参数解析和文本渲染。
- `internal/executor`：启动外部进程、捕获修改前状态、顺序执行与回滚。
- `internal/history`：快照 JSON、默认状态目录和最新快照检索。
- `internal/measure`：原生 HTTPS 探针、逐源超时和受限并发测速。
- `cmd/main`：连接 CLI 动作与运行时，不承载 recipe 规则。

## Recipe 合约

每个 recipe 在 [recipe.mbt](../recipe.mbt) 注册：

1. `Target` 元数据：ID、别名、作用域、能力和镜像端点；
2. `capture_command`：把工具输出规范化为可恢复的历史值；
3. `set_commands` / `get_commands` / `restore_commands`：生成原生进程步骤；
4. 对结构化配置，使用相应的 set/get/restore 文件步骤。

聚合目标可以返回多条命令。例如 `node` 同时管理 npm、pnpm 和 Yarn。
执行器不理解目标名称，只执行 recipe 产生的 `ChangePlan`。

## 安全边界

- 命令名和参数以数组交给进程 API，不拼接 shell 字符串；
- `--dry-run` 只渲染计划；
- 写操作必须先成功捕获并保存快照；
- URL 中含 userinfo、token、password 或 auth 查询参数时标记为
  `Redacted`，拒绝执行不可恢复的修改；
- 多步骤计划失败后按快照生成恢复命令；
- 历史默认写入用户状态目录，不写入项目仓库。
- 自动选择只接受成功返回响应头的端点；所有探针失败时拒绝修改。

## 文件型 recipe 边界

Cargo 和 mooncakes 等目标需要修改 TOML/JSON 文件，不能安全地退化为
shell 文本替换。执行计划使用类型化文件步骤，并满足：

1. 保留无关配置、注释和用户自定义仓库；
2. 同目录临时文件写入后原子替换；
3. 修改前保存完整原文件或“文件不存在”状态；
4. 命令步骤或文件步骤任一失败时按相反顺序回滚；
5. dry-run 渲染目标路径和结构化变更，但不写文件。

## 新增 recipe

1. 添加该工具的小型命令或文件步骤构造函数；
2. 在 [recipe.mbt](../recipe.mbt) 注册一个 `Recipe`；
3. 至少添加 get/set/reset、缺失值恢复和错误作用域测试；
4. 更新 README 支持列表；
5. 运行项目质量门。

完整检查表见 [RECIPES.md](RECIPES.md)。
