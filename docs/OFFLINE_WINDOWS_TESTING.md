# Offline Windows Testing Notes

The font display test uses Windows system fonts only. It does not load fonts
from the network and does not require bundled font assets.

## Font Assumptions

- Chinese default: `Microsoft YaHei`
- Western options: `Arial`, `Tahoma`, `Consolas`, `Segoe UI`, `Verdana`
- These font families are available on normal Windows desktop installations.

## Before Moving To An Offline Windows Machine

If the app will only be run as a built executable, build the Windows package on
a connected or prepared machine first, then copy the generated build output.

If the app must be built on the offline Windows machine, prepare these items in
advance:

- Flutter SDK matching the project metadata.
- Visual Studio Build Tools with C++ desktop workload.
- CMake and Ninja from the Visual Studio workload or Flutter requirements.
- A populated Dart pub cache for all packages in `pubspec.lock`.
- Windows platform files generated before the move, or a Flutter SDK available
  offline so `flutter create --platforms=windows .` can generate them.

Run these checks on the prepared Windows machine before disconnecting it:

```powershell
flutter doctor -v
flutter pub get --offline
flutter build windows
```

After the machine is offline, use `flutter pub get --offline` instead of the
normal online package resolution path.

## Build Package

Use the project script to create a release executable package:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1 -Offline
```

The script creates:

- `dist\vibe_im_windows_release\feishu_im.exe`
- `dist\vibe_im_windows_release.zip`

Copy the full `dist\vibe_im_windows_release` directory when testing, because
Flutter desktop apps require the adjacent DLL and data files next to the `.exe`.
