# MoonChsrc

MoonChsrc 是一个用 MoonBit 编写的跨工具链换源引擎与命令行工具。项目受
[chsrc](https://github.com/RubyMetric/chsrc) 启发，但采用独立的 MoonBit
数据模型与实现，不复制上游 C 源码。

发布：[GitHub v0.2.0](https://github.com/lillian-dot/moonchsrc/releases/tag/v0.2.0) ·
[Mooncakes `lillian-dot/moonchsrc`](https://mooncakes.io/docs/lillian-dot/moonchsrc)

0.2.0 提供一个安全优先、可实际使用的版本：

- 列出内置目标与镜像；
- 支持 npm、pnpm、Yarn 2+、Node 聚合目标、pip、Go modules、Composer、Cargo、RubyGems、mooncakes 和 Flathub；
- 为 project、user、system 三种作用域生成明确的换源命令；
- `set --dry-run` 只预览，不改写用户配置；
- `set` 通过原生进程 API 直接执行，不使用 shell 字符串拼接；
- `get` 查询当前生效的源；
- `reset` 将目标恢复到官方上游源；
- 写操作前保存当前配置，`restore` 可恢复最近一次快照；
- 多步骤失败时自动回滚，含凭据的源地址不会明文写入历史。
- `measure` 使用原生 HTTPS 并发探测镜像，逐源超时后稳定排序。

## 安装

Linux / macOS：

```bash
curl -fsSL https://raw.githubusercontent.com/lillian-dot/moonchsrc/main/scripts/install.sh | sh
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/lillian-dot/moonchsrc/main/scripts/install.ps1 | iex
```

安装器会下载当前 GitHub Release 中与平台匹配的原生程序，并使用
`SHA256SUMS` 验证文件。目前提供 Linux x64/ARM64、macOS ARM64 和
Windows x64 原生程序。也可以从源码运行或安装 Mooncakes 模块：

```bash
moon add lillian-dot/moonchsrc
```

## 运行

```bash
moon run cmd/main -- list
moon run cmd/main -- list npm
moon run cmd/main -- set --dry-run npm npmmirror user
moon run cmd/main -- set --dry-run pip tuna project
moon run cmd/main -- get --dry-run node user
moon run cmd/main -- set --dry-run go goproxycn user
moon run cmd/main -- set --dry-run composer aliyun user
moon run cmd/main -- set --dry-run npm auto user
moon run cmd/main -- set --dry-run pip first project
moon run cmd/main -- set --dry-run cargo rsproxy user
moon run cmd/main -- set --dry-run moonbit ustc user
moon run cmd/main -- set --dry-run rubygems rubychina user
moon run cmd/main -- set --dry-run flatpak ustc user
moon run cmd/main -- set npm npmmirror user
moon run cmd/main -- reset npm user
moon run cmd/main -- restore --dry-run npm user
moon run cmd/main -- restore npm user
moon run cmd/main -- measure npm
```

## MoonBit API

```mbt check
///|
test "build a source-change plan" {
  let plan = plan_change("npm", "npmmirror", scope=Project)
  assert_eq(plan.target_id, "npm")
  assert_eq(plan.scope, Project)
}
```

## 路线图

完整里程碑、完成标准和质量门见 [docs/ROADMAP.md](docs/ROADMAP.md)。
架构和 recipe 扩展说明见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
参与开发请见 [CONTRIBUTING.md](CONTRIBUTING.md)，recipe 编写清单见
[docs/RECIPES.md](docs/RECIPES.md)。

## 来源与许可证

- 参考项目：RubyMetric/chsrc
- 上游链接：https://github.com/RubyMetric/chsrc
- 上游许可证：GPL-3.0-or-later（部分组件为 MIT）
- 参考范围：命令行领域模型与“目标/镜像/recipe”概念；本仓库为独立实现。
- 本项目许可证：Apache-2.0
# MoonChsrc

MoonBit 编写的跨工具链换源引擎与命令行工具。完整说明与可测试示例见
[README.mbt.md](README.mbt.md)。
