# Mac QuickLook Modern

统一的 macOS Finder 文件预览扩展项目。目标系统 **macOS 13–27**，一个宿主 App 内置一个 Preview Extension 和一个 Thumbnail Extension；不再分发多个旧式 `.qlgenerator` 或 `.pkg`。

This is a clean-room implementation inspired by the [Mac-QuickLook catalog](https://github.com/haokaiyang/Mac-QuickLook), not a binary conversion of the original plugin collection.

## 当前状态 / Status

- 已实现 12 类文件解析器；核心 Swift 代码可使用 SwiftPM 在 Linux 上测试。
- 已提供 XcodeGen macOS App 工程配置、两种 Quick Look 扩展、统一安装界面、CI、构建后完整性校验、打包/发布脚本。
- v0.5.0：恢复完整解析模块，31 项 Swift 核心单元测试、Swift 源文件语法解析和本地元数据一致性检查；CI 增加 macOS 构建后 `.app/Contents/PlugIns` 校验。
- 最新代码需以 GitHub Actions 实际运行结果为准。**Finder 实际调用、macOS 13 验收、Developer ID 签名与 Apple 公证仍未完成。**
- 87 个原始二进制目录/安装包仅作为迁移登记，**并未全部重新实现**。见 `Docs/LEGACY_INVENTORY.csv`。

## 支持的文件类型

| 类别 | 后缀 | 当前实际实现 |
| --- | --- | --- |
| 调色 | `.cube` | 完整 LUT 网格校验、混合 1D/3D LUT、对角线颜色采样与文本预览；不渲染 LUT 效果 |
| 色板 | `.ase` | Adobe Swatch Exchange 名称、颜色模型、RGB 色块；非 RGB 只显示模型 |
| 定位 | `.gpx` | 轨迹、航点、路线统计、离线路径轮廓（保留轨迹分段）、源文本；不联网加载地图瓦片 |
| 字幕 | `.srt`, `.vtt`, `.ass`, `.ssa` | 事件/样式数、内容文本 |
| 剪辑 | `.edl`, `.otio`, `.fcpxml` | 事件、轨道、片段等结构统计，源文本 |
| 下载 | `.torrent` | 文件数、总字节数、Tracker 等静态元数据；不发起网络请求 |
| 制造 | `.gcode` | 运动、挤出、工具和标注层数量、源文本 |

上述清单代表解析器能够理解这些文件，不代表所有系统都已验证 Finder 会自动调度本扩展。对于已有其他应用注册的同一文件类型，系统可能使用其他预览提供者。

## Architecture

```text
MacQuickLookModern.app
├── Main App                    SwiftUI · 导入文件自检 · 格式列表
├── PlugIns/QuickLookPreview.appex
│   └── QLPreviewProvider      HTML 数据预览
└── PlugIns/QuickLookThumbnail.appex
    └── QLThumbnailProvider    Finder 缩略图
Shared/
├── FileSummary.swift          格式路由与大小限制
├── PreviewHTML.swift          受限制的 HTML 输出
└── Decoders/                格式解析与防护
```

无需单独安装任何解码插件。格式处理器是同一工程内的代码模块，不在运行时下载任意第三方组件。

## 本地构建

需要 macOS、Xcode 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```sh
brew install xcodegen
python3 Scripts/audit.py
xcodegen generate --spec project.yml
xcodebuild -project MacQuickLookModern.xcodeproj -scheme MacQuickLookModern -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project MacQuickLookModern.xcodeproj -scheme MacQuickLookModern -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
python3 Scripts/verify-built-bundle.py ~/Library/Developer/Xcode/DerivedData/MacQuickLookModern-*/Build/Products/Debug/MacQuickLookModern.app
```

Unsigned build 只能用于开发验证，不能作为已签名安装包直接分发。真实 Finder 测试、签名、公证参考 `Docs/ACCEPTANCE.md` 与 `Docs/RELEASE.md`。

解析模块也可单独测试（可在 Linux 运行）：

```sh
swift test
```

## 原生编译后的校验

`Scripts/verify-built-bundle.py` 读取最终生成的 App bundle，确认 12 种内容类型、两个嵌入的 `.appex` 和可执行文件均在正确路径。此脚本属于构建产物结构检查，**不代表 Finder 已成功加载扩展**。CI 的原生编译须在创建 GitHub 分支后才能运行。

## 安装与卸载

安装单个**已签名并完成 Apple Notarization 的** `.app` 到 `/Applications`，启动一次，使用 Finder 的空格键预览对应文件。若系统将这些后缀绑定到其他内容类型，需要检查 UTI 映射与 Quick Look 扩展优先级；本项目不会强制覆盖其他应用。

卸载只需移除本 App。无需向 `~/Library/QuickLook` 手动复制或移除单独的旧式插件。不包含联网更新、管理守护进程或内核修改。

## CI / 发布

`.github/workflows/build.yml` 为 Intel/macOS 15、Apple Silicon/macOS 26 和 Apple Silicon/macOS 27 (Xcode 27) 配置编译与测试工作流。macOS 13/14 的 Finder 验收依赖实机或自行管理的测试环境。

`Scripts/package-release.sh` 会对**已经完成 Developer ID 签名**的 App 执行校验、公证、DMG 打包和公证。需要开发者自己的 Apple 证书及 notarytool 凭据。没有认证材料时不可生成合格安装包。

## 迁移和许可

本项目不包含旧仓库的第三方插件二进制。原目录、许可核查和兼容状态登记在 `Docs/`。原仓库主许可证为 CC0，但这不授予重新分发其所收集的所有第三方插件的权利。原项目及贡献者按对应来源保留署名和许可。

## Limitations

文件大小限制 8 MiB，超出立即拒绝；解析器不执行代码、不加载网络资源、不解析 XML DTD/外部实体，不运行插件二进制。UTF-8 文本和带 BOM 的 UTF-16 文本受支持，其他历史字符编码未实现。ASE 色板的非 RGB 颜色只报告模型，避免不可靠的色彩转换。复杂视频解码、3D 实时渲染及所有旧插件的全量移植**未包含在当前版本**。
