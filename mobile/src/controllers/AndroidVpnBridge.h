#ifndef ANDROIDVPNBRIDGE_H
#define ANDROIDVPNBRIDGE_H

#include <QObject>
#include <QString>
#include <thread>

namespace Shadowsocks {

class AndroidVpnBridge : public QObject {
    Q_OBJECT

public:
    static AndroidVpnBridge* instance();

    bool isVpnPrepared();
    void requestVpnPrepare();

    static bool protectSocket(int fd);

    bool startVpnService(const QString &serverHost, quint16 socksPort);
    void stopVpnService();

    bool isVpnActive() const { return m_vpnActive; }

signals:
    void vpnStateChanged(bool active);
    void vpnError(const QString &message);
    void vpnEstablished(int tunFd);

public slots:
    void notifyVpnEstablished(int tunFd);
    void notifyVpnStopped();

private:
    explicit AndroidVpnBridge(QObject *parent = nullptr);
    ~AndroidVpnBridge();

    static AndroidVpnBridge *s_instance;
    bool m_vpnActive = false;
    int m_currentTunFd = -1;
    quint16 m_socksPort = 1080;
    std::thread m_tunnelThread;
};

} // namespace Shadowsocks

#endif // ANDROIDVPNBRIDGE_H
