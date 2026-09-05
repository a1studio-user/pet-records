# 1.0.0 上架清单

## Apple Developer

- [x] 使用开发者账号创建/确认 App ID：`com.anto.PawprintDiary`
- [x] 为 App ID 开启 Sign in with Apple capability
- [x] 在 Xcode Accounts 登录对应 Team，并通过云托管 Apple Distribution 证书/描述文件完成分发导出
- [ ] 在 App Store Connect 创建/确认 App 记录，名称使用“宠刻”
- [ ] 若在中国大陆上架，准备并填写与 App/开发者信息匹配的有效 ICP 备案号

## Supabase

- [x] 数据表、唯一八位分享码、成员关系和 RLS 已部署
- [x] Authentication → Providers → Apple：生产设置接口确认已启用
- [x] `delete-account` Edge Function v2 已部署为 ACTIVE，且 `verify_jwt=true`
- [x] 不带身份的生产请求实测返回 HTTP 401
- [x] 客户端和 Edge Function 已实现再次 Apple 授权及 token revocation 流程
- [ ] 配置 Apple 服务端 Secrets，并用测试账号验证撤销成功
- [x] 使用两个隔离临时身份完成数据库级测试：加入、五类记录同步、编辑、删除冲突、移除、退出共享、重置代码；临时数据已清理
- [ ] TestFlight 使用两个真实 Apple 测试账号完成同一套端到端验证
- [ ] 验证删除账号后 auth user、宠物、记录、成员关系和 Storage 对象均被移除

## App Store Connect

- [ ] 填写 `metadata-zh-Hans.md` 中的名称、副标题、描述、关键词和审核备注
- [ ] 发布 `site/privacy.html` 和 `site/support.html`，填写公开 HTTPS URL
- [ ] 按 `app-privacy.md` 填写并发布隐私标签
- [ ] 完成年龄分级问卷；无暴力、色情、赌博、医疗建议或公开社交内容，不选择 Made for Kids
- [ ] 内容版权：确认所有 App 图标、照片示例、文案和数据名称均有权使用
- [ ] 出口合规：工程已声明只使用系统/标准传输加密，不含非豁免加密
- [ ] 填写审核联系人姓名、电话、邮箱（不要使用隐私中转邮箱）
- [ ] 上传 iPhone 与 iPad 截图

## 构建与验收

- [x] Release 版本号：1.0.0（Build 3）
- [x] iPhone/iPad 通用设备族，最低 iOS/iPadOS 17
- [x] 相机、相册说明与隐私清单已加入包内
- [x] 小屏 iPhone、灵动岛 iPhone、大屏 iPhone、iPad mini、11/13 英寸 iPad 模拟器验收
- [ ] 横屏和 iPad 分屏验收
- [x] 超大动态字体模拟器验收
- [x] 已生成 5 张 1284 × 2778 的 iPhone JPG 和 5 张 2064 × 2752 的 iPad JPG，均无透明通道并使用“宠刻”名称
- [ ] VoiceOver 真机验收
- [x] 保留 Bluelue 数据的覆盖安装验收；未卸载旧包，原有容器与数据保留
- [x] 使用 Release + App Store Distribution 执行 Archive
- [x] 已重新导出包含相册修复、洗澡记录及最新猫种名单的 App Store Connect 分发 IPA，并核对版本、签名、Apple entitlement 与隐私清单
- [ ] 上传 App Store Connect / TestFlight 并完成 Apple 服务端校验
- [ ] TestFlight 完成 Apple 登录、后台同步、照片、共享和账号删除回归
