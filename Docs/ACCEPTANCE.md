# Finder acceptance checklist

## Build verification

- 在 Intel 和 Apple Silicon 分别执行 XcodeGen 生成、Debug Build 和 XCTest；保存编译日志。
- 通过 `Scripts/verify-built-bundle.py` 检查构建产物中两个 `.appex` 的可执行文件和 UTI 声明。
- 仅通过 SwiftPM Linux 核心测试或构建后结构检查不足以宣布 Finder 预览可运行。
- 在 macOS 13、14、15、26、27 各测试一个受系统支持的设备或虚拟机环境。27 仅 Apple Silicon。

## Installation and extension registration

1. 从 Xcode 使用正确开发团队签名 App 及其两个 `.appex`；将 `.app` 拷入 `/Applications` 并启动。
2. 在终端确认扩展状态：

```sh
pluginkit -m -p com.apple.quicklook.preview
pluginkit -m -p com.apple.quicklook.thumbnail
```

3. 使用 `mdls -name kMDItemContentType Fixtures/example.cube` 检查系统实际匹配的 UTI；不能只依据后缀推定处理器已被选中。
4. 在 Finder 选择各个 Fixtures 文件并按 Space，分别检查完整预览与缩略图。
5. 在 Finder 文件“打开方式”和双击行为中验证本 App **不是**可选打开程序、不会改变默认打开程序；宿主 App 内没有选择/打开文件功能。
6. 如果 Finder 没有调用本扩展，先检查安装、系统扩展设置、UTI 匹配与其他应用冲突，不通过删除系统扩展或关闭 SIP 来“修复”。
7. 安装、卸载、重新安装，确认 Quick Look 注册状态一致且未污染老式 `QuickLook` 目录。

## Non-invasive diagnostics

Run `zsh Scripts/diagnose-finder.zsh Fixtures/example.cube` on a Mac with the signed app installed. It prints both extension registrations and Finder's recognized UTI without changing handlers. A matching UTI is necessary, but **not sufficient**, to establish that Finder selected our extension; verify Space-bar preview and thumbnail directly.

## Security and regressions

- 输入包含 `<script>`、HTML 实体或非常规 Unicode 的文件，不应执行脚本或访问远程资源。
- 超大文件、无效 ASE/Torrent、XML DTD/实体、损坏 UTF-8、畸形 OTIO 必须安全失败。
- 非目标后缀不应触发本扩展。
- 无网络情况下可以正常预览有效输入。
- 其他预览工具与系统原生预览不应被异常覆盖。

## Compatibility records

| macOS | Architecture | Targeted by project | CI configured | Xcode tested | Finder tested |
| --- | --- | --- | --- | --- | --- |
| 13 | Intel / Apple silicon where supported | Yes | No | No | No |
| 14 | Intel / Apple silicon where supported | Yes | No | No | No |
| 15 | Intel / Apple silicon where supported | Yes | macos-15-intel | No | No |
| 26 | Intel / Apple silicon where supported | Yes | macos-26 ARM | No | No |
| 27 | Apple silicon | Yes | xcode-27 ARM | No | No |

This table is not a compatibility certification. Only tests that have actually executed should be marked passed.
