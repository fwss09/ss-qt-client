#include "Socks5Session.h"
#include <QtEndian>
#include <QHostAddress>
#include <QHostInfo>
#include <QNetworkDatagram>
#include <unistd.h>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <sys/socket.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

static void protectSocketFd(qintptr fd) {
    if (fd <= 0) return;
    QJniObject::callStaticMethod<jboolean>(
        "org/shadowsocks/client/ShadowsocksVpnService",
        "protectSocket",
        "(I)Z",
        static_cast<jint>(fd)
    );
}
#endif

namespace Shadowsocks {

Socks5Session::Socks5Session(qintptr socketDescriptor,
                             const QString &remoteHost,
                             quint16 remotePort,
                             const QString &method,
                             const QByteArray &masterKey,
                             QObject *parent)
    : QObject(parent),
      m_socketDescriptor(socketDescriptor),
      m_remoteHost(remoteHost),
      m_remotePort(remotePort),
      m_method(method),
      m_masterKey(masterKey) {
    m_cipherInfo = CryptoHelper::getCipherInfo(m_method);
}

Socks5Session::~Socks5Session() {
    if (m_connectNotifier) {
        m_connectNotifier->setEnabled(false);
        delete m_connectNotifier;
        m_connectNotifier = nullptr;
    }
    if (m_connectingFd >= 0) {
        ::close(m_connectingFd);
        m_connectingFd = -1;
    }
    if (m_clientSocket) {
        m_clientSocket->disconnect(this);
        m_clientSocket->abort();
        delete m_clientSocket;
    }
    if (m_remoteSocket) {
        m_remoteSocket->disconnect(this);
        m_remoteSocket->abort();
        delete m_remoteSocket;
    }
    if (m_udpLocalSocket) {
        m_udpLocalSocket->disconnect(this);
        m_udpLocalSocket->close();
        delete m_udpLocalSocket;
    }
    if (m_udpRemoteSocket) {
        m_udpRemoteSocket->disconnect(this);
        m_udpRemoteSocket->close();
        delete m_udpRemoteSocket;
    }
}

void Socks5Session::start() {
    m_clientSocket = new QTcpSocket(this);
    if (!m_clientSocket->setSocketDescriptor(m_socketDescriptor)) {
        closeSession("Failed to set client socket descriptor");
        return;
    }

    connect(m_clientSocket, &QTcpSocket::readyRead, this, &Socks5Session::onClientReadyRead);
    connect(m_clientSocket, &QTcpSocket::disconnected, this, &Socks5Session::onClientDisconnected);
    connect(m_clientSocket, &QTcpSocket::errorOccurred, this, &Socks5Session::onClientError);

    m_state = AwaitingGreeting;
}

void Socks5Session::onClientReadyRead() {
    QByteArray data = m_clientSocket->readAll();
    m_clientBuffer.append(data);

    if (m_state == AwaitingGreeting) {
        handleGreeting();
    } else if (m_state == AwaitingRequest) {
        handleRequest();
    } else if (m_state == ConnectingRemote) {
        m_pendingClientData.append(m_clientBuffer);
        m_clientBuffer.clear();
    } else if (m_state == Streaming) {
        if (!m_clientBuffer.isEmpty() && m_remoteSocket) {
            QByteArray encrypted = m_encryptor.encryptChunk(m_clientBuffer);
            m_clientBuffer.clear();
            if (!encrypted.isEmpty()) {
                m_remoteSocket->write(encrypted);
                emit bytesTransferred(0, encrypted.size());
            }
        }
    }
}

void Socks5Session::handleGreeting() {
    if (m_clientBuffer.size() < 2) return;

    quint8 ver = static_cast<quint8>(m_clientBuffer[0]);
    if (ver != 0x05) {
        closeSession(QString("Unsupported SOCKS version: %1").arg(ver));
        return;
    }

    quint8 nmethods = static_cast<quint8>(m_clientBuffer[1]);
    if (m_clientBuffer.size() < 2 + nmethods) return;

    const char response[] = {0x05, 0x00};
    m_clientSocket->write(response, 2);

    m_clientBuffer.remove(0, 2 + nmethods);
    m_state = AwaitingRequest;

    if (!m_clientBuffer.isEmpty()) {
        handleRequest();
    }
}

void Socks5Session::handleRequest() {
    if (m_clientBuffer.size() < 4) return;

    quint8 ver = static_cast<quint8>(m_clientBuffer[0]);
    quint8 cmd = static_cast<quint8>(m_clientBuffer[1]);
    quint8 atyp = static_cast<quint8>(m_clientBuffer[3]);

    if (ver != 0x05) {
        closeSession("Invalid SOCKS request version");
        return;
    }

    if (cmd == 0x03) {
        handleUdpAssociate();
        return;
    }

    if (cmd != 0x01) {
        const char rep[] = {0x05, 0x07, 0x00, 0x01, 0, 0, 0, 0, 0, 0};
        m_clientSocket->write(rep, sizeof(rep));
        closeSession(QString("Unsupported SOCKS5 command: %1").arg(cmd));
        return;
    }

    int headerLen = 0;
    QString targetDisplay;

    if (atyp == 0x01) {
        headerLen = 1 + 4 + 2;
        if (m_clientBuffer.size() < 3 + headerLen) return;

        quint32 ip = qFromBigEndian<quint32>(reinterpret_cast<const uchar*>(m_clientBuffer.constData() + 4));
        quint16 port = qFromBigEndian<quint16>(reinterpret_cast<const uchar*>(m_clientBuffer.constData() + 8));
        targetDisplay = QString("%1:%2").arg(QHostAddress(ip).toString()).arg(port);

    } else if (atyp == 0x03) {
        if (m_clientBuffer.size() < 5) return;
        quint8 domainLen = static_cast<quint8>(m_clientBuffer[4]);
        headerLen = 1 + 1 + domainLen + 2;
        if (m_clientBuffer.size() < 3 + headerLen) return;

        QString domain = QString::fromUtf8(m_clientBuffer.mid(5, domainLen));
        quint16 port = qFromBigEndian<quint16>(reinterpret_cast<const uchar*>(m_clientBuffer.constData() + 5 + domainLen));
        targetDisplay = QString("%1:%2").arg(domain).arg(port);

    } else if (atyp == 0x04) {
        headerLen = 1 + 16 + 2;
        if (m_clientBuffer.size() < 3 + headerLen) return;

        QHostAddress ipv6(reinterpret_cast<const quint8*>(m_clientBuffer.constData() + 4));
        quint16 port = qFromBigEndian<quint16>(reinterpret_cast<const uchar*>(m_clientBuffer.constData() + 20));
        targetDisplay = QString("[%1]:%2").arg(ipv6.toString()).arg(port);

    } else {
        closeSession(QString("Unknown address type: %1").arg(atyp));
        return;
    }

    m_targetHeader = m_clientBuffer.mid(3, headerLen);
    m_clientBuffer.remove(0, 3 + headerLen);

    m_pendingClientData = m_clientBuffer;
    m_clientBuffer.clear();

    emit logMessage(QString("[SOCKS5 TCP] Connecting to %1 via %2:%3")
                    .arg(targetDisplay).arg(m_remoteHost).arg(m_remotePort));

    const char successRep[] = {0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0};
    m_clientSocket->write(successRep, sizeof(successRep));

    m_remoteSocket = new QTcpSocket(this);
    connect(m_remoteSocket, &QTcpSocket::connected, this, &Socks5Session::onRemoteConnected);
    connect(m_remoteSocket, &QTcpSocket::readyRead, this, &Socks5Session::onRemoteReadyRead);
    connect(m_remoteSocket, &QTcpSocket::disconnected, this, &Socks5Session::onRemoteDisconnected);
    connect(m_remoteSocket, &QTcpSocket::errorOccurred, this, &Socks5Session::onRemoteError);

    m_state = ConnectingRemote;

#ifdef Q_OS_ANDROID
    QHostAddress remoteIp(m_remoteHost);
    if (remoteIp.isNull()) {
        QHostInfo info = QHostInfo::fromName(m_remoteHost);
        if (!info.addresses().isEmpty()) {
            remoteIp = info.addresses().first();
        }
    }

    if (!remoteIp.isNull() && remoteIp.protocol() == QAbstractSocket::IPv4Protocol) {
        int fd = ::socket(AF_INET, SOCK_STREAM, 0);
        if (fd >= 0) {
            protectSocketFd(fd);

            int flags = fcntl(fd, F_GETFL, 0);
            fcntl(fd, F_SETFL, flags | O_NONBLOCK);

            sockaddr_in sin{};
            sin.sin_family = AF_INET;
            sin.sin_port = htons(m_remotePort);
            inet_pton(AF_INET, remoteIp.toString().toLatin1().constData(), &sin.sin_addr);

            int res = ::connect(fd, reinterpret_cast<struct sockaddr*>(&sin), sizeof(sin));
            if (res == 0) {
                m_remoteSocket->setSocketDescriptor(fd, QAbstractSocket::ConnectedState, QIODevice::ReadWrite);
                onRemoteConnected();
                return;
            } else if (errno == EINPROGRESS) {
                m_connectingFd = fd;
                m_connectNotifier = new QSocketNotifier(fd, QSocketNotifier::Write, this);
                connect(m_connectNotifier, &QSocketNotifier::activated, this, [this]() {
                    if (m_connectNotifier) {
                        m_connectNotifier->setEnabled(false);
                        m_connectNotifier->deleteLater();
                        m_connectNotifier = nullptr;
                    }
                    int socketFd = m_connectingFd;
                    m_connectingFd = -1;
                    if (socketFd < 0) return;

                    int err = 0;
                    socklen_t len = sizeof(err);
                    getsockopt(socketFd, SOL_SOCKET, SO_ERROR, &err, &len);
                    if (err == 0) {
                        if (m_remoteSocket) {
                            m_remoteSocket->setSocketDescriptor(socketFd, QAbstractSocket::ConnectedState, QIODevice::ReadWrite);
                            onRemoteConnected();
                        } else {
                            ::close(socketFd);
                        }
                    } else {
                        ::close(socketFd);
                        closeSession(QString("Socket connect failed: error %1").arg(err));
                    }
                });
                return;
            } else {
                ::close(fd);
            }
        }
    }
#endif

    m_remoteSocket->connectToHost(m_remoteHost, m_remotePort);
}

void Socks5Session::handleUdpAssociate() {
    m_udpLocalSocket = new QUdpSocket(this);
    if (!m_udpLocalSocket->bind(QHostAddress::LocalHost, 0)) {
        closeSession("Failed to bind local UDP associate socket");
        return;
    }

    quint16 localUdpPort = m_udpLocalSocket->localPort();

#ifdef Q_OS_ANDROID
    int udpFd = ::socket(AF_INET, SOCK_DGRAM, 0);
    if (udpFd >= 0) {
        protectSocketFd(udpFd);

        sockaddr_in anyAddr{};
        anyAddr.sin_family = AF_INET;
        anyAddr.sin_addr.s_addr = INADDR_ANY;
        anyAddr.sin_port = 0;
        ::bind(udpFd, reinterpret_cast<struct sockaddr*>(&anyAddr), sizeof(anyAddr));

        m_udpRemoteSocket = new QUdpSocket(this);
        m_udpRemoteSocket->setSocketDescriptor(udpFd, QAbstractSocket::BoundState, QIODevice::ReadWrite);
    } else {
        m_udpRemoteSocket = new QUdpSocket(this);
        m_udpRemoteSocket->bind(QHostAddress::AnyIPv4, 0);
    }
#else
    m_udpRemoteSocket = new QUdpSocket(this);
    m_udpRemoteSocket->bind(QHostAddress::AnyIPv4, 0);
#endif

    QHostAddress resolvedAddr(m_remoteHost);
    if (resolvedAddr.isNull()) {
        QHostInfo info = QHostInfo::fromName(m_remoteHost);
        if (!info.addresses().isEmpty()) {
            resolvedAddr = info.addresses().first();
        }
    }
    m_remoteIpAddress = resolvedAddr;

    connect(m_udpLocalSocket, &QUdpSocket::readyRead, this, &Socks5Session::onLocalUdpReadyRead);
    connect(m_udpRemoteSocket, &QUdpSocket::readyRead, this, &Socks5Session::onRemoteUdpReadyRead);

    char rep[10] = {
        0x05, 0x00, 0x00, 0x01,
        127, 0, 0, 1,
        static_cast<char>((localUdpPort >> 8) & 0xFF),
        static_cast<char>(localUdpPort & 0xFF)
    };
    m_clientSocket->write(rep, 10);

    emit logMessage(QString("[SOCKS5 UDP] UDP association opened on 127.0.0.1:%1 (remote target %2:%3)")
                    .arg(localUdpPort).arg(m_remoteIpAddress.toString()).arg(m_remotePort));
    m_clientBuffer.clear();
    m_state = Streaming;
}

void Socks5Session::onLocalUdpReadyRead() {
    while (m_udpLocalSocket && m_udpLocalSocket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpLocalSocket->receiveDatagram();
        m_clientUdpAddress = datagram.senderAddress();
        m_clientUdpPort = static_cast<quint16>(datagram.senderPort());

        QByteArray data = datagram.data();

        if (data.size() < 4) continue;

        QByteArray ssPayload = data.mid(3);

        QByteArray encrypted = CryptoHelper::encryptUdpPacket(m_method, m_masterKey, ssPayload);
        if (!encrypted.isEmpty() && m_udpRemoteSocket && !m_remoteIpAddress.isNull()) {
            m_udpRemoteSocket->writeDatagram(encrypted, m_remoteIpAddress, m_remotePort);
            emit bytesTransferred(0, encrypted.size());
        }
    }
}

void Socks5Session::onRemoteUdpReadyRead() {
    while (m_udpRemoteSocket && m_udpRemoteSocket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpRemoteSocket->receiveDatagram();
        QByteArray plain = CryptoHelper::decryptUdpPacket(m_method, m_masterKey, datagram.data());
        if (plain.isEmpty()) continue;

        QByteArray socksPacket;
        socksPacket.append('\0');
        socksPacket.append('\0');
        socksPacket.append('\0');
        socksPacket.append(plain);

        if (m_udpLocalSocket && !m_clientUdpAddress.isNull() && m_clientUdpPort > 0) {
            m_udpLocalSocket->writeDatagram(socksPacket, m_clientUdpAddress, m_clientUdpPort);
            emit bytesTransferred(datagram.data().size(), 0);
        }
    }
}

void Socks5Session::onRemoteConnected() {
    if (m_state != ConnectingRemote) return;

    if (!m_cipherInfo) {
        closeSession("Cipher info unavailable");
        return;
    }

    QByteArray clientSalt = CryptoHelper::generateRandomBytes(m_cipherInfo->saltSize);
    if (!m_encryptor.init(m_method, m_masterKey, clientSalt)) {
        closeSession("Failed to initialize AEAD stream encryptor");
        return;
    }

    m_remoteSocket->write(clientSalt);

    QByteArray initialPayload = m_targetHeader + m_pendingClientData;
    m_pendingClientData.clear();

    QByteArray encrypted = m_encryptor.encryptChunk(initialPayload);
    if (encrypted.isEmpty()) {
        closeSession("Failed to encrypt initial Shadowsocks payload");
        return;
    }

    m_remoteSocket->write(encrypted);
    emit bytesTransferred(0, clientSalt.size() + encrypted.size());

    m_state = Streaming;
}

void Socks5Session::onRemoteReadyRead() {
    QByteArray incoming = m_remoteSocket->readAll();
    if (incoming.isEmpty()) return;

    if (!m_serverSaltReceived) {
        m_serverSalt.append(incoming);
        if (m_serverSalt.size() < m_cipherInfo->saltSize) {
            return;
        }

        QByteArray actualSalt = m_serverSalt.left(m_cipherInfo->saltSize);
        QByteArray remaining = m_serverSalt.mid(m_cipherInfo->saltSize);
        m_serverSaltReceived = true;

        if (!m_decryptor.init(m_method, m_masterKey, actualSalt)) {
            closeSession("Failed to initialize AEAD stream decryptor");
            return;
        }

        incoming = remaining;
    }

    if (incoming.isEmpty()) return;

    QList<QByteArray> payloads;
    if (!m_decryptor.feed(incoming, payloads)) {
        closeSession("AEAD decryption failed (tag mismatch or corrupt stream)");
        return;
    }

    for (const QByteArray &chunk : payloads) {
        m_clientSocket->write(chunk);
        emit bytesTransferred(chunk.size(), 0);
    }
}

void Socks5Session::onClientDisconnected() {
    closeSession();
}

void Socks5Session::onClientError(QAbstractSocket::SocketError error) {
    Q_UNUSED(error)
    closeSession(QString("Client socket error: %1").arg(m_clientSocket ? m_clientSocket->errorString() : "unknown"));
}

void Socks5Session::onRemoteDisconnected() {
    closeSession();
}

void Socks5Session::onRemoteError(QAbstractSocket::SocketError error) {
    Q_UNUSED(error)
    closeSession(QString("Remote server socket error: %1").arg(m_remoteSocket ? m_remoteSocket->errorString() : "unknown"));
}

void Socks5Session::closeSession(const QString &reason) {
    if (m_state == Closing) return;
    m_state = Closing;

    if (!reason.isEmpty()) {
        emit logMessage(QString("[SESSION] Closing: %1").arg(reason));
    }

    if (m_clientSocket) {
        m_clientSocket->disconnect(this);
        m_clientSocket->close();
    }
    if (m_remoteSocket) {
        m_remoteSocket->disconnect(this);
        m_remoteSocket->close();
    }
    if (m_udpLocalSocket) {
        m_udpLocalSocket->disconnect(this);
        m_udpLocalSocket->close();
    }
    if (m_udpRemoteSocket) {
        m_udpRemoteSocket->disconnect(this);
        m_udpRemoteSocket->close();
    }

    emit sessionClosed();
    deleteLater();
}

}
