package com.kumulos.companion;

import com.google.firebase.messaging.RemoteMessage;
import com.kumulos.android.Kumulos;
import com.kumulos.android.FirebaseMessageHandler;
import android.content.SharedPreferences;

public class FirebaseMessagingService extends com.google.firebase.messaging.FirebaseMessagingService {

    private static final String TAG = FirebaseMessagingService.class.getName();

    @Override
    public void onNewToken(String token) {
        SharedPreferences prefs = getSharedPreferences("KUMULOS", MODE_PRIVATE);

        boolean sdkInitialized = prefs.contains("K_API_KEY");
        if (sdkInitialized){
            Kumulos.pushTokenStore(this, token);
        }
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        FirebaseMessageHandler.onMessageReceived(this, remoteMessage);
    }
}
