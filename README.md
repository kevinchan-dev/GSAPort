# GSAPort — iOS 8 fork

**Tested and verified: iCloud sign-in on a jailbroken iPad 4 running iOS 8.4.1**, using GSAPort `2.4.2+ios8.4`, including a manually generated trusted-device verification code. This verifies account sign-in; individual iCloud services and other devices or iOS versions have not all been tested.

## Relationship to iTunesStoreX

GSAPort restored iCloud sign-in on the test device **before iTunesStoreX was installed**, so iTunesStoreX was not needed for that successful iCloud login. App Store login still failed with GSAPort alone.

[The iOS 8 iTunesStoreX fork](https://github.com/kevinchan-dev/iTunesStoreX) `3.1+ios8.1` subsequently restored App Store sign-in on the same iPad, with GSAPort still installed. App Store login was confirmed on 7 November 2026 after restarting `itunesstored` so it loaded the Store tweak. App downloads remain unverified.

The projects address different authentication paths: GSAPort handles iCloud authentication, and iTunesStoreX repairs Store URLs and the App Store authentication endpoint. We have not tested App Store login after removing GSAPort, so whether iTunesStoreX needs GSAPort for that login remains unknown. Keep both installed to reproduce the verified setup. The device also had `tlsfix` and CheckmateStore installed; their necessity was not tested independently.

## About this fork

An unofficial fork of [Epixx512/GSAPort](https://github.com/Epixx512/GSAPort), with compatibility changes for iOS 8. Credit for the original tweak and authentication implementation belongs to Pod and the upstream contributors.

This checkout now builds an **experimental iPad 4 / iOS 8 package**. The upstream description below describes the original release. The local changes add `GSAPortProtocol` to default and ephemeral `NSURLSession` configurations and explicit session factory calls, build only `armv7`, and restrict installation to iOS 8.x. iCloud sign-in was confirmed on a jailbroken iPad 4 running iOS 8.4.1 with build `2.4.2+ios8.4`, including a manually generated trusted-device verification code. Individual iCloud services have not all been tested. Background sessions cannot use custom URL protocols, and existing/shared session interception and iOS 8 endpoint differences still require device testing. This project does not intercept App Store sign-in endpoints.

The current build also reads streamed request bodies and accepts JSON credentials in addition to property lists. Its diagnostic logging records HTTP status and numeric authentication errors without logging credentials, verification codes, tokens, or response bodies.

Download `com.podpod123.gsaport_2.4.2+ios8.4_iphoneos-arm.deb` from this fork's [GitHub Releases](../../releases). It is a 32-bit ARM build for a traditional (rootful) iOS 8 jailbreak and requires Cydia Substrate (`mobilesubstrate`). It retains the upstream package identifier and replaces an existing GSAPort installation. Copy it to the iPad, then install with Filza/iFile or run this command as root in the directory containing the file:

```sh
dpkg -i com.podpod123.gsaport_2.4.2+ios8.4_iphoneos-arm.deb
```

Respring after installation. For trusted-device two-factor authentication, enter your password first, then enter only the verification code in the password field when retrying, as required by upstream. SMS verification is unsupported. The original third-party anisette service remains a network dependency. To uninstall, remove GSAPort in Cydia or run `dpkg -r com.podpod123.gsaport`, then respring.

To build, install [Theos](https://theos.dev/docs/installation), a toolchain that supports `armv7`, the iOS 9.3 SDK in `$THEOS/sdks/iPhoneOS9.3.sdk`, and ldid. With a complete iOS toolchain configured, run:

```sh
export THEOS=/path/to/theos
make package FINALPACKAGE=1 THEOS_PLATFORM_DEB_COMPRESSION_TYPE=gzip
```

The tested build used Apple Clang 16, Theos, the Theos iOS 9.3 SDK, the bundled static OpenSSL library, and ldid v2.1.5-procursus7. On the test Mac, the compiler tools were selected with `PREFIX=/Library/Developer/CommandLineTools/usr/bin/`. The SDK needed corrections: removal of simulator architectures from top-level stub headers, a missing liblaunch stub from the Theos 10.3 SDK, standard C memory/string export declarations missing from libsystem_c, and the iOS IOKit install name (without `Versions/A`). The dm.pl packager also needed explicit numeric UID/GID 0 for archive entries. These local SDK/toolchain repairs are not included in this repository, so reproducing the build with that SDK requires the same corrections. No SDK or system library is included in the package. Gzip compression is used for compatibility with older dpkg versions.

The `diagnostics/ipad-probe.m` helper was used to check runtime loading, session registration, HTTPS connectivity, and GSAPort logs on the test device. It does not need an Apple ID password or verification code. The downloadable package contains only the tweak, its process filter, and package installation/removal scripts; it contains no device logs or account data.

---

The original upstream description follows:

A tweak that uses an NSURLProtocol subclass to intercept Apple ID related login requests to run them through Apple's GrandSlam Authentication protocol. Works on iOS 6 and iOS 7, iOS 8 fails because it uses the NSURLSession system instead. This allows old iOS versions to get past Apple ID authentication, as they don't natively have GSA.
AI usage disclosure: GSAPort is partially AI assisted, with Claude Sonnet 5, the default basic model. AI assisted means parts of its code are corrected/generated by AI, while a big chunk of the code is still human written. I do have Obj-C/C++ experience, and I have throughly checked all AI-touched portions of GSAPort. Most of the SRP algorithm comes from https://github.com/cocagne/pysrp, and AI was used to generate the C equivalent of it. This is *NOT* the same as vibecoding!! Vibecoding is the process of copying and pasting the entire thing from an AI with minimal human intervention.
Big source of information: https://gist.github.com/JJTech0130/049716196f5f1751b8944d93e73d3452. Anisette server is https://github.com/Dadoum/anisette-v3-server.
