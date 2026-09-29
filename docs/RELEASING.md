# Release signing and notarization

Local development does not require a paid certificate; `scripts/build-app.sh` applies an ad-hoc signature. Public distribution should use a Developer ID Application identity and Apple's notary service.

Recommended release flow:

1. Run `./scripts/test.sh` and `./scripts/build-app.sh` on the minimum supported macOS SDK where practical.
2. Re-sign the app with hardened runtime and a Developer ID Application certificate.
3. Archive the app as a ZIP with `ditto`.
4. Submit the ZIP using `xcrun notarytool submit --wait` with credentials stored in Keychain, never in the repository.
5. Staple with `xcrun stapler staple`, then validate with `spctl --assess --type execute` and `codesign --verify --deep --strict`.
6. Test on a clean macOS 14+ account, including login-item consent and Gatekeeper launch.

Do not publish credentials, signing identities, notary profiles, provisioning material, complete App Server output, or account data. QuotaPet 0.1 has no automatic update mechanism and is not prepared for App Store distribution.
