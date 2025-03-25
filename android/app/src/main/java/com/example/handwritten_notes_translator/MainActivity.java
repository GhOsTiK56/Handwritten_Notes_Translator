package com.example.handwritten_notes_translator;

import android.content.ContentValues;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.handwritten_notes_translator/gallery";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("saveToGallery")) {
                                String tempPath = call.argument("path");
                                String fileName = call.argument("fileName");
                                String savedPath = saveToGallery(tempPath, fileName);
                                if (savedPath != null) {
                                    result.success(savedPath);
                                } else {
                                    result.error("SAVE_ERROR", "Failed to save to gallery", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private String saveToGallery(String tempPath, String fileName) {
        try {
            // Сохраняем файл локально в директории приложения
            File localDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES);
            File localFile = new File(localDir, fileName);
            try (FileInputStream fis = new FileInputStream(tempPath);
                 FileOutputStream fos = new FileOutputStream(localFile)) {
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = fis.read(buffer)) != -1) {
                    fos.write(buffer, 0, bytesRead);
                }
                fos.flush();
            }

            // Записываем файл в MediaStore для отображения в галерее
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
            values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_DCIM + "/HandwrittenNotes");
            values.put(MediaStore.Images.Media.IS_PENDING, 1);

            Uri uri = getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri != null) {
                try (OutputStream out = getContentResolver().openOutputStream(uri)) {
                    try (FileInputStream fis = new FileInputStream(localFile)) {
                        byte[] buffer = new byte[1024];
                        int bytesRead;
                        while ((bytesRead = fis.read(buffer)) != -1) {
                            out.write(buffer, 0, bytesRead);
                        }
                    }
                    out.flush();
                }
                values.clear();
                values.put(MediaStore.Images.Media.IS_PENDING, 0);
                getContentResolver().update(uri, values, null, null);
            }

            // Возвращаем локальный путь для отображения в приложении
            return localFile.getAbsolutePath();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}