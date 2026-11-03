#ifndef PINGSERVICE_H
#define PINGSERVICE_H

#include <QObject>
#include <QTcpSocket>
#include <QElapsedTimer>

namespace Shadowsocks {

class PingWorker : public QObject {
    Q_OBJECT

public:
    PingWorker(const QString &serverId, const QString &host, quint16 port, QObject *parent = nullptr);
    void start();

signals:
    void finished(const QString &serverId, int latencyMs);

private slots:
    void onConnected();
    void onError(QAbstractSocket::SocketError error);
    void onTimeout();

private:
    QString m_serverId;
    QString m_host;
    quint16 m_port;
    QTcpSocket *m_socket = nullptr;
    QElapsedTimer m_timer;
};

class PingService : public QObject {
    Q_OBJECT

public:
    explicit PingService(QObject *parent = nullptr);

    void pingServer(const QString &serverId, const QString &host, quint16 port);

signals:
    void pingResult(const QString &serverId, int latencyMs);
};

}

#endif
