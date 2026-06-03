package com.qadam.foodseller.qadam_food_seller

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var imagePickResult: MethodChannel.Result? = null
    private var pendingCameraFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qadam_food_seller/device"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceIdentity" -> {
                    val deviceToken = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ANDROID_ID
                    ) ?: "unknown-android-device"

                    result.success(
                        mapOf(
                            "device_type" to "Android",
                            "device_token" to deviceToken,
                            "fcm_token" to null
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qadam_food_seller/profile_image"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickProfileImage" -> pickImage("file", result)
                "pickImage" -> {
                    val source = call.argument<String>("source") ?: "file"
                    pickImage(source, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickImage(source: String, result: MethodChannel.Result) {
        if (imagePickResult != null) {
            result.error("picker_active", "Image picker is already open.", null)
            return
        }

        try {
            val requestCode: Int
            val intent = when (source) {
                "camera" -> {
                    requestCode = CAMERA_IMAGE_REQUEST_CODE
                    createCameraIntent()
                }

                "gallery" -> {
                    requestCode = PROFILE_IMAGE_REQUEST_CODE
                    Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                        type = "image/*"
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                }

                else -> {
                    requestCode = PROFILE_IMAGE_REQUEST_CODE
                    Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/*"
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                }
            }

            imagePickResult = result
            startActivityForResult(intent, requestCode)
        } catch (error: Exception) {
            pendingCameraFile = null
            imagePickResult = null
            result.error("picker_failed", error.message, null)
        }
    }

    private fun createCameraIntent(): Intent {
        val file = File(cacheDir, "picked_image_${System.currentTimeMillis()}.jpg")
        pendingCameraFile = file
        val uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )

        return Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != PROFILE_IMAGE_REQUEST_CODE && requestCode != CAMERA_IMAGE_REQUEST_CODE) {
            return
        }

        val result = imagePickResult
        imagePickResult = null

        if (resultCode != Activity.RESULT_OK) {
            pendingCameraFile = null
            result?.success(null)
            return
        }

        if (requestCode == CAMERA_IMAGE_REQUEST_CODE) {
            val file = pendingCameraFile
            pendingCameraFile = null
            try {
                result?.success(file?.takeIf { it.exists() }?.let { compressImageFile(it) })
            } catch (error: Exception) {
                result?.error("compress_failed", error.message, null)
            }
            return
        }

        pendingCameraFile = null
        val uri = data?.data
        if (uri == null) {
            result?.success(null)
            return
        }

        try {
            result?.success(copyPickedImage(uri))
        } catch (error: Exception) {
            result?.error("copy_failed", error.message, null)
        }
    }

    private fun copyPickedImage(uri: Uri): String {
        val bitmap = decodeBitmapFromUri(uri)
        if (bitmap != null) {
            val file = File(cacheDir, "picked_image_${System.currentTimeMillis()}.jpg")
            writeCompressedBitmap(bitmap, file)
            return file.absolutePath
        }

        val fallbackFile = File(cacheDir, "picked_image_${System.currentTimeMillis()}.jpg")
        contentResolver.openInputStream(uri).use { input ->
            if (input == null) error("Unable to open selected image.")
            FileOutputStream(fallbackFile).use { output ->
                input.copyTo(output)
            }
        }
        return fallbackFile.absolutePath
    }

    private fun compressImageFile(sourceFile: File): String {
        val bitmap = decodeBitmapFromFile(sourceFile) ?: return sourceFile.absolutePath
        val compressedFile = File(cacheDir, "picked_image_${System.currentTimeMillis()}.jpg")
        writeCompressedBitmap(bitmap, compressedFile)
        if (compressedFile.exists() && compressedFile.length() > 0L) {
            sourceFile.delete()
            return compressedFile.absolutePath
        }
        return sourceFile.absolutePath
    }

    private fun decodeBitmapFromUri(uri: Uri): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        contentResolver.openInputStream(uri).use { input ->
            if (input == null) return null
            BitmapFactory.decodeStream(input, null, bounds)
        }

        val options = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(bounds)
        }
        return contentResolver.openInputStream(uri).use { input ->
            if (input == null) return null
            BitmapFactory.decodeStream(input, null, options)
        }
    }

    private fun decodeBitmapFromFile(file: File): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)

        val options = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(bounds)
        }
        return BitmapFactory.decodeFile(file.absolutePath, options)
    }

    private fun calculateInSampleSize(options: BitmapFactory.Options): Int {
        var sampleSize = 1
        val height = options.outHeight
        val width = options.outWidth
        if (height <= 0 || width <= 0) return sampleSize

        while (height / sampleSize > MAX_IMAGE_DIMENSION ||
            width / sampleSize > MAX_IMAGE_DIMENSION
        ) {
            sampleSize *= 2
        }
        return sampleSize
    }

    private fun writeCompressedBitmap(bitmap: Bitmap, file: File) {
        val scaledBitmap = scaleBitmap(bitmap)
        FileOutputStream(file).use { output ->
            scaledBitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, output)
        }
        if (scaledBitmap != bitmap) scaledBitmap.recycle()
        bitmap.recycle()
    }

    private fun scaleBitmap(bitmap: Bitmap): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val largestSide = maxOf(width, height)
        if (largestSide <= MAX_IMAGE_DIMENSION) return bitmap

        val scale = MAX_IMAGE_DIMENSION.toFloat() / largestSide.toFloat()
        val targetWidth = (width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (height * scale).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

    companion object {
        private const val PROFILE_IMAGE_REQUEST_CODE = 7192
        private const val CAMERA_IMAGE_REQUEST_CODE = 7193
        private const val MAX_IMAGE_DIMENSION = 1600
        private const val JPEG_QUALITY = 78
    }
}
