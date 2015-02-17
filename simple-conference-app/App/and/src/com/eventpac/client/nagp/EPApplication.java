package com.eventpac.client.nagp;

import android.annotation.SuppressLint;

@SuppressLint("NewApi")
public class EPApplication extends com.eventpac.core.EPApplication {
    
    public EPApplication() {
        super("app:/common/configuration.json");
    }

}
