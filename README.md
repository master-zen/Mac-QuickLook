# Mac QuickLook Modern

**仅为 Finder Quick Look 提供空格预览与缩略图；不做独立文件打开、播放、编辑或转换。** 目标系统 **macOS 13–27**，一个宿主 App 内置一个 Preview Extension 和一个 Thumbnail Extension；不再分发多个旧式 `.qlgenerator` 或 `.pkg`。

This is a clean-room implementation inspired by the [Mac-QuickLook catalog](https://github.com/haokaiyang/Mac-QuickLook), not a binary conversion of the original plugin collection.

## 当前状态 / Status

- 已实现 12 类文件解析器；核心 Swift 代码可使用 SwiftPM 在 Linux 上测试。
- 已提供 XcodeGen macOS 宿主容器、两种 Quick Look 扩展、CI、构建后完整性校验、打包/发布脚本。宿主不声明文件打开角色，也不提供文件选择或查看器。
- v0.6.0：删除宿主 App 内置文件打开器和全部文档打开关联，只保留 Finder Quick Look 扩展。\n- v0.5.0：恢复完整解析模块，33 项 Swift 核心单元测试、Swift 源文件语法解析和本地元数据一致性检查；CI 增加 macOS 构建后 `.app/Contents/PlugIns` 校验。
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
├── Main App                    SwiftUI · 只作 Quick Look 容器与使用说明
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

安装单个**已签名并完成 Apple Notarization 的** `.app` 到 `/Applications`，启动一次以便发现扩展，使用 Finder 的空格键预览对应文件。**双击文件不会打开本 App；本 App 不出现在“打开方式”候选中，也不修改默认打开程序。**若系统将这些后缀绑定到其他内容类型，需要检查 UTI 映射与 Quick Look 扩展优先级；本项目不会强制覆盖其他应用。

卸载只需移除本 App。无需向 `~/Library/QuickLook` 手动复制或移除单独的旧式插件。不包含联网更新、管理守护进程或内核修改。

## CI / 发布

`.github/workflows/build.yml` 为 Intel/macOS 15、Apple Silicon/macOS 26 和 Apple Silicon/macOS 27 (Xcode 27) 配置编译与测试工作流。macOS 13/14 的 Finder 验收依赖实机或自行管理的测试环境。

`Scripts/package-release.sh` 会对**已经完成 Developer ID 签名**的 App 执行校验、公证、DMG 打包和公证。需要开发者自己的 Apple 证书及 notarytool 凭据。没有认证材料时不可生成合格安装包。

## 迁移和许可

本项目不包含旧仓库的第三方插件二进制。原目录、许可核查和兼容状态登记在 `Docs/`。原仓库主许可证为 CC0，但这不授予重新分发其所收集的所有第三方插件的权利。原项目及贡献者按对应来源保留署名和许可。

## Limitations

文件大小限制 8 MiB，超出立即拒绝；解析器不执行代码、不加载网络资源、不解析 XML DTD/外部实体，不运行插件二进制。UTF-8 文本和带 BOM 的 UTF-16 文本受支持，其他历史字符编码未实现。ASE 色板的非 RGB 颜色只报告模型，避免不可靠的色彩转换。复杂视频解码、3D 实时渲染及所有旧插件的全量移植**未包含在当前版本**。

## 下载的开发版本为什么可能无法预览\n\n当前 GitHub Release 中的 `UNSIGNED-DEV` 是未经 Apple Developer ID 签名、公证的 CI 编译产物，不能承诺像正式 macOS 应用一样注册 Finder Quick Look 扩展。仅下载 ZIP、解压或启动 App 并不等于扩展已经启用。此前将它放在 Releases 供直接安装测试属于发布验收缺陷，后续正式版必须先通过签名、公证、安装和 Finder 调度测试。\n\n系统按 **实际 UTI** 而非单纯后缀选择 Quick Look 扩展。即使自定义 UTI 与两个扩展的 `QLSupportedContentTypes` 一致，如果系统/其他应用把文件映射到不同 UTI，仍可能无法命中。CI 现运行 `Scripts/probe-filetypes.swift`，输出每个文件扩展名在不同 macOS Runner 上解析得到的 UTI。\n\n## Finder 诊断（只读）

安装完成后，可在 macOS 终端执行 `zsh Scripts/diagnose-finder.zsh /path/to/example.cube`，查看系统识别出的 UTI、扩展注册状态、签名以及 Gatekeeper 判定。该脚本不重置 Quick Look 缓存、不更改文件关联，也不打开文件。

## Quick Look-only invariant

- 只有 `.appex` 负责解码和生成预览/缩略图；宿主 App 是最低限度的容器和提示界面。
- `UTImportedTypeDeclarations` 告诉系统如何识别扩展名；使用 `CFBundleDocumentTypes` 仅登记 12 种类型，但所有条目严格设置 `CFBundleTypeRole=None`、`LSHandlerRank=None`，不声明打开/编辑文件能力；Finder 真正调用仍取决于实际 UTI 和扩展签名注册。
- 受 macOS 文件类型系统和提供程序选择策略影响，Finder 是否选用本扩展仍须通过 `mdls` 和 `pluginkit` 实机验证。
