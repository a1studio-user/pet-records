# 宠刻 · iOS/iPadOS App 与交互原型

一个面向猫和狗的轻量级生活记录 App，包含用于快速验证交互的网页原型，以及可编译运行的原生 iOS/iPadOS SwiftUI 工程。原生版已连接 Supabase Auth、Postgres 与私有 Storage，用于账号认证、记录同步和照片备份。

当前目录同时包含可编译运行的原生 SwiftUI 工程 `PawprintDiary.xcodeproj`。最低系统为 iOS/iPadOS 17，当前版本号为 `1.0.0 (3)`。

## 已覆盖的原型流程

- 多宠物档案：猫/狗、性别、已绝育/未绝育/未知、品种、生日、自动年龄、头像照片；支持编辑，且品种选择过程中会保留已输入内容
- 生活记录与口味榜页头可直接切换当前宠物，切换后停留在原页面并刷新对应数据
- 驱虫记录：猫用/狗用分区，并可继续按内驱、外驱、内外同驱筛选；下次提醒频次由用户自行填写“月/次”，系统只据此计算日期，不预设或推荐周期
- 疫苗记录：疫苗名称、注射时间、第几针、照片、提醒
- 主粮记录：名称、kg 规格、价格、购买/开始/吃完日期，以及自动食用天数、每日成本、日均消耗
- 口味榜：品牌、产品、可自定义类别、0.5–5 星半星评分、照片；3 星及以上自动进入红榜，3 星以下进入黑榜，并支持列表/大图切换
- 洗澡记录：洗澡日期、价格与备注；支持共享宠物共同维护、编辑和删除
- 所有记录的图片位显示用户拍摄或上传的产品照片，点击缩略图可查看大图；未上传时保留原有类别图标
- 犬种使用产品已确认的 66 项中文名单；猫种使用产品已确认的 69 项中文名单（两者均含“其它”并支持自定义输入）
- 已部署的 Supabase 表结构、所有权约束、逐操作 RLS、必要索引和私有照片策略
- 真实账号与云端备份：原生“通过 Apple 登录”、Keychain 会话恢复、首次登录绑定本机记录、静默自动同步、记录与照片恢复
- 共同饲养：每只宠物拥有唯一八位分享码；主饲养员可管理档案、成员和分享码，共同饲养员可维护记录并可主动退出
- 新安装默认不包含演示宠物或示例记录；测试时可通过一次性启动参数清除残留本地会话，不会删除云端账号数据
- 新增记录时可在表单内直接选择任意宠物；不会切换当前页面宠物，也不会要求退出表单后重新操作
- 底部导航栏“新增”使用原生底部抽屉动画，提供两列记录类型卡片；小屏和辅助大字号下可滚动，选择后进入对应记录表单
- 原生界面按水平尺寸等级自适应：iPad 放大字号、图标、头像、间距与照片卡片，并将有效内容宽度扩展到 1040pt；窄屏、分屏和 iPhone 自动回到紧凑布局
- 页面内容、导航栏和操作按钮遵循系统安全区域，避开灵动岛、刘海和底部 Home Indicator；仅装饰背景延伸到屏幕边缘

## 原生 App 运行

1. 使用 Xcode 26 或兼容版本打开 `PawprintDiary.xcodeproj`。
2. Scheme 选择 `PawprintDiary`，设备选择任意 iPhone 或 iPad 模拟器。
3. 点击 Run。工程不依赖第三方包，首次即可编译。

也可在终端验证模拟器构建：

```bash
xcodebuild -project PawprintDiary.xcodeproj \
  -scheme PawprintDiary \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/PawprintDiaryDerived \
  CODE_SIGNING_ALLOWED=NO build
```

原生版已经实现首页、生活记录、口味红黑榜、宠物档案、新增/编辑、相机/相册、本地 JSON 持久化、用户自定提醒，以及真实 Supabase Apple 认证、共同饲养和云端同步。项目连接信息放在被 Git 忽略的 `PawprintDiary/Config.local.xcconfig`；新环境可复制 `PawprintDiary/Config.xcconfig.example`。严禁把 `service_role` 或 secret key 放入 App。

## 本地预览

在本目录执行：

```bash
python3 -m http.server 4173
```

然后打开 [http://localhost:4173](http://localhost:4173)。网页版本的数据保存在浏览器 `localStorage`，其账号交互仍只用于原型演示；真实认证和云端同步位于原生 SwiftUI App 中。

## 产品边界

本应用仅保存用户主动输入的记录，不根据驱虫药、疫苗、日期、针次或宠物档案输出任何建议、判断和看法，尤其不提供医疗建议。工程已包含相机/相册用途说明、隐私清单、隐私政策草案、App Store 隐私标签填写表和账号删除客户端流程；生产账号删除服务已部署。公开发布前仍须完成 Apple 凭据撤销真机验收、公开托管政策页面并完成法务复核。

## 资料来源

- 猫种参考：[TICA Breed Standards](https://tica.org/resources/our-publications/breed-standards)、[CFA Recognized Breeds](https://cfa.org/breeds/)
- 驱虫药首版参考：中国大陆公开厂商产品页及农业农村部公开兽药注册资料。名称仅用于检索与记录，后续上线前需逐条复核批准文号与在售状态。
- Supabase 安全设计：[Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)、[Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control)

`supabase/schema.sql` 是初始结构基线；`supabase/migrations/` 是当前生产结构的权威增量记录，并已部署到本项目 Supabase。`supabase/ACCOUNT_FLOW.md` 记录实际注册、首次绑定、持续同步与重装恢复流程。
