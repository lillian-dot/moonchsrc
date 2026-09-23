# MoonChsrc：MoonBit 原生开发工具换源器

## 项目定位

MoonChsrc 面向需要在不同网络环境中使用开发工具的开发者。它受
[chsrc](https://github.com/RubyMetric/chsrc) 的产品思路启发，以 MoonBit
独立实现“选择目标、查看镜像、预览并切换来源、恢复原配置”的完整流程；
不移植或复制上游 C 代码。源码以 Apache-2.0 开源。

## 已完成的能力

- 覆盖 11 个目标：npm、pnpm、Yarn 2+、Node 聚合目标、pip、Go modules、
  Composer、Cargo、RubyGems、mooncakes、Flathub。
- 统一提供 `list`、`get`、`set`、`reset`、`restore` 和 `measure`；
  支持适用目标的 project / user / system 作用域，以及 `auto` / `first` 选源。
- 所有写操作可先用 `--dry-run` 预览；执行前保存快照，失败时尝试回滚；
  含凭据的配置会被脱敏，无法安全恢复时拒绝写入。
- 核心规则由 MoonBit recipe 和类型化执行计划表达；外部工具通过原生进程
  API 调用，不拼接 shell 命令。Cargo 和 mooncakes 使用结构化文件步骤。

## 可复现验证

仓库提供 36 项 MoonBit 测试和 Windows、Linux、macOS 构建/测试矩阵。
在安装了 MoonBit CLI 与 npm 的 Linux/macOS 机器上运行：

```bash
moon check --target native
moon test --target native
sh scripts/demo-isolated-npm.sh
```

演示脚本在仓库内建立临时 npm 配置与历史目录，依次验证 dry-run、真实换源、
查询和恢复，不改写日常使用的 npm 用户配置。Linux x64/ARM64、macOS
ARM64、Windows x64 提供原生 Release；Mooncakes 模块名为
`lillian-dot/moonchsrc`。

## 当前边界与下一步

并非 chsrc 的全量目标覆盖：uv/Poetry、Maven/Gradle、Docker/Homebrew、
rustup、Bundler 与 IPv4/IPv6 策略仍在路线图中。接下来优先扩展 recipe，
补充更多隔离的真实执行测试，并录制终端演示。项目源代码、架构、贡献说明
和开发计划均在[仓库](https://github.com/lillian-dot/moonchsrc)公开。
