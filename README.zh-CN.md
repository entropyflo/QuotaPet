# QuotaPet

QuotaPet 是一个开源的 macOS 桌面悬浮宠物，用于显示当前 ChatGPT/Codex 账户的五小时剩余额度与重置倒计时。紧凑苹果由 SwiftUI 程序化绘制，全尺寸模式使用随应用打包的十阶段苹果精灵表。

> QuotaPet 是非官方社区项目，与 OpenAI 无隶属、授权、赞助或背书关系。它不依赖、不修改、不复制，也不追踪 ChatGPT 官方宠物。

## 环境要求

- macOS 14 或更高版本
- Swift 6 / Xcode 16 或更高版本
- 实时数据需要本机可用的 `codex` 与已登录的 Codex 账户

优先测试 Apple Silicon，但源码不依赖特定 CPU 架构。

## 构建运行

应用图标母版位于 `Resources/AppIcon-1024.png`。构建脚本使用 Apple 的 `actool`，将 `Resources/Assets.xcassets` 中完整的 macOS 多尺寸图标编译到 App 包内。

```sh
./scripts/test.sh
./scripts/build-app.sh
open build/QuotaPet.app
```

本地构建使用 ad-hoc 签名。应用不显示在 Dock，所有控制都可从菜单栏访问。

可下载构建见 GitHub Releases。首个公开构建使用 ad-hoc 签名且尚未公证，因此 macOS 可能要求从访达右键菜单选择“打开”，并在“隐私与安全性”中确认。

无需真实账户的 UI 预览：

```sh
.build/debug/QuotaPet --preview-state=95
.build/debug/QuotaPet --preview-state=20
.build/debug/QuotaPet --preview-state=0
.build/debug/QuotaPet --preview-state=offline
```

也可设置 `QUOTAPET_PREVIEW` 为上述值；仅传 `--preview` 时默认 95%。追加 `--preview-scale=0.5` 或 `--preview-scale=1` 可检查固定大小档位，且不会修改已保存偏好。

## 数据与隐私

QuotaPet 从 `CODEX_EXECUTABLE`、已知 ChatGPT/Homebrew 路径和 `PATH` 查找 Codex，启动 `codex app-server --listen stdio://`，通过 JSONL 完成初始化，仅调用 `account/rateLimits/read` 并监听额度更新通知。不创建本地网络端口。

QuotaPet **不会**读取 `~/.codex/auth.json`，不会请求 ChatGPT 内部 HTTP 接口，不会读取聊天、Prompt、回答、会话或项目文件，不保存账号、Token、Cookie或完整 App Server 响应，也没有遥测与远程后端。详见 [PRIVACY.md](PRIVACY.md)。

## 使用行为

- 300 分钟窗口识别为五小时额度，10080 分钟窗口识别为周额度，不依赖 primary/secondary 顺序。
- 剩余额度限制在 0–100%；缺少窗口时明确显示暂不可用，不伪造 100%。
- 连接失败保留最后成功数据并标记过期。
- 启动、每 60 秒、服务端额度通知、Mac 唤醒及五小时重置时刷新。
- 透明非激活式面板支持鼠标拖动，并可通过悬停控件或菜单在持久化的 0.5x/1x 两档间切换。它还支持锁定、始终置顶、全部 Spaces/全屏辅助空间和点击穿透；菜单栏始终可关闭点击穿透。
- 0.5x 将额度改为环绕静态 2D 苹果的圆环，百分比和重置时间以与 1x 相同的实际字号直接显示在苹果主体色块上，每 10% 从青苹果逐级变为褐色坏苹果；1x 使用随应用打包的 `apple-quota-10-stage-v2-cartoon.png`，每消耗 10% 切换一个阶段。
- 1x 状态悬停时，macOS 26 及以上通过 `GlassEffectContainer`、命名空间内唯一的 `glassEffectID` 和原生 matched-geometry 玻璃过渡，让五小时额度与周额度玻璃表面平滑变形；更早的受支持系统使用缩放/材质降级效果。
- 适配系统浅色/深色外观和 Reduce Motion。
- 额度卡片与进度条在 macOS 26 及以上使用原生交互式 Liquid Glass；macOS 14–15 使用材质与高光降级效果，并尊重“降低透明度”。

项目结构和设计见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)，卸载见 [docs/UNINSTALL.md](docs/UNINSTALL.md)，发布签名/公证见 [docs/RELEASING.md](docs/RELEASING.md)。

## 第一版范围之外

不跟随官方 ChatGPT 宠物；不支持 Windows/Linux、多账号、Token 历史图表、宠物养成/商店、自定义皮肤、App Store、自动使用额度重置次数或自动更新。

## 许可

MIT，见 [LICENSE](LICENSE)。
