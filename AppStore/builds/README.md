# 宠刻 1.0.0（3）构建说明

## 当前可提交构建

- 文件：`PawprintDiary-1.0.0-3.ipa`
- App 显示名称：`宠刻`
- Bundle ID：`com.anto.PawprintDiary`
- Team ID：`8K38W4M6JJ`
- 最低系统：iOS/iPadOS 17.0
- 设备族：iPhone、iPad
- 架构：arm64
- 签名：Cloud Managed Apple Distribution，`get-task-allow=false`
- Sign in with Apple entitlement：已包含
- 隐私清单：已包含
- 最新内容：正式名称更新为“宠刻”、相册选择修复、洗澡记录、68 个指定猫种及“其它”自定义入口
- SHA-256：`eaf3230c825eb6cd2ba98878de2083d76ec1cf908535e7677d3689f6822adca5`

对应文件：

- `DistributionSummary-1.0.0-3.plist`：分发签名与权限摘要
- `Packaging-1.0.0-3.log`：Xcode 导出日志

## 历史构建

`PawprintDiary-1.0.0-1.ipa` 早于相册选择修复、洗澡记录和最新猫种名单；`PawprintDiary-1.0.0-2.ipa` 仍使用旧显示名称“爪印日记”。两者仅用于历史追踪，禁止提交 App Store Connect。

1.0.0（3）尚未上传 App Store Connect。生产 Supabase 的 Apple Provider 已启用，`delete-account` v2 已部署为 ACTIVE 且启用 JWT 校验。上传前仍需完成公开隐私政策/支持页、商店资料与 TestFlight 双 Apple 账号端到端验收。
