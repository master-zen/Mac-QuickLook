# Legacy migration register

Source catalog: https://github.com/haokaiyang/Mac-QuickLook

## Origin and rights

原仓库创建于 2018 年，包含 76 个旧式 `.qlgenerator` 插件目录和 11 个 `.pkg` 安装包，以及外链格式目录。它不是一套统一源代码。原仓库的 CC0 不能替代其中每个第三方程序的单独授权。

新的项目**没有复制任何旧第三方插件二进制**。每项格式支持由新的本地解析模块实现，后续要集成其他库，需要逐一核实许可证、版本、ABI、安全与维护状况。

## Legacy capability groups

| 原功能类别 | 新方案 | 迁移状态 |
| --- | --- | --- |
| SRT/SSA/ASS 字幕与基础文本 | Swift Subtitle 解析 | 重新实现基本预览，不包括全部旧插件行为 |
| 旧 QLTorrent 安装包 | Bencode 静态元数据解析 | 已实现核心文件元数据，不包括旧 GUI |
| QuickLookASE | ASE 色板解析 | 已实现 RGB 色块与模型元数据 |
| Electron/HTML 文档预览与代码语法高亮 | 保留系统或现有成熟扩展 | 不在首批重复开发 |
| 3D 模型预览 | 如有明确需求另做 ModelIO/SceneKit/RealityKit 评估 | 未实现 |
| 视频预览与解码 | 单独研究系统 Media Extension、授权编解码器 | 未实现 |
| 电子书、压缩文件、证书、旧 Office 等 | 按独立许可和现代使用频率复核 | 未实现 |
| GPS / LUT / OTIO / FCPXML / EDL / GCode | 现代专用解析器 | GPS 可输出离线路径轮廓，LUT 可输出采样色块，其余仍主要是元数据与文本，不包括完整渲染 |

## Preservation policy

完整 87 项源目录见 `LEGACY_INVENTORY.csv`，其中状态 `not-reviewed` 表示未独立审计其源代码、编译兼容性和许可证，`not-imported` 表示没有迁移相应旧插件。它不是“87 个插件已完成现代化”的证明。对于尚无现代替代方案的格式，需要单独建立样本、解析规范、故障样本和自动化测试。

## Architecture mapping

- 安装：一个已签名的 `.app`，自动内嵌两个 `.appex`。不会将几十个旧插件复制到 QuickLook 文件夹。
- 内容类型：宿主 App 声明导入 UTTypes，Preview/Thumbnail 扩展声明对应 `QLSupportedContentTypes`。
- 格式解析：受限文件大小、无网络、无代码执行、数据专用解析器。
- 安全：不运行旧打包程序，不要求关闭 Gatekeeper 或 SIP。
- 验证：跨平台单元测试只验证解析模块；macOS/Xcode 和 Finder 的结果必须独立记录。
