#ifndef SOCKS5SESSION_H
#define SOCKS5SESSION_H

#include <QObject>
#include <QTcpSocket>
#include <QUdpSocket>
#include <QByteArray>
#include <QHostAddress>
#include <QSocketNotifier>
#include "Crypto.h"

namespace Shadowsocks {

class Socks5Session : public QObject {
    Q_OBJECT

public:
    enum SessionState {
        AwaitingGreeting,
        AwaitingRequest,
        ConnectingRemote,
        Streaming,
        Closing
    };

    explicit Socks5Session(qintptr socketDescriptor,
                           const QString &remoteHost,
                           quint16 remotePort,
                           const QString &method,
                           const QByteArray &masterKey,
                           QObject *parent = nullptr);
    ~Socks5Session() override;

    void start();

signals:
    void bytesTransferred(quint64 in, quint64 out);
    void sessionClosed();
    void logMessage(const QString &msg);

private slots:
    void onClientReadyRead();
    void onClientDisconnected();
    void onClientError(QAbstractSocket::SocketError error);

    void onRemoteConnected();
    void onRemoteReadyRead();
    void onRemoteDisconnected();
    void onRemoteError(QAbstractSocket::SocketError error);

    void onLocalUdpReadyRead();
    void onRemoteUdpReadyRead();

private:
    void handleGreeting();
    void handleRequest();
    void handleUdpAssociate();
    void closeSession(const QString &reason = QString());

    qintptr m_socketDescriptor;
    QTcpSocket *m_clientSocket = nullptr;
    QTcpSocket *m_remoteSocket = nullptr;
    QSocketNotifier *m_connectNotifier = nullptr;
    int m_connectingFd = -1;

    QUdpSocket *m_udpLocalSocket = nullptr;
    QUdpSocket *m_udpRemoteSocket = nullptr;
    QHostAddress m_clientUdpAddress;
    quint16 m_clientUdpPort = 0;

    QString m_remoteHost;
    QHostAddress m_remoteIpAddress;
    quint16 m_remotePort;
    QString m_method;
    QByteArray m_masterKey;
    const CipherInfo *m_cipherInfo = nullptr;

    SessionState m_state = AwaitingGreeting;

    QByteArray m_clientBuffer;
    QByteArray m_remoteBuffer;
    QByteArray m_targetHeader;
    QByteArray m_pendingClientData;

    AeadStreamEncryptor m_encryptor;
    AeadStreamDecryptor m_decryptor;

    bool m_serverSaltReceived = false;
    QByteArray m_serverSalt;
};

}

#endif
