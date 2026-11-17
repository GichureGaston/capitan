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
| FOSS licence in the repository | Apache-2.0, see `LICENSE` |
| Unique application ID | `io.github.gichuregaston.capitan` |
| FOSS-only dependencies | Vendored GMS-free `geolocator_android` in `packages/`; location uses `LocationManager` (`com.google.android.gms` is also excluded as a guard) |
| Release build unsigned by default | Yes, unless `android/key.properties` exists |
| Release tags | Add `v1.0.0` and one for every later release |
| Fastlane metadata | `fastlane/metadata/android/en-US/` |
| Flutter version pin | 3.47.7 in the fdroiddata recipe |
| App icon | Generated from `branding/app_icon_source.jpg` with `tools/generate_icons.py` |
| Android launcher icon | Replaced with the project icon; adaptive icon included for Android 8+ |

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
flutter build apk --release
```

Without `android/key.properties` the APK is unsigned, which is what F-Droid
expects. To ship your own signed APK as well, copy
`android/key.properties.example` to `android/key.properties`, point it at your
keystore, and rebuild.

Check that the proprietary location provider is really gone:

```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk 'classes*.dex' \
  | strings | grep -c 'com/google/android/gms'   # should print 0
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

## 3. Submit the build recipe

Fork <https://gitlab.com/fdroid/fdroiddata>, create a branch named after the
application ID, copy
[`docs/fdroid/io.github.gichuregaston.capitan.yml`](fdroid/io.github.gichuregaston.capitan.yml)
to `metadata/io.github.gichuregaston.capitan.yml`, and open a merge request
titled `New App: io.github.gichuregaston.capitan`.

The recipe is already pinned to the `v1.0.0` commit
(`027da4a17aa185b3a8c4b642f797166c81a141b0`). For a later release, update it
with:

```bash
git rev-parse v1.0.1
```

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

## Notes for reviewers

- The app needs network access for weather, marine, tide, geocoding, and
  nearby-spot data (Open-Meteo, Nominatim, Overpass). The fish and coral guides
  are bundled and work offline.
- Location is optional, foreground-only, and used to fetch local conditions and
  nearby spots. There is no background location.
- There is no advertising, analytics, crash reporting, or account system.
- Species photos are public domain, CC0, CC BY, or CC BY-SA; attribution is
  stored with each species and shown in the detail screen.
