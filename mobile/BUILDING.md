# Building Minibanter for Android and iOS

Run all commands in this document from the `mobile` directory.

```bash
cd mobile
flutter pub get
```

## Build configuration

The app needs an API URL at build time. Use a publicly reachable HTTPS URL for a production build:

```bash
--dart-define=API_BASE_URL=https://api.example.com
```

Do not use `localhost` for a physical device: it refers to the device itself. For local Android-emulator testing, use `http://10.0.2.2:8000` if the FastAPI server runs on the host machine.

## Android

Install Android Studio and the Android SDK, then point Flutter at the SDK if necessary:

```bash
flutter config --android-sdk /path/to/Android/Sdk
flutter doctor --android-licenses
flutter doctor
```

Build a release APK for direct testing:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

The APK is written to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build a Google Play upload bundle:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

The bundle is written to:

```text
build/app/outputs/bundle/release/app-release.aab
```

### Android signing before publication

The repository currently signs release builds with the debug key so local release builds work. Google Play requires a dedicated release keystore and a Gradle signing configuration before an `.aab` can be uploaded. Keep the keystore and its passwords out of version control, for example in a local `android/key.properties` file that is ignored by Git.

Also replace the current placeholder application ID, `com.minibanter.minibanter`, with your organization’s unique Android package name before publishing.

## iOS

iOS builds require macOS with Xcode installed; they cannot be produced from this WSL environment.

Open `ios/Runner.xcworkspace` in Xcode and, under **Runner > Signing & Capabilities**, choose your Apple Developer team and confirm a unique bundle identifier. The current identifier is `com.minibanter.babySubtitles`.

Then build an IPA:

```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

The IPA is written to:

```text
build/ios/ipa/
```

Use Xcode Organizer or Transporter to upload the resulting archive to App Store Connect for TestFlight or App Store distribution.

## Versioning

Update `version` in `pubspec.yaml` for every store build:

```yaml
version: 1.0.1+2
```

The value before `+` is the user-facing version. The number after `+` is the incrementing Android version code and iOS build number.
