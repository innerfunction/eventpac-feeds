package com.eventpac.client.emptyproject;

import android.annotation.SuppressLint;
import android.os.Build;
import android.webkit.WebView;

@SuppressLint("NewApi")
public class EPApplication extends com.eventpac.core.EPApplication{
    
    public EPApplication() {
        super("app:/common/configuration.json");
    }

}
