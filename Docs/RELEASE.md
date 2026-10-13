# Release procedure

预览扩展必须随宿主 App 一起签名。签名及公证属于开发者身份操作，不应在仓库存储密钥或证书。

## Build and sign

1. 在 macOS 上用 XcodeGen 生成 `.xcodeproj`。
2. 在 Xcode 将 App、Preview Extension、Thumbnail Extension 三个 Target 配置为同一 Apple Developer Team；发布签名使用 Developer ID Application，启用 Hardened Runtime。签名前执行 `python3 Scripts/verify-built-bundle.py /path/to/MacQuickLookModern.app`。
3. 使用 Product > Archive 构建，导出 Developer ID 签名的 App。
4. 在本地运行：

```sh
export SIGNED_APP='/absolute/path/to/MacQuickLookModern.app'
export NOTARY_PROFILE='YOUR_NOTARYTOOL_KEYCHAIN_PROFILE'
./Scripts/package-release.sh
```

脚本将校验签名、提交 ZIP 公证、Staple App、制作 DMG、提交并 Staple DMG、校验 Gatekeeper，最后打印 SHA-256。需事先配置 notarytool Keychain profile。任何步骤失败，不能发布成品。

## Distribution

- 仅发布签名且公证完成的 DMG；保留 SHA-256 与发布日志。
- 各个系统版本上的安装和 Finder 实测独立记录。
- 不提供静默安装/替换其他预览插件的脚本。

## Current release gate

当前没有已验证的 macOS Xcode 编译结果，没有可供签名的 App 构建、Apple Developer ID 或公证凭据，因此尚不能合法声称存在可发布 DMG。请勿将源码 ZIP 描述为可直接安装的正式软件。
