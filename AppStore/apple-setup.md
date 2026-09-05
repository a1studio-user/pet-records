# Apple 登录与发布配置

以下步骤需要 Apple Developer/App Store Connect 账号权限，不能仅通过本地工程自动完成。

## 1. Apple Developer

1. 在 Identifiers 中确认 App ID `com.anto.PawprintDiary`。
2. 为该 App ID 开启 Sign in with Apple。
3. 在 Xcode → Settings → Accounts 登录对应团队，刷新开发与 App Store Distribution 描述文件。
4. 若 Supabase 要求 Web OAuth 回调，再创建 Services ID、Key 与私钥；私钥只保存于安全的服务端 Secret，不得放进 App 或提交仓库。

## 2. Supabase Auth

1. 打开 Authentication → Providers → Apple。
2. 启用 Apple Provider，并按项目控制台字段配置 Bundle ID/Services ID 与 Apple 凭据。
3. 使用两个真实 Apple 测试账号验证：首次绑定、重装恢复、共同饲养、移除成员、退出共享与重置分享码。

## 3. 账号删除

- 仓库中的 `supabase/functions/delete-account/index.ts` 使用 service role 删除 auth user，因此属于高权限、不可逆服务。
- 只有在发布者明确授权后部署，且必须保持 JWT 验证；部署前后均要用专用测试账号验收，不能使用真实用户数据试删。
- Edge Function 已实现 Apple 授权码交换、账号一致性校验和 token revocation；部署前需设置 `APPLE_TEAM_ID`、`APPLE_CLIENT_ID`、`APPLE_KEY_ID`、`APPLE_PRIVATE_KEY` 四个 Secrets。私钥不得提交仓库或写入客户端。

## 4. Archive

完成以上配置后，在 Xcode 使用 Release + Any iOS Device (arm64) 执行 Archive，先 Validate App，再上传 TestFlight。不要从 Debug 或模拟器产物提交。
