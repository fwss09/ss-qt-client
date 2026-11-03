#include "PingService.h"
#include <QTimer>

namespace Shadowsocks {

PingWorker::PingWorker(const QString &serverId, const QString &host, quint16 port, QObject *parent)
    : QObject(parent),
      m_serverId(serverId),
      m_host(host),
      m_port(port) {
}

void PingWorker::start() {
    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected, this, &PingWorker::onConnected);
    connect(m_socket, &QTcpSocket::errorOccurred, this, &PingWorker::onError);

    QTimer::singleShot(3000, this, &PingWorker::onTimeout);

    m_timer.start();
    m_socket->connectToHost(m_host, m_port);
}

void PingWorker::onConnected() {
    int latency = static_cast<int>(m_timer.elapsed());
    m_socket->abort();
    emit finished(m_serverId, latency);
    deleteLater();
}

void PingWorker::onError(QAbstractSocket::SocketError error) {
    Q_UNUSED(error)
    m_socket->abort();
    emit finished(m_serverId, -1);
    deleteLater();
}

void PingWorker::onTimeout() {
    if (m_socket && m_socket->state() != QAbstractSocket::UnconnectedState) {
        m_socket->abort();
        emit finished(m_serverId, -1);
        deleteLater();
    }
}

PingService::PingService(QObject *parent)
    : QObject(parent) {
}

void PingService::pingServer(const QString &serverId, const QString &host, quint16 port) {
    auto *worker = new PingWorker(serverId, host, port, this);
    connect(worker, &PingWorker::finished, this, &PingService::pingResult);
    worker->start();
}

}
