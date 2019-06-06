package com.kumulos.companion.location;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.location.Location;

import com.google.android.gms.location.LocationResult;
import com.kumulos.android.Kumulos;

import java.util.List;

public class LocationBroadcastReceiver extends BroadcastReceiver {

    static final String ACTION_PROCESS_LOCATION_UPDATE = "com.kumulos.companion.LOCATION_UPDATE";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (null == intent) {
            return;
        }

        final String action = intent.getAction();

        if (!ACTION_PROCESS_LOCATION_UPDATE.equals(action)) {
            return;
        }

        LocationResult result = LocationResult.extractResult(intent);

        if (null == result) {
            return;
        }

        List<Location> locations = result.getLocations();

        for (Location location : locations) {
            Kumulos.sendLocationUpdate(context, location);
        }

    }
}
