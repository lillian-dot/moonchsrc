# MoonChsrc roadmap

目标：把 MoonChsrc 建设成可维护、可扩展、跨平台的 MoonBit 换源工具，
覆盖 chsrc 的核心使用体验，而不是逐行翻译其 C 实现。

## M1：可扩展核心框架

- [x] 目标、镜像、作用域和类型化错误模型
- [x] 多步骤执行计划
- [x] Shell-free 原生进程执行器
- [x] `list`、`get`、`set`、`reset` 和 `--dry-run`
- [x] recipe 注册与能力声明，消除 planner 中的目标分支
- [x] 统一的命令输出、退出码和部分失败报告

完成标准：新增目标时只需要添加 recipe 与测试，不修改 CLI 分发器。

## M2：安全修改与恢复

- [x] 修改前读取当前配置
- [x] 本地历史记录和备份
- [x] `restore` 恢复最近一次修改
- [x] 多步骤事务：失败后回滚已完成步骤
- [x] 敏感配置脱敏，禁止记录 token/password

完成标准：所有写操作都可预览、可恢复，并有失败路径测试。

## M3：主流 recipe

- [x] npm、pnpm、Yarn 2+、Node 聚合目标
- [x] pip
- [x] Go modules
- [x] MoonBit / mooncakes
- [x] Cargo（rustup 待实现）
- [ ] uv / Poetry
- [ ] Maven / Gradle
- [x] RubyGems（Bundler 待实现）
- [x] Composer
- [ ] Docker / Homebrew

完成标准：每个 recipe 至少支持 get/set/reset、官方源、一个国内镜像和核心测试。

## M4：测速与自动选择

- [x] 镜像测速探针和超时模型
- [x] 并发测速与稳定排序
- [x] `measure <target>`
- [x] `set <target> auto|first`
- [ ] IPv4 / IPv6 选择

完成标准：可复现的测速测试和真实网络集成测试分离。

## M5：跨平台与发行

- [x] Windows、Linux、macOS 路径与权限适配（待 CI 首次远端验证）
- [x] x64、arm64 原生构建矩阵（待 CI 首次远端验证）
- [x] GitHub Actions：check、build、test（待首次远端运行验证）
- [x] 安装脚本和校验和（待首次 GitHub Release 验证）
- [ ] mooncakes.io 发布

## M6：比赛与社区交付

- [x] 架构、recipe 编写和贡献文档
- [x] 上游来源、许可证和独立实现边界说明
- [ ] 可运行演示与终端录屏
- [ ] GitHub / Gitlink 同步
- [ ] 一页项目申报书与最终验收清单

## 当前质量门

每个里程碑合入前必须通过：

```text
moon check --warn-list +unnecessary_annotation
moon test
moon fmt
moon info
```
