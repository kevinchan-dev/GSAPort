# Repository guidance

These instructions apply throughout this repository. Read `README.md` for the current tested behavior and limitations before making changes.

## Scope and compatibility

- This is an unofficial iOS 8 fork of Epixx512/GSAPort. Preserve upstream attribution and history.
- The verified setup is a jailbroken iPad 4 running iOS 8.4.1 with Cydia Substrate. iCloud sign-in was confirmed with package `2.4.2+ios8.4`; individual services, downloads, and other devices are not automatically verified by that result.
- GSAPort handles iCloud authentication. The separate iTunesStoreX fork handles Store compatibility. Consult the README for the combined test results; do not claim either tweak is independently sufficient for App Store login without testing that configuration.
- Target traditional rootful packaging, `armv7`, and an iOS 8.0 deployment minimum. The Makefile uses the iOS 9.3 SDK. Do not introduce newer runtime APIs, architectures, or rootless paths without an explicit change in scope.

## Source map

- `Tweak.x`: request interception, GrandSlam/SRP authentication, anisette requests, two-factor handling, and response translation.
- `SessionSupport.x`: NSURLSession configuration and factory hooks.
- `RequestBody.h`: materializes streamed HTTP request bodies with a size limit.
- `AccountDiagnostics.x`: account-save error logging.
- `GSAPort.plist`: Substrate process and bundle filters. Changes here affect where the tweak loads.
- `control`: Debian package identity, version, and firmware/Substrate dependencies.
- `layout/DEBIAN/`: install/removal scripts that restart affected daemons.
- `openssl/`: bundled headers and static libraries. Do not replace these binaries incidentally.
- `diagnostics/ipad-probe.m`: device-side diagnostic executable; not part of the installed tweak.
- `polyfill.x`: retained upstream compatibility code, currently excluded from the build.

## Implementation rules

- Use Objective-C and Logos consistently with the existing code. Tweak sources build with ARC.
- Keep interception limited to the intended endpoints and processes. Preserve the `GSAPortHandled` request marker so internal authentication requests cannot recurse through the protocol handler.
- Support both `HTTPBody` and `HTTPBodyStream`. Preserve request methods and headers, bound buffering, and propagate stream failures. Never log the buffered body.
- Keep JSON-to-property-list conversion consistent with downstream request parsing and serialization.
- Preserve existing session protocol classes and settings, avoid duplicate registration, and do not mutate caller-owned configurations. Background NSURLSession configurations cannot use this custom URL protocol; shared-session coverage requires separate verification.
- Two-factor state is held in the originating process. Closing Settings or restarting processes can discard it. A code-only retry is intentional behavior, not evidence that the original password was wrong.
- Do not bypass certificate validation or change authentication/cryptographic behavior to hide a connection failure. Diagnose the failing transport or protocol stage first.

## Build and validation

With Theos, an ARMv7-capable toolchain, the iOS 9.3 SDK, and ldid configured:

```sh
export THEOS=/path/to/theos
make package FINALPACKAGE=1 THEOS_PLATFORM_DEB_COMPRESSION_TYPE=gzip
```

The README records the SDK/linker-stub corrections needed on the original build machine. They are not bundled here. Do not assume a temporary toolchain directory still exists or silently copy machine-specific paths into project configuration.

- For documentation-only changes, review the diff and run `git diff --check`; a package rebuild is unnecessary.
- For code changes, build the affected package and use focused tests for the changed behavior. There is no committed automated test suite; do not claim one passed.
- For request-body changes, check direct and streamed bodies, method/header preservation, malformed input, read failures, and the size limit as applicable.
- A successful build or HTTP 200 does not prove successful authentication or account saving. Distinguish transport results, server authentication status, two-factor validation, and the final device result.
- For packages intended for distribution, check ARMv7 architecture, iOS deployment minimum, expected iOS dependency paths, signing, package version/dependencies, root ownership, executable maintainer scripts, filter plist validity, and gzip archive compatibility. Generate a SHA-256 checksum for the final artifact.
- `.theos/` and `packages/` are ignored generated output. Do not commit build products, SDKs, temporary toolchains, or device logs.

## Device diagnostics

- Use the device connection supplied by the user; do not commit IP addresses, SSH configuration, private keys, or account identifiers.
- Begin with package versions, tweak loading, process state, and existing diagnostics. Keep device changes within the user's authorized scope and explain when an install or restart will close Settings or interrupt a sign-in attempt.
- The probe supports `logs`, `errors`, and `methods`. With no argument it also loads the tweak and makes unauthenticated HTTPS HEAD requests. HTTP 403 from those HEAD probes can demonstrate connectivity; it is not an authentication test.
- Diagnostics may record fixed route names, HTTP status, error domains/codes, and field-presence checks. Never record passwords, verification codes, tokens, authorization headers, device UUIDs, raw account objects, or request/response bodies.
- Have the user enter credentials and codes on their device. Do not ask them to paste secrets into chat or command lines.
- Sign device helpers with ldid. If iOS terminates an overwritten helper because of cached signing state, use a fresh executable filename rather than disabling signature checks.
- Do not remove accounts, reset account databases, or clear credentials as a routine troubleshooting step.

## Commits and publication

- Check `git status` before editing and preserve unrelated work. Keep source, package metadata, and documentation consistent; do not bump the package version for documentation-only edits.
- Commit locally when requested. A request to commit does not authorize pushing, publishing releases, or uploading artifacts. Wait for the user's explicit publication instruction, including completion of any requested review.
- `origin` is the user's fork; `upstream` is Epixx512/GSAPort. Do not push to upstream or rewrite published history as part of routine work.
- When publication is authorized, build from the intended committed source, describe the actual tested scope, retain upstream credit, and upload only the intended package and checksum. Label unverified compatibility work as experimental.
- Report the commit, validation performed, remaining limitations, and whether changes were pushed. Never describe a partial diagnostic result as a confirmed fix.
