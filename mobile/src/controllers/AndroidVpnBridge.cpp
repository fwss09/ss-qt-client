#include "AndroidVpnBridge.h"
#include <QDebug>
#include <cstring>
#include <cstdio>

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#include <QJniEnvironment>
#include <jni.h>
#include "hev-main.h"

extern "C" {
    JNIEXPORT void JNICALL
    Java_org_shadowsocks_client_ShadowsocksVpnService_onVpnEstablished(JNIEnv *env, jclass clazz, jint tunFd) {
        Q_UNUSED(env)
        Q_UNUSED(clazz)
        qDebug() << "[JNI] onVpnEstablished with FD:" << tunFd;
        if (Shadowsocks::AndroidVpnBridge::instance()) {
            Shadowsocks::AndroidVpnBridge::instance()->notifyVpnEstablished(tunFd);
        }
    }

    JNIEXPORT void JNICALL
    Java_org_shadowsocks_client_ShadowsocksVpnService_onVpnStopped(JNIEnv *env, jclass clazz) {
        Q_UNUSED(env)
        Q_UNUSED(clazz)
        qDebug() << "[JNI] onVpnStopped received";
        if (Shadowsocks::AndroidVpnBridge::instance()) {
            Shadowsocks::AndroidVpnBridge::instance()->notifyVpnStopped();
        }
    }
}
#endif

namespace Shadowsocks {

AndroidVpnBridge *AndroidVpnBridge::s_instance = nullptr;

AndroidVpnBridge* AndroidVpnBridge::instance() {
    if (!s_instance) {
        s_instance = new AndroidVpnBridge();
    }
    return s_instance;
}

AndroidVpnBridge::AndroidVpnBridge(QObject *parent)
    : QObject(parent) {
}

AndroidVpnBridge::~AndroidVpnBridge() {
#ifdef Q_OS_ANDROID
    hev_socks5_tunnel_quit();
    if (m_tunnelThread.joinable()) {
        m_tunnelThread.detach();
    }
#endif
}

bool AndroidVpnBridge::protectSocket(int fd) {
#ifdef Q_OS_ANDROID
    if (fd <= 0) return false;
    jboolean ok = QJniObject::callStaticMethod<jboolean>(
        "org/shadowsocks/client/ShadowsocksVpnService",
        "protectSocket",
        "(I)Z",
        static_cast<jint>(fd)
    );
    return ok;
#else
    Q_UNUSED(fd)
    return true;
#endif
}

bool AndroidVpnBridge::isVpnPrepared() {
#ifdef Q_OS_ANDROID
    auto context = QJniObject(QNativeInterface::QAndroidApplication::context());
    if (!context.isValid()) return false;

    auto intent = QJniObject::callStaticObjectMethod(
        "android/net/VpnService",
        "prepare",
        "(Landroid/content/Context;)Landroid/content/Intent;",
        context.object<jobject>()
    );

    // If prepare() returns null, permission is ALREADY granted!
    return !intent.isValid();
#else
    return true;
#endif
}

void AndroidVpnBridge::requestVpnPrepare() {
#ifdef Q_OS_ANDROID
    auto context = QJniObject(QNativeInterface::QAndroidApplication::context());
    if (!context.isValid()) return;

    auto intent = QJniObject::callStaticObjectMethod(
        "android/net/VpnService",
        "prepare",
        "(Landroid/content/Context;)Landroid/content/Intent;",
        context.object<jobject>()
    );

    if (intent.isValid()) {
        const int VPN_REQUEST_CODE = 0x5501;
        context.callMethod<void>(
            "startActivityForResult",
            "(Landroid/content/Intent;I)V",
            intent.object<jobject>(),
            VPN_REQUEST_CODE
        );
    }
#endif
}

bool AndroidVpnBridge::startVpnService(const QString &serverHost, quint16 socksPort) {
    m_socksPort = socksPort;

#ifdef Q_OS_ANDROID
    auto context = QJniObject(QNativeInterface::QAndroidApplication::context());
    if (!context.isValid()) {
        emit vpnError("Android Context unavailable");
        notifyVpnStopped();
        return false;
    }

    // 1. Verify VPN preparation (show permission prompt if not yet granted)
    auto prepareIntent = QJniObject::callStaticObjectMethod(
        "android/net/VpnService",
        "prepare",
        "(Landroid/content/Context;)Landroid/content/Intent;",
        context.object<jobject>()
    );

    if (prepareIntent.isValid()) {
        qDebug() << "[VPN] Prompting user for VPN permission dialog";
        const int VPN_REQUEST_CODE = 0x5501;
        context.callMethod<void>(
            "startActivityForResult",
            "(Landroid/content/Intent;I)V",
            prepareIntent.object<jobject>(),
            VPN_REQUEST_CODE
        );
        notifyVpnStopped();
        return false;
    }

    // 2. Start ShadowsocksVpnService through static helper
    QJniObject jHost = QJniObject::fromString(serverHost);
    jboolean ok = QJniObject::callStaticMethod<jboolean>(
        "org/shadowsocks/client/ShadowsocksVpnService",
        "startVpnService",
        "(Landroid/content/Context;Ljava/lang/String;I)Z",
        context.object<jobject>(),
        jHost.object<jstring>(),
        static_cast<jint>(socksPort)
    );

    if (!ok) {
        qWarning() << "[VPN] Failed to launch ShadowsocksVpnService";
        notifyVpnStopped();
        return false;
    }

    return true;
#else
    // Desktop preview simulation
    qDebug() << "[MOBILE DESKTOP PREVIEW] Simulating Android VPN connect to" << serverHost << "via SOCKS" << socksPort;
    notifyVpnEstablished(999);
    return true;
#endif
}

void AndroidVpnBridge::stopVpnService() {
#ifdef Q_OS_ANDROID
    hev_socks5_tunnel_quit();
    if (m_tunnelThread.joinable()) {
        m_tunnelThread.detach();
    }

    auto context = QJniObject(QNativeInterface::QAndroidApplication::context());
    if (!context.isValid()) return;

    QJniObject::callStaticMethod<void>(
        "org/shadowsocks/client/ShadowsocksVpnService",
        "stopVpnService",
        "(Landroid/content/Context;)V",
        context.object<jobject>()
    );
#else
    notifyVpnStopped();
#endif
}

void AndroidVpnBridge::notifyVpnEstablished(int tunFd) {
    m_currentTunFd = tunFd;
    m_vpnActive = true;

#ifdef Q_OS_ANDROID
    // Launch hev-socks5-tunnel in a dedicated thread to convert TUN IP packets into SOCKS5 proxy calls
    if (m_tunnelThread.joinable()) {
        hev_socks5_tunnel_quit();
        m_tunnelThread.detach();
    }

    quint16 port = m_socksPort > 0 ? m_socksPort : 1080;
    qDebug() << "[TUN2SOCKS] Spawning tun2socks worker for tunFd" << tunFd << "pointing to 127.0.0.1:" << port;

    m_tunnelThread = std::thread([tunFd, port]() {
        char config[1024];
        std::snprintf(config, sizeof(config),
            "tunnel:\n"
            "  name: tun0\n"
            "  mtu: 1500\n"
            "  ipv4: 198.18.0.1\n"
            "socks5:\n"
            "  address: 127.0.0.1\n"
            "  port: %u\n"
            "  udp: 'udp'\n"
            "mapdns:\n"
            "  address: 198.18.0.2\n"
            "  port: 53\n"
            "  network: 100.64.0.0\n"
            "  netmask: 255.192.0.0\n"
            "  cache-size: 10000\n"
            "misc:\n"
            "  log-file: stderr\n"
            "  log-level: debug\n",
            static_cast<unsigned int>(port));

        qDebug() << "[TUN2SOCKS] Configuration:\n" << config;
        int res = hev_socks5_tunnel_main_from_str(reinterpret_cast<const unsigned char *>(config), std::strlen(config), tunFd);
        qDebug() << "[TUN2SOCKS] hev-socks5-tunnel engine exited with code:" << res;
    });
#endif

    emit vpnEstablished(tunFd);
    emit vpnStateChanged(true);
}

void AndroidVpnBridge::notifyVpnStopped() {
#ifdef Q_OS_ANDROID
    hev_socks5_tunnel_quit();
    if (m_tunnelThread.joinable()) {
        m_tunnelThread.detach();
    }
#endif

    m_currentTunFd = -1;
    m_vpnActive = false;
    emit vpnStateChanged(false);
}

} // namespace Shadowsocks
