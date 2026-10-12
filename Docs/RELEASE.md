# Release policy

The single installation unit is `MacQuickLookModern.app`, bundling `QuickLookPreview.appex` and `QuickLookThumbnail.appex`. Do not distribute old `.qlgenerator` files.

CI uploads an unsigned development App artifact. It is not a signed consumer release.

To ship an end-user release, build a release configuration and sign the App and both nested extensions with a Developer ID Application identity, then verify the nested signatures and Hardened Runtime. Configure `notarytool` keychain profile using your own Apple developer credentials. Run:

```sh
SIGNED_APP='/path/to/MacQuickLookModern.app' NOTARY_PROFILE='notary-profile' zsh Scripts/package-release.sh
```

The script verifies and submits for Apple notarization, staples the App, creates and notarizes a DMG. Never commit signing certificates or credentials to this repository. Make a release only after the CI matrix and the real Finder tests in Docs/ACCEPTANCE.md succeed.
