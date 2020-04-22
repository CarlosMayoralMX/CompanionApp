package com.kumulos.companion;

import com.kumulos.android.InAppDeepLinkHandlerInterface;
import org.json.JSONObject;
import android.content.Context;

public class InAppDeepLinkHandlerImpl implements InAppDeepLinkHandlerInterface {

    public void handle(Context context, JSONObject data){
        if (MainActivity.sInAppChannel != null){
            MainActivity.sInAppChannel.invokeMethod("inAppReceived", null);
        }
    }
}
