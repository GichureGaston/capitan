# Releasing Capitán on F-Droid

F-Droid builds Android apps from source on its own build servers. You do not
upload an APK. Two things have to be in place:

1. the repository is FOSS-compliant and carries its own store metadata
   (this repository), and
2. a build recipe is merged into [`fdroiddata`](https://gitlab.com/fdroid/fdroiddata).

This document is the checklist for both.

## Repository status

| Requirement | Status |
| --- | --- |
| 3 months of active development (inclusion policy) | Not yet: first commit 2026-11-11, earliest eligibility 2027-02-11; see below |
| FOSS licence in the repository | Apache-2.0, see `LICENSE` |
| Unique application ID | `io.github.gichuregaston.capitan` |
| FOSS-only dependencies | Vendored GMS-free `geolocator_android` in `packages/`; location uses `LocationManager` (`com.google.android.gms` is also excluded as a guard) |
| Release build unsigned by default | Yes, unless `android/key.properties` exists |
| APK layout | One APK per ABI (arm32, arm64, x86_64); ~31–37 MB each instead of a 69 MB universal APK |
| Release tags | Add `v1.0.0` and one for every later release |
| Fastlane metadata | `fastlane/metadata/android/en-US/` |
| Flutter version pin | 3.47.7 in the fdroiddata recipe |
| App icon | Generated from `branding/app_icon_source.jpg` with `tools/generate_icons.py` |
| Android launcher icon | Replaced with the project icon; adaptive icon included for Android 8+ |

## Policy gate: 3 months of active development

The first merge request ([!57817](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/57817))
was closed on 2026-11-17 for one reason only: the [inclusion
policy](https://f-droid.org/en/docs/Inclusion_Policy/) requires an app to have
been actively developed for at least three months before it can enter the main
repository. The build recipe, lint, source scan and `fdroid build` all passed;
there is nothing left to fix in the recipe itself.

The policy allows an exception when the app has proven users, the author
already maintains other apps on F-Droid, or the app was made for an event.
Capitán currently has none of those, so the only reliable route is to wait and
keep developing. The repository's first commit is 2026-11-11, so the earliest
realistic resubmission date is **2027-02-11**.

Until then:

- keep making real, user-visible improvements rather than empty commits;
- ship them as tagged releases (`v1.0.1`, `v1.0.2`, ...) with a matching
  `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt` and a GitHub
  release, so the maintenance history is easy for a reviewer to verify;
- collect real user feedback and evidence of use (reports, downloads, stars,
  contributors) — that can later support the "proven users" exception;
- re-run the checks in section 2 before every tag.

When resubmitting, start from the current recipe in this repository, update the
pinned `commit`, `versionName`, all three build `versionCode` values,
`CurrentVersion` and `CurrentVersionCode` to the newest tagged release, and say in the MR description
that the app has now been actively developed since 2026-11-11. Link to the
release history as proof. The previous MR can be reopened if the fork's
`capitan` branch is still available; otherwise open a fresh one.

For immediate distribution without waiting, publish a personal F-Droid repo
instead. That is explicitly allowed by the policy, but users must add it
manually, and its APKs will not be update-compatible with a later main-repo
build unless reproducible builds are configured.

## 1. Bump and tag a release

```bash
# pubspec.yaml
version: 1.0.0+1

git add -A
git commit -m "Release 1.0.0"
git tag v1.0.0
git push origin main --tags
```

Every release needs:

- a new `version:` in `pubspec.yaml` (`1.0.1+2`, ...),
- a matching `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`
  (`2.txt`, `3.txt`, ...),
- a tag (`v1.0.1`, ...).

## 2. Build and check locally

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```

That produces three APKs in `build/app/outputs/flutter-apk/`:
`app-armeabi-v7a-release.apk` (~31 MB), `app-arm64-v8a-release.apk` (~35 MB)
and `app-x86_64-release.apk` (~37 MB). A single universal APK would be ~69 MB.
The F-Droid recipe builds each ABI separately with
`--target-platform="android-arm"`, `"android-arm64"` or `"android-x64"`.

Without `android/key.properties` the APKs are unsigned, which is what F-Droid
expects. To ship your own signed APKs as well, copy
`android/key.properties.example` to `android/key.properties`, point it at your
keystore, and rebuild.

Check that the proprietary location provider is really gone in every APK:

```bash
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  echo "$apk: $(unzip -p "$apk" 'classes*.dex' | strings \
    | grep -c 'com/google/android/gms') GMS references"   # each should print 0
done
```

### Vendored location plugin

Upstream `geolocator_android` depends on
`com.google.android.gms:play-services-location`. Capitán overrides it with a
local copy in `packages/geolocator_android` (MIT, upstream `LICENSE` kept) that
uses only Android's `LocationManager`. The override is declared in
`pubspec.yaml`, and the copy must be included in the source repository/tag that
F-Droid builds. Re-run the GMS check above after upgrading `geolocator`.

F-Droid signs its own build with its own key. An APK you publish yourself will
therefore not be update-compatible with the F-Droid build unless you set up
reproducible builds (`Binaries:` plus `AllowedAPKSigningKeys:` in the
fdroiddata recipe). Decide before the first users install.

### Self-signed APKs on GitHub releases

GitHub release assets are not used by F-Droid, but attaching them gives users a
direct install during the maintenance period. Build from the release tag with
the same Flutter version as the recipe (`3.47.7` for `v1.0.0`), produce the
three split APKs, and sign each one with a keystore you control:

- keystore: `android/capitan-release.jks` (gitignored), alias `capitan`
- credentials: gitignored `android/key.properties`
- certificate SHA-256:
  `866a83da9b9c0caf1da1ed45085c8d93b05e2c9134b377d528fb99823e9c350e`

Back up the keystore and its passwords: losing them means you can never sign an
update with the same identity. Say in the release notes that these APKs are not
update-compatible with the later F-Droid build, which uses F-Droid's key, and
tell users which ABI to install (almost all phones use `arm64-v8a`; the older
`armeabi-v7a` is a fallback and `x86_64` is for Intel devices/emulators).

Flutter numbers the split APKs `abi_code * 1000 + pubspec version code`
(arm32=1, arm64=2, x86_64=4). For `1.0.0+1` the APK version codes are
1001/2001/4001, so the recipe uses `VercodeOperation: 1000 + %c`,
`2000 + %c`, `4000 + %c` and `CurrentVersionCode: 4001`.

## 3. Submit the build recipe

Only do this once the policy gate above is satisfied. Fork
<https://gitlab.com/fdroid/fdroiddata>, create a branch named after the
application ID, copy
[`docs/fdroid/io.github.gichuregaston.capitan.yml`](fdroid/io.github.gichuregaston.capitan.yml)
to `metadata/io.github.gichuregaston.capitan.yml`, and open a merge request
titled `New App: io.github.gichuregaston.capitan`.

The recipe is already pinned to the `v1.0.0` commit
(`027da4a17aa185b3a8c4b642f797166c81a141b0`) with one build block per ABI. For
a later release, update **all three** build blocks with:

```bash
git rev-parse v1.0.1
```

Keep the `VercodeOperation` list in sync with the ABI version codes above;
`fdroid checkupdates` uses it to create the three new build blocks.

Test the recipe with F-Droid's buildserver:

```bash
git clone --depth=1 https://gitlab.com/fdroid/fdroidserver ~/fdroidserver
sudo docker run --rm -itu vagrant --entrypoint /bin/bash \
  -v ~/fdroiddata:/build:z \
  -v ~/fdroidserver:/home/vagrant/fdroidserver:Z \
  registry.gitlab.com/fdroid/fdroidserver:buildserver

# inside the container
. /etc/profile
export PATH="$fdroidserver:$PATH" PYTHONPATH="$fdroidserver"
export JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 >/dev/null \
  | grep 'java.home' | awk -F'=' '{print $2}' | tr -d ' ')
cd /build
fdroid readmeta
fdroid rewritemeta io.github.gichuregaston.capitan
fdroid lint io.github.gichuregaston.capitan
fdroid build io.github.gichuregaston.capitan
```

The merge request's GitLab CI runs the same checks. After the recipe is
merged, a build usually appears in the main repository within 24–48 hours.

## 4. Future releases

With `UpdateCheckMode: Tags` and `AutoUpdateMode: Version` in the recipe, you
only need to push a new version tag. F-Droid adds the build block itself. Keep
the changelog file in the tag so the listing shows what changed.

Before each tag, check that the recipe and the release metadata still agree:

```bash
python3 tools/check_fdroid_release.py --strict
```

After pushing the tag, run it again without `--strict` to confirm the recipe in
this repository still matches the tagged release. When it reports a mismatch,
update `docs/fdroid/io.github.gichuregaston.capitan.yml` (commit, version name,
all three build version codes, `CurrentVersion`, `CurrentVersionCode`) in the
same release commit. The checker also verifies each build's output path and
`--target-platform` so the three ABI blocks cannot silently drift apart.

## Notes for reviewers

- The app needs network access for weather, marine, tide, geocoding, and
  nearby-spot data (Open-Meteo, Nominatim, Overpass). The fish and coral guides
  are bundled and work offline.
- Location is optional, foreground-only, and used to fetch local conditions and
  nearby spots. There is no background location.
- There is no advertising, analytics, crash reporting, or account system.
- Species photos are public domain, CC0, CC BY, or CC BY-SA; attribution is
  stored with each species and shown in the detail screen.
