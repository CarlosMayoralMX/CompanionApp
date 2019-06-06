package com.kumulos.companion;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;

import com.kumulos.android.Installation;
import com.kumulos.android.Kumulos;
import com.kumulos.android.KumulosConfig;
import com.kumulos.companion.location.LocationTrackingInitializer;

import org.json.JSONObject;

import java.util.List;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.kumulos.flutter";
    private static final String PUSH_CHANNEL = "com.kumulos.companion.push";
    private static final String LOCATION_CHANNEL = "com.kumulos.companion.location";
    private static final String PAIRING_CHANNEL = "com.kumulos.companion.pairing";

    private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 1;
    private MethodChannel mLocationChannel;
    private LocationTrackingInitializer mLocationTrackingInitializer;

    public static MethodChannel sPushChannel = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        switch (methodCall.method) {
                            case "getInstallId":
                                String id = Installation.id(MainActivity.this);
                                result.success(id);
                                break;
                            case "init":
                                this.initSdk(methodCall, result);
                                break;
                            case "trackEvent":
                                this.trackEvent(methodCall, result);
                                break;
                            default:
                                result.notImplemented();
                                break;
                        }
                    }

                    private void initSdk(MethodCall methodCall, MethodChannel.Result result) {
                        String apiKey;
                        String secretKey;

                        try {
                            @SuppressWarnings("unchecked")
                            List<String> args = (List<String>) methodCall.arguments;
                            apiKey = args.get(0);
                            secretKey = args.get(1);
                            KumulosConfig config = new KumulosConfig.Builder(apiKey, secretKey).build();
                            Kumulos.initialize(getApplication(), config);
                        } catch (Exception e) {
                            result.error(e.getMessage(), null, null);
                            return;
                        }

                        SharedPreferences prefs = getSharedPreferences("KUMULOS", MODE_PRIVATE);
                        SharedPreferences.Editor editor = prefs.edit();

                        editor.putString("K_API_KEY", apiKey);
                        editor.putString("K_SECRET_KEY", secretKey);
                        editor.apply();

                        result.success(null);
                    }

                    @SuppressWarnings("unchecked")
                    private void trackEvent(MethodCall methodCall, MethodChannel.Result result) {
                        String type;
                        Map<String,Object> properties;
                        JSONObject jsonProperties = null;
                        boolean immediateFlush;

                        try {
                            List<Object> args = (List<Object>) methodCall.arguments;

                            type = String.valueOf(args.get(0));
                            properties = (Map<String,Object>) args.get(1);

                            if (properties != null) {
                                jsonProperties = new JSONObject(properties);
                            }

                            immediateFlush = (boolean) args.get(2);
                        } catch (Exception e) {
                            result.error(e.getMessage(), null, null);
                            return;
                        }

                        if (immediateFlush) {
                            Kumulos.trackEventImmediately(MainActivity.this, type, jsonProperties);
                        }
                        else {
                            Kumulos.trackEvent(MainActivity.this, type, jsonProperties);
                        }

                        result.success(null);
                    }
                });

        new MethodChannel(getFlutterView(), PAIRING_CHANNEL).setMethodCallHandler((methodCall, result) -> {
            switch (methodCall.method) {
                case "unpair":
                    Kumulos.pushUnregister(MainActivity.this);

                    mLocationTrackingInitializer.stopLocationTracking(MainActivity.this);

                    SharedPreferences sp  = getSharedPreferences("KUMULOS", MODE_PRIVATE);
                    SharedPreferences.Editor editor = sp.edit();
                    editor.clear();
                    editor.apply();

                    result.success(null);
                    break;
                default:
                    result.notImplemented();
            }
        });

        sPushChannel = new MethodChannel(getFlutterView(), PUSH_CHANNEL);
        sPushChannel.setMethodCallHandler(
                (methodCall, result) -> {
                    switch (methodCall.method) {
                        case "pushRegister":
                            Kumulos.pushRegister(getApplication());
                            result.success(null);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                }
        );

        setupLocationHandling();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == REQUEST_PERMISSIONS_REQUEST_CODE) {
            if (grantResults.length < 1) {
                return;
            }

            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                mLocationChannel.invokeMethod("locationAuthorized", null);
                mLocationTrackingInitializer.startLocationTracking(this);
            } else if (grantResults[0] == PackageManager.PERMISSION_DENIED) {
                mLocationChannel.invokeMethod("locationNotAuthorized", null);
            }
        }
        else{
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        }
    }

    private void setupLocationHandling() {
        mLocationTrackingInitializer = new LocationTrackingInitializer();
        mLocationChannel = new MethodChannel(getFlutterView(), LOCATION_CHANNEL);
        mLocationChannel.setMethodCallHandler((methodCall, result) -> {
            switch (methodCall.method) {
                case "requestLocation":
                    MainActivity.this.requestLocation();
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });

        SharedPreferences prefs = getSharedPreferences("KUMULOS", MODE_PRIVATE);
        if (this.hasLocationPermission(this) && prefs.contains("K_API_KEY")) {
            mLocationTrackingInitializer.startLocationTracking(this);
        }
    }

    private boolean hasLocationPermission(Context context) {
        int fineLocationPermissionState = ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION);
        return fineLocationPermissionState == PackageManager.PERMISSION_GRANTED;
    }

    private void requestLocation() {
        SharedPreferences sp = getSharedPreferences("KUMULOS", MODE_PRIVATE);
        if (sp.contains("locationSent")) {
            SharedPreferences.Editor editor = sp.edit();
            editor.remove("locationSent");
            editor.apply();
        }

        String[] perms = new String[] { Manifest.permission.ACCESS_FINE_LOCATION };

        if (!ActivityCompat.shouldShowRequestPermissionRationale(MainActivity.this, Manifest.permission.ACCESS_FINE_LOCATION)) {
            ActivityCompat.requestPermissions(MainActivity.this, perms, REQUEST_PERMISSIONS_REQUEST_CODE);
            return;
        }

        AlertDialog.Builder alertBuilder = new AlertDialog.Builder(MainActivity.this);
        alertBuilder.setCancelable(true);
        alertBuilder.setTitle(getString(R.string.location_prompt_title));
        alertBuilder.setMessage(getString(R.string.location_prompt_body));
        alertBuilder.setPositiveButton(android.R.string.yes, (dialog, which) ->
                ActivityCompat.requestPermissions(this, perms, REQUEST_PERMISSIONS_REQUEST_CODE));

        AlertDialog alert = alertBuilder.create();
        alert.show();
    }

}
