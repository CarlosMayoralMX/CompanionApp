package com.kumulos.companion;

import android.content.SharedPreferences;

import com.kumulos.android.Kumulos;
import com.kumulos.android.KumulosConfig;
import com.kumulos.android.KumulosInApp;

import io.flutter.app.FlutterApplication;

public class KompanionApp extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();

        SharedPreferences prefs = getSharedPreferences("KUMULOS", MODE_PRIVATE);

        KumulosInApp.setDeepLinkHandler(new InAppDeepLinkHandlerImpl());
        if (prefs.contains("K_API_KEY") && prefs.contains("K_SECRET_KEY")) {
            String apiKey = prefs.getString("K_API_KEY", "");
            String secretKey = prefs.getString("K_SECRET_KEY", "");

            KumulosConfig config = new KumulosConfig.Builder(apiKey, secretKey)
                .enableInAppMessaging(KumulosConfig.InAppConsentStrategy.AUTO_ENROLL)
                .build();
            Kumulos.initialize(this, config);
        }
        else{
            Kumulos.maybeRegisterLifecycleWatcher(this);
        }
    }
}
