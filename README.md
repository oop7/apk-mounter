<div align="center">

# APK Mounter

**A root utility to bind-mount custom APKs over installed apps, preserving data and signatures.**

![GitHub release (latest by date)](https://img.shields.io/github/v/release/oop7/apk-mounter?style=for-the-badge&color=blue)
[![License](https://img.shields.io/github/license/oop7/apk-mounter?style=for-the-badge&color=green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com/)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)

</div>


## About

**APK Mounter** is a specialized utility for rooted Android devices. It allows you to "mount" a custom APK file (like a ReVanced patched application) over an existing installed app without uninstalling the original. This preserves your data and login sessions while letting you use the modified version.

It leverages Linux bind mount technology via root access (Magisk, KernelSU, or APatch) to overlay your file on top of the system path.

## Key Features

*   **Root Detection**: Fully compatible with Magisk, KernelSU, and APatch.
*   **Signature Bypass**: Mount self-signed or differently signed APKs without conflicts.
*   **Seamless Mounting**: Overlay any APK instantly without data loss.
*   **Auto-Detection**: Smartly identifies the package name from your selected APK.
*   **Persistent**: Mounts survive reboots automatically (via `service.d`).
*   **Material You**: Beautiful UI that adapts to your system colors (Android 12+).
*   **Theme Support**: Native Dark and Light mode support.

## Getting Started

### Prerequisites
*   **Rooted Device**: You must have Magisk, KernelSU, or APatch installed.
*   **Android 6.0+**: Supports Marshmallow and newer versions.

### Installation
1.  Download the latest APK from the [**Releases Page**](https://github.com/oop7/apk-mounter/releases).
2.  Install `apk-mounter-universal-vX.X.X.apk` on your device.
3.  Open the app and grant **Root Access** when prompted.

## How to Use

1.  **Prepare your APK**: Have your custom/patched APK ready on your device storage.
2.  **Select**: Open APK Mounter and tap the **Floating Action Button (+)**.
3.  **Choose File**: Pick your custom APK file.
4.  **Confirm**: The app will detect the target package name (e.g., `com.google.android.youtube`). Verify it matches the app you want to replace.
5.  **Mount**: Tap the **Mount** button.
    *   *The app will apply the mount script immediately.*
6.  **Enjoy**: Open the target app from your launcher. It is now your custom version!

### Managing Mounts
*   **List**: The home screen shows all active mounts.
*   **Unmount**: Tap the **Delete (Trash)** icon to remove a mount and restore the original app.
*   **Remount**: Tap the **Refresh** icon to re-apply the mount if it stops working.

## Credits

*   Implementation and mounting logic derived from [ReVanced Manager](https://github.com/ReVanced/revanced-manager), licensed under [GPL v3.0](https://github.com/ReVanced/revanced-manager/blob/main/LICENSE).
*   Built with [Flutter](https://flutter.dev).

## License

This project is licensed under the **GPLv3 License**. See the [LICENSE](LICENSE) file for details.

---
<div align="center">
  <sub>Built for the Android community</sub>
</div>
