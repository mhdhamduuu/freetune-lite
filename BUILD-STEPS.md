# Build & Install FreeTune Lite (no Mac needed)

## 1. Get the IPA (automatic)
The repo has `.github/workflows/build-ipa.yml` — every push to `main` builds
`FreeTuneLite-unsigned.ipa` on a macOS runner with Xcode 16 and uploads it as
the artifact **FreeTuneLite-unsigned-ipa**.

## 2. Sign & install on iPhone (Sideloadly, Windows)
1. Install **Sideloadly** (sideloadly.io) + **Apple Devices** app (Microsoft Store)
2. Connect the iPhone by USB → tap **Trust**
3. Drag `FreeTuneLite-unsigned.ipa` into Sideloadly
4. Enter your Apple ID → **Start**
5. iPhone: Settings → General → **VPN & Device Management** → trust your Apple ID
6. Open **FreeTune Lite** 🎵

## 3. Enable Jamendo downloads (one free step)
1. Register at **dev.jamendo.com** → get your `client_id`
2. FreeTune Lite → **Settings tab** → paste → **Save key**
3. Jamendo songs now appear in search results and every one is legally
   downloadable (⬇ button).

## Manual build (any Mac with Xcode 16)
```
xcodebuild -project FreeTuneLite.xcodeproj -target FreeTuneLite \
  -configuration Release -sdk iphoneos \
  SYMROOT="$(pwd)/build/Products" build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
mkdir -p build/Payload
cp -R build/Products/Release-iphoneos/FreeTuneLite.app build/Payload/
cd build && zip -qry FreeTuneLite-unsigned.ipa Payload
```
