import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section("我们保存的信息") {
                Text("本 App 需要通过 Apple 登录后使用。Apple 提供的账号标识、可能提供的姓名与邮箱，以及你主动录入的宠物档案、记录、提醒设置和所选照片会同步至 Supabase。")
            }

            Section("使用目的") {
                Text("这些信息只用于登录、备份、跨设备恢复和你主动加入的共同饲养同步。本 App 不投放广告，不出售个人信息，不进行跨 App 跟踪。")
            }

            Section("照片与设备权限") {
                Text("只有在你点击“从相册选择”或“拍照”后，系统才会请求对应权限。相册与拍照互为独立选择；App 不会读取未选择的照片。")
            }

            Section("共同饲养") {
                Text("主饲养员可通过八位分享码邀请他人。加入后，共同饲养员能查看并管理该宠物的生活记录，但不能修改宠物档案或再次分享。主饲养员可移除成员，共同饲养员也可自行退出。")
            }

            Section("存储与删除") {
                Text("云端服务当前位于 Supabase 的澳大利亚区域。你可在“账号”中删除账号；删除后，你创建的宠物、记录和云端照片会永久移除，共同饲养的其他宠物不会被删除。")
            }

            Section("产品边界") {
                Text("本 App 仅保存用户主动录入的信息，不提供建议、判断或看法，尤其不提供医疗建议。")
            }

            Section("联系我们") {
                Text("如需提出隐私或数据问题，请使用 App Store 产品页面中的“App 支持”链接联系我们。")
            }
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}
