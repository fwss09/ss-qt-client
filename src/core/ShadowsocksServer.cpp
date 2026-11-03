#include "ShadowsocksServer.h"

namespace Shadowsocks {

ShadowsocksServer::ShadowsocksServer(QObject *parent)
    : QTcpServer(parent) {
}

ShadowsocksServer::~ShadowsocksServer() {
    stopServer();
}

bool ShadowsocksServer::startServer(const QHostAddress &bindAddr,
                                    quint16 localPort,
                                    const QString &remoteHost,
                                    quint16 remotePort,
                                    const QString &method,
                                    const QString &password) {
    if (m_running) {
        stopServer();
    }

    m_remoteHost = remoteHost;
    m_remotePort = remotePort;
    m_method = method;
    m_password = password;

    const CipherInfo *info = CryptoHelper::getCipherInfo(method);
    if (!info) {
        emit serverError(QString("Unknown encryption method: %1").arg(method));
        return false;
    }

    m_masterKey = CryptoHelper::deriveMasterKey(password, info->keySize);
    if (m_masterKey.isEmpty()) {
        emit serverError("Failed to derive master key from password");
        return false;
    }

    if (!listen(bindAddr, localPort)) {
        emit serverError(QString("Failed to bind SOCKS5 listener on %1:%2: %3")
                         .arg(bindAddr.toString()).arg(localPort).arg(errorString()));
        return false;
    }

    m_running = true;
    emit logMessage(QString("[CORE] SOCKS5 server listening on %1:%2 -> forwarding to %3:%4 (%5)")
                    .arg(bindAddr.toString())
                    .arg(localPort)
                    .arg(remoteHost)
                    .arg(remotePort)
                    .arg(method));
    emit connectionCountChanged(0);
    return true;
}

void ShadowsocksServer::stopServer() {
    if (!m_running && !isListening()) return;

    close();
    m_running = false;

    for (Socks5Session *session : m_sessions) {
        session->disconnect(this);
        session->deleteLater();
    }
    m_sessions.clear();

    emit logMessage("[CORE] SOCKS5 server stopped");
    emit connectionCountChanged(0);
}

void ShadowsocksServer::incomingConnection(qintptr socketDescriptor) {
    auto *session = new Socks5Session(socketDescriptor,
                                      m_remoteHost,
                                      m_remotePort,
                                      m_method,
                                      m_masterKey,
                                      this);

    m_sessions.append(session);
    emit connectionCountChanged(m_sessions.size());

    connect(session, &Socks5Session::bytesTransferred, this, &ShadowsocksServer::trafficTransferred);
    connect(session, &Socks5Session::sessionClosed, this, &ShadowsocksServer::onSessionClosed);
    connect(session, &Socks5Session::logMessage, this, &ShadowsocksServer::logMessage);

    session->start();
}

void ShadowsocksServer::onSessionClosed() {
    auto *session = qobject_cast<Socks5Session*>(sender());
    if (session) {
        m_sessions.removeOne(session);
        emit connectionCountChanged(m_sessions.size());
    }
}

}
