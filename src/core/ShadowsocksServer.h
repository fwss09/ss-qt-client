#ifndef SHADOWSOCKSSERVER_H
#define SHADOWSOCKSSERVER_H

#include <QTcpServer>
#include <QList>
#include "Socks5Session.h"

namespace Shadowsocks {

class ShadowsocksServer : public QTcpServer {
    Q_OBJECT

public:
    explicit ShadowsocksServer(QObject *parent = nullptr);
    ~ShadowsocksServer() override;

    bool startServer(const QHostAddress &bindAddr,
                     quint16 localPort,
                     const QString &remoteHost,
                     quint16 remotePort,
                     const QString &method,
                     const QString &password);

    void stopServer();

    bool isRunning() const { return m_running; }
    int activeConnectionsCount() const { return m_sessions.size(); }

signals:
    void trafficTransferred(quint64 bytesIn, quint64 bytesOut);
    void serverError(const QString &error);
    void logMessage(const QString &msg);
    void connectionCountChanged(int count);

protected:
    void incomingConnection(qintptr socketDescriptor) override;

private slots:
    void onSessionClosed();

private:
    bool m_running = false;
    QString m_remoteHost;
    quint16 m_remotePort = 8388;
    QString m_method;
    QString m_password;
    QByteArray m_masterKey;

    QList<Socks5Session*> m_sessions;
};

}

#endif
