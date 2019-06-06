package com.kumulos.companion.location;

import android.annotation.SuppressLint;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.location.Location;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.Task;
import com.kumulos.android.Kumulos;

import org.json.JSONException;
import org.json.JSONObject;

public class LocationTrackingInitializer {

    private FusedLocationProviderClient mFusedLocationClient;
    private LocationRequest mLocationRequest;
    private static final long UPDATE_INTERVAL = 60000;
    private static final long FASTEST_UPDATE_INTERVAL = 30000;
    private static final long MAX_WAIT_TIME = UPDATE_INTERVAL * 5;//batch. saves battery, solves background execution limits
    private static final long SMALLEST_DISPLACEMENT_FOR_LOCATION_UPDATE = 5;//5m

    public void startLocationTracking(Context context){
        this.mFusedLocationClient = LocationServices.getFusedLocationProviderClient(context);
        this.mLocationRequest = this.createLocationRequest();

        this.requestLocationUpdates(context);

        @SuppressLint("MissingPermission") Task<Location> result = this.mFusedLocationClient.getLastLocation();
        result.addOnCompleteListener(task -> {
            Location location = task.getResult();
            if (null == location) {
                return;
            }
            SharedPreferences sp = context.getSharedPreferences("KUMULOS", Context.MODE_PRIVATE);

            if (sp.contains("locationSent")) {
                return;
            }

            JSONObject props = new JSONObject();
            try {
                props.put("lat", location.getLatitude());
                props.put("lng", location.getLongitude());
                Kumulos.trackEventImmediately(context, "companion.locationUpdated", props);

                SharedPreferences.Editor editor = sp.edit();
                editor.putBoolean("locationSent", true);
                editor.apply();
            } catch (JSONException e) {
                e.printStackTrace();
            }
        });
    }

    public void stopLocationTracking(Context context) {
        if (null != this.mFusedLocationClient) {
            this.mFusedLocationClient.removeLocationUpdates(this.getPendingIntent(context));
        }
    }

    private LocationRequest createLocationRequest() {
        LocationRequest request = new LocationRequest();

        request.setInterval(UPDATE_INTERVAL);
        request.setFastestInterval(FASTEST_UPDATE_INTERVAL);
        request.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
        request.setMaxWaitTime(MAX_WAIT_TIME);
        request.setSmallestDisplacement(SMALLEST_DISPLACEMENT_FOR_LOCATION_UPDATE);

        return request;
    }


    private void requestLocationUpdates(Context context) {
        try {
            this.mFusedLocationClient.requestLocationUpdates(this.mLocationRequest, this.getPendingIntent(context));
        } catch (SecurityException e) {
            e.printStackTrace();
        }
    }

    private PendingIntent getPendingIntent(Context context) {
        Intent intent = new Intent(context, LocationBroadcastReceiver.class);
        intent.setAction(LocationBroadcastReceiver.ACTION_PROCESS_LOCATION_UPDATE);
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);
    }
}
