package com.example.installing_package;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import androidx.annotation.Nullable;

import org.json.JSONObject;

import java.io.IOException;

import okhttp3.*;

public class NotificationService extends Service {

    private final OkHttpClient client = new OkHttpClient();
    private final String SUPABASE_URL = "https://mavkdxueudusgjdphyhn.supabase.co";
    private final String SUPABASE_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdmtkeHVldWR1c2dqZHBoeWhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDU3MDgsImV4cCI6MjA2MDQyMTcwOH0.srw9bbod0BLAwhbQASWQ9IfYcL8oRc4ZszlfzM4l1N4";

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        JSONObject data = new JSONObject();
        try {
            data.put("package_name", "com.example");
            data.put("title", "عنوان إشعار");
            data.put("text", "نص الإشعار");
            data.put("timestamp", System.currentTimeMillis());
        } catch (Exception e) {
            e.printStackTrace();
        }

        sendNotificationToSupabase(data);
        return START_NOT_STICKY;
    }

    private void sendNotificationToSupabase(JSONObject json) {
        RequestBody body = RequestBody.create(json.toString(), MediaType.parse("application/json"));
        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/rest/v1/notifications")
                .addHeader("apikey", SUPABASE_API_KEY)
                .addHeader("Authorization", "Bearer " + SUPABASE_API_KEY)
                .addHeader("Content-Type", "application/json")
                .post(body)
                .build();

        client.newCall(request).enqueue(new Callback() {
            public void onFailure(Call call, IOException e) {
                e.printStackTrace();
            }

            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    System.out.println("✅ تم رفع الإشعار");
                } else {
                    System.out.println("❌ فشل رفع الإشعار: " + response.message());
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
