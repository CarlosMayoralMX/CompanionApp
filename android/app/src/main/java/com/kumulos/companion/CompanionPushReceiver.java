package com.kumulos.companion;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.app.TaskStackBuilder;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;
import com.kumulos.android.PushMessage;
import java.util.HashMap;
import java.util.Map;

public class CompanionPushReceiver extends BroadcastReceiver {

    public static final String ACTION_PUSH_RECEIVED = "com.kumulos.push.RECEIVED";

    @Override
    final public void onReceive(Context context, Intent intent) {
        if (null == intent) {
            return;
        }

        String action = intent.getAction();

        if (null == action) {
            return;
        }

        switch (action) {
            case ACTION_PUSH_RECEIVED:
                this.onPushReceived(context, intent);
                break;
        }
    }

     /**
     * Handles showing a notification in the notification drawer when a content push is received.
     *
     * @param context
     */
    protected void onPushReceived(Context context, Intent intent) {
        PushMessage pushMessage = intent.getParcelableExtra(PushMessage.EXTRAS_KEY);
        
        Map<String,String> map = new HashMap();
        map.put("title", pushMessage.getTitle());
        map.put("message", pushMessage.getMessage());
        
        if (MainActivity.sPushChannel != null){
            MainActivity.sPushChannel.invokeMethod("pushReceived", map);
        }
    }
}