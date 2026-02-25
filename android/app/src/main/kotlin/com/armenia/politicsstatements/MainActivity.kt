package com.armenia.politicsstatements

import android.content.Intent
import android.media.MediaScannerConnection
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val SHARE_CHANNEL = "statements/share"
    private val SCAN_FILE_CHANNEL = "statements/scan_file"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            //            val argsMap = call.arguments as HashMap<String, String>
            if (call.method == "share-file") {
                val path = call.argument("filePath") as String?
                val mimeType = call.argument("mimeType") as String?
                val shareWithLink = call.argument("shareWithLink") as Boolean?
                val shareWithText = call.argument("shareWithText") as Boolean?
                if (!path.isNullOrEmpty()) {
                    shareFile(path, mimeType, shareWithLink ?: false, shareWithText ?: false)
                } else {
                    result.error("1", "no file path", "")
                }
            }

        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
                SCAN_FILE_CHANNEL).setMethodCallHandler { call, result ->
            //            val argsMap = call.arguments as HashMap<String, String>
            if (call.method == "scan-file") {
                val path = call.argument("filePath") as String?
                val mimeType = call.argument("mimeType") as String?
                if (!path.isNullOrEmpty()) {
                    MediaScannerConnection.scanFile(context, arrayOf(path), arrayOf(mimeType)) { path, uri -> result.success(""); }
                } else {
                    result.error("1", "no file path", "")
                }
            }

        }
    }

    fun shareFile(filePath: String?, mimeType: String?, shareWithLink: Boolean, shareWithText: Boolean) {
        val share = Intent(Intent.ACTION_SEND)
        share.type = mimeType
        share.putExtra(Intent.EXTRA_STREAM, FileProvider.getUriForFile(this,
                "com.armenia.famousstatements.fileprovider", //(use your app signature + ".provider" )
                File(filePath)))
        if (shareWithLink) {
            share.putExtra(Intent.EXTRA_TEXT,
                    "https://play.google.com/store/apps/details?id=com.armenia.famousstatements");
        } else if (shareWithText) {
            share.putExtra(Intent.EXTRA_TEXT, "Shared from app Bolola");
        }

        startActivity(Intent.createChooser(share, "Share your audio"))
    }
}
