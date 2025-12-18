package com.apkmounter.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.apkmounter.app/apk_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPackageName") {
                val apkPath = call.argument<String>("apkPath")
                if (apkPath != null) {
                    val packageName = getPackageNameFromApk(apkPath)
                    if (packageName != null) {
                        result.success(packageName)
                    } else {
                        result.error("INVALID_APK", "Could not read package name from APK", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "APK path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getPackageNameFromApk(apkPath: String): String? {
        return try {
            val packageInfo = packageManager.getPackageArchiveInfo(apkPath, 0)
            packageInfo?.packageName
        } catch (e: Exception) {
            null
        }
    }
}
