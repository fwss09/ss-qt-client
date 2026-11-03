package org.shadowsocks.client;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.util.Log;

public class ShadowsocksVpnService extends VpnService {
    private static final String TAG = "SS_VpnService";
    private static final String CHANNEL_ID = "ss_vpn_status";
    private static final int NOTIFICATION_ID = 1001;

    public static final String ACTION_CONNECT = "org.shadowsocks.client.CONNECT";
    public static final String ACTION_DISCONNECT = "org.shadowsocks.client.DISCONNECT";
    public static final String EXTRA_SERVER_HOST = "server_host";
    public static final String EXTRA_SOCKS_PORT = "socks_port";

    private ParcelFileDescriptor mVpnInterface = null;
    private static volatile ShadowsocksVpnService sInstance = null;

    // Native C++ callbacks
    public static native void onVpnEstablished(int tunFd);
    public static native void onVpnStopped();

    public static ShadowsocksVpnService getInstance() {
        return sInstance;
    }

    public static boolean protectSocket(int fd) {
        ShadowsocksVpnService instance = sInstance;
        if (instance != null) {
            boolean ok = instance.protect(fd);
            Log.i(TAG, "protectSocket fd=" + fd + " result=" + ok);
            return ok;
        }
        Log.w(TAG, "protectSocket called but sInstance is null");
        return false;
    }

    public static boolean startVpnService(Context context, String serverHost, int socksPort) {
        try {
            Intent intent = new Intent(context, ShadowsocksVpnService.class);
            intent.setAction(ACTION_CONNECT);
            intent.putExtra(EXTRA_SERVER_HOST, serverHost);
            intent.putExtra(EXTRA_SOCKS_PORT, socksPort);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent);
            } else {
                context.startService(intent);
            }
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Failed to start VPN service: " + e.getMessage(), e);
            onVpnStopped();
            return false;
        }
    }

    public static void stopVpnService(Context context) {
        try {
            Intent intent = new Intent(context, ShadowsocksVpnService.class);
            intent.setAction(ACTION_DISCONNECT);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent);
            } else {
                context.startService(intent);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to stop VPN service: " + e.getMessage(), e);
            onVpnStopped();
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        sInstance = this;
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) return START_NOT_STICKY;

        String action = intent.getAction();
        if (ACTION_CONNECT.equals(action)) {
            Notification notification = buildNotification("Shadowsocks", "Establishing secure tunnel...");
            if (Build.VERSION.SDK_INT >= 34) { // Android 14+
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED);
            } else {
                startForeground(NOTIFICATION_ID, notification);
            }
            String serverHost = intent.getStringExtra(EXTRA_SERVER_HOST);
            int socksPort = intent.getIntExtra(EXTRA_SOCKS_PORT, 1080);
            startVpn(serverHost, socksPort);
        } else if (ACTION_DISCONNECT.equals(action)) {
            stopVpn();
        }

        return START_NOT_STICKY;
    }

    private void startVpn(String serverHost, int socksPort) {
        Log.i(TAG, "Starting VPN session to server " + serverHost + " via local SOCKS port " + socksPort);

        try {
            if (mVpnInterface != null) {
                mVpnInterface.close();
                mVpnInterface = null;
            }

            Builder builder = new Builder();
            builder.setSession("Shadowsocks");
            builder.setMtu(1500);

            // Virtual IPv4 network (carrier/isolated subnet)
            builder.addAddress("198.18.0.1", 15);

            // Default route
            builder.addRoute("0.0.0.0", 0);

            // DNS servers: 198.18.0.2 points to local mapdns in hev-socks5-tunnel
            builder.addDnsServer("198.18.0.2");
            builder.addDnsServer("1.1.1.1");

            // Exclude our own app so Shadowsocks proxy connections don't loop back!
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false);
            }
            try {
                builder.addDisallowedApplication(getPackageName());
            } catch (Exception e) {
                Log.w(TAG, "Could not exclude package from VPN: " + e.getMessage());
            }

            mVpnInterface = builder.establish();
            if (mVpnInterface != null) {
                int tunFd = mVpnInterface.detachFd();
                Log.i(TAG, "VPN TUN established successfully with FD: " + tunFd);

                // Update notification to Connected
                NotificationManager manager = getSystemService(NotificationManager.class);
                if (manager != null) {
                    manager.notify(NOTIFICATION_ID, buildNotification("Shadowsocks Connected", "Protected • Traffic encrypted"));
                }
                onVpnEstablished(tunFd);
            } else {
                Log.e(TAG, "Failed to establish VPN interface (null returned by Builder)");
                onVpnStopped();
                stopForeground(true);
                stopSelf();
            }

        } catch (Exception e) {
            Log.e(TAG, "Error starting VPN: " + e.getMessage(), e);
            onVpnStopped();
            stopForeground(true);
            stopSelf();
        }
    }

    private void stopVpn() {
        Log.i(TAG, "Stopping VPN session");
        try {
            if (mVpnInterface != null) {
                mVpnInterface.close();
                mVpnInterface = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error closing VPN interface: " + e.getMessage());
        }

        stopForeground(true);
        onVpnStopped();
        stopSelf();
    }

    @Override
    public void onDestroy() {
        sInstance = null;
        stopVpn();
        super.onDestroy();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "VPN Status",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Shows active Shadowsocks VPN connection status");
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private Notification buildNotification(String title, String text) {
        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder = new Notification.Builder(this, CHANNEL_ID);
        } else {
            builder = new Notification.Builder(this);
        }

        builder.setContentTitle(title)
               .setContentText(text)
               .setSmallIcon(android.R.drawable.ic_lock_lock)
               .setOngoing(true);

        return builder.build();
    }
}
