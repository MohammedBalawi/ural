package com.example.installing_package;

import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

public class MyNotificationListenerService extends NotificationListenerService {

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        String packageName = sbn.getPackageName();
        String title = sbn.getNotification().extras.getString("android.title");
        String text = sbn.getNotification().extras.getString("android.text");

        Log.d("NotificationListener", "🔔 إشعار جديد: " + packageName + " - " + title + ": " + text);

        // هنا يمكنك رفع الإشعار إلى Supabase عبر HTTP POST بنفس طريقة الـ NotificationService التي عملناها
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        Log.d("NotificationListener", "🗑️ إشعار تم إزالته: " + sbn.getPackageName());
    }
}
