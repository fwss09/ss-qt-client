#include "MobileAppController.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QUuid>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>

namespace Shadowsocks {

MobileAppController::MobileAppController(QObject *parent)
    : QObject(parent) {
    m_vpnBridge = AndroidVpnBridge::instance();

    connect(&m_server, &ShadowsocksServer::trafficTransferred, this, &MobileAppController::onTraffic);
    connect(&m_server, &ShadowsocksServer::logMessage, this, &MobileAppController::onServerLog);
    connect(&m_server, &ShadowsocksServer::serverError, this, &MobileAppController::onServerError);
    connect(&m_server, &ShadowsocksServer::connectionCountChanged, this, &MobileAppController::onConnectionCountChanged);

    connect(&m_pingService, &PingService::pingResult, this, &MobileAppController::onPingResult);
    connect(m_vpnBridge, &AndroidVpnBridge::vpnStateChanged, this, &MobileAppController::onVpnStateChanged);

    // Load server list from disk
    QString path = configFilePath();
    if (!m_serverModel.loadFromJson(path) || m_serverModel.rowCount() == 0) {
        ServerConfig sample;
        sample.id = "sample-server-1";
        sample.name = "Sample Cloud Server";
        sample.host = "198.51.100.1";
        sample.port = 8388;
        sample.password = "mypassword123";
        sample.method = "chacha20-poly1305";
        sample.ping = -1;
        m_serverModel.addServer(sample);
        m_serverModel.saveToJson(path);
    }

    // Restore active server from settings
    QString savedId = m_settings.activeServerId();
    int idx = m_serverModel.findServerIndexById(savedId);
    if (idx != -1) {
        m_activeServerIndex = idx;
    } else if (m_serverModel.rowCount() > 0) {
        m_activeServerIndex = 0;
    }

    m_netManager = new QNetworkAccessManager(this);
    fetchUserGeoLocation();
    if (m_activeServerIndex != -1) {
        fetchServerGeoLocation(m_serverModel.getServer(m_activeServerIndex).host);
    }

    appendLog(QString("[SYSTEM] Mobile client initialized. Config path: %1").arg(path));

    if (m_settings.autoConnect() && m_activeServerIndex != -1) {
        connectToServer(m_activeServerIndex);
    }
}

MobileAppController::~MobileAppController() {
    if (m_vpnBridge->isVpnActive()) {
        m_vpnBridge->stopVpnService();
    }
    if (m_server.isRunning()) {
        m_server.stopServer();
    }
}

QString MobileAppController::configFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(configDir);
    return configDir + "/servers.json";
}

QString MobileAppController::activeServerName() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        return m_serverModel.getServer(m_activeServerIndex).name;
    }
    return "No server selected";
}

QString MobileAppController::activeServerAddress() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        const auto &s = m_serverModel.getServer(m_activeServerIndex);
        return QString("%1:%2").arg(s.host).arg(s.port);
    }
    return "-";
}

QString MobileAppController::activeServerMethod() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        return m_serverModel.getServer(m_activeServerIndex).method;
    }
    return "-";
}

int MobileAppController::activeServerPing() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        return m_serverModel.getServer(m_activeServerIndex).ping;
    }
    return -1;
}

void MobileAppController::setLocalSocksPort(int port) {
    if (port > 0 && port < 65536 && port != m_settings.localPort()) {
        m_settings.setLocalPort(static_cast<quint16>(port));
        emit settingsChanged();
        appendLog(QString("[CONFIG] Local SOCKS5 port set to %1").arg(port));
    }
}

void MobileAppController::setGlobeGreenColor(bool enable) {
    if (m_settings.globeGreenColor() != enable) {
        m_settings.setGlobeGreenColor(enable);
        emit globeStyleChanged();
    }
}

void MobileAppController::setGlobeFilled(bool enable) {
    if (m_settings.globeFilled() != enable) {
        m_settings.setGlobeFilled(enable);
        emit globeStyleChanged();
    }
}

void MobileAppController::toggleConnect() {
    if (m_isConnected || m_isConnecting) {
        disconnectFromServer();
    } else {
        if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
            connectToServer(m_activeServerIndex);
        } else if (m_serverModel.rowCount() > 0) {
            connectToServer(0);
        } else {
            appendLog("[ERROR] No servers configured to connect to.");
            emit toastRequested("Please add a server first");
        }
    }
}

void MobileAppController::connectToServer(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;

    if (m_isConnected) {
        disconnectFromServer();
    }

    m_activeServerIndex = index;
    const auto &cfg = m_serverModel.getServer(index);
    m_settings.setActiveServerId(cfg.id);
    emit activeServerChanged();

    fetchServerGeoLocation(cfg.host);

    m_isConnecting = true;
    emit stateChanged();

    appendLog(QString("[APP] Connecting to %1 (%2:%3)...")
              .arg(cfg.name).arg(cfg.host).arg(cfg.port));

    QHostAddress bindAddr(QHostAddress::LocalHost);
    quint16 localPort = m_settings.localPort();

    bool ok = m_server.startServer(bindAddr, localPort, cfg.host, cfg.port, cfg.method, cfg.password);
    if (!ok) {
        m_isConnecting = false;
        m_isConnected = false;
        appendLog("[APP] Failed to start local SOCKS5 proxy engine");
        emit toastRequested("Failed to start proxy");
        emit stateChanged();
        return;
    }

    m_trafficMeter.reset();
    appendLog(QString("[APP] SOCKS5 engine running on 127.0.0.1:%1").arg(localPort));

    // Request Android VPN
    m_vpnBridge->startVpnService(cfg.host, localPort);
}

void MobileAppController::disconnectFromServer() {
    appendLog("[VPN] Disconnecting VPN...");
    m_isConnecting = true;
    emit stateChanged();

    m_vpnBridge->stopVpnService();
    m_server.stopServer();

    m_isConnected = false;
    m_isConnecting = false;
    appendLog("[VPN] VPN session disconnected");
    emit stateChanged();
    emit toastRequested("VPN Disconnected");
}

void MobileAppController::onVpnStateChanged(bool active) {
    m_isConnecting = false;
    m_isConnected = active;
    if (active) {
        appendLog("[VPN] Android system VPN is ACTIVE: All traffic routed through Shadowsocks");
        emit toastRequested("VPN Connected");
    }
    emit stateChanged();
}

void MobileAppController::addServer(const QString &name, const QString &host, int port, const QString &password, const QString &method) {
    ServerConfig cfg;
    cfg.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    cfg.name = name.trimmed().isEmpty() ? QString("%1:%2").arg(host).arg(port) : name.trimmed();
    cfg.host = host.trimmed();
    cfg.port = static_cast<quint16>(port);
    cfg.password = password;
    cfg.method = method;
    cfg.ping = -1;

    m_serverModel.addServer(cfg);
    m_serverModel.saveToJson(configFilePath());

    if (m_activeServerIndex == -1) {
        m_activeServerIndex = 0;
        fetchServerGeoLocation(cfg.host);
        emit activeServerChanged();
    }

    appendLog(QString("[CONFIG] Server added: %1 (%2:%3)").arg(cfg.name).arg(cfg.host).arg(cfg.port));
    emit toastRequested(QString("Server '%1' added").arg(cfg.name));

    pingServer(m_serverModel.rowCount() - 1);
}

void MobileAppController::editServer(int index, const QString &name, const QString &host, int port, const QString &password, const QString &method) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;

    ServerConfig cfg = m_serverModel.getServer(index);
    cfg.name = name.trimmed().isEmpty() ? QString("%1:%2").arg(host).arg(port) : name.trimmed();
    cfg.host = host.trimmed();
    cfg.port = static_cast<quint16>(port);
    cfg.password = password;
    cfg.method = method;

    m_serverModel.updateServer(index, cfg);
    m_serverModel.saveToJson(configFilePath());

    if (index == m_activeServerIndex) {
        fetchServerGeoLocation(cfg.host);
        emit activeServerChanged();
    }

    appendLog(QString("[CONFIG] Server updated: %1").arg(cfg.name));
    emit toastRequested("Server updated");
}

void MobileAppController::removeServer(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;

    QString name = m_serverModel.getServer(index).name;
    if (index == m_activeServerIndex && m_isConnected) {
        disconnectFromServer();
    }

    m_serverModel.removeServer(index);
    m_serverModel.saveToJson(configFilePath());

    if (m_activeServerIndex >= m_serverModel.rowCount()) {
        m_activeServerIndex = m_serverModel.rowCount() - 1;
    }
    emit activeServerChanged();

    appendLog(QString("[CONFIG] Server removed: %1").arg(name));
    emit toastRequested("Server removed");
}

bool MobileAppController::importFromUrl(const QString &url) {
    ServerConfig cfg;
    if (!ServerConfig::fromSsUrl(url.trimmed(), cfg)) {
        appendLog("[ERROR] Failed to parse Shadowsocks URI");
        emit toastRequested("Invalid ss:// URI");
        return false;
    }

    cfg.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    cfg.ping = -1;
    m_serverModel.addServer(cfg);
    m_serverModel.saveToJson(configFilePath());

    appendLog(QString("[CONFIG] Imported server: %1 (%2:%3)").arg(cfg.name).arg(cfg.host).arg(cfg.port));
    emit toastRequested(QString("Imported: %1").arg(cfg.name));

    pingServer(m_serverModel.rowCount() - 1);
    return true;
}

QString MobileAppController::getServerSsUrl(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return QString();
    return m_serverModel.getServer(index).toSsUrl();
}

void MobileAppController::pingServer(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;
    const auto &cfg = m_serverModel.getServer(index);
    m_pingService.pingServer(cfg.id, cfg.host, cfg.port);
}

void MobileAppController::pingAllServers() {
    for (int i = 0; i < m_serverModel.rowCount(); ++i) {
        pingServer(i);
    }
    emit toastRequested("Testing latency for all servers...");
}

void MobileAppController::clearLogs() {
    m_logs.clear();
    emit logsUpdated();
}

void MobileAppController::copyToClipboard(const QString &text) {
    QClipboard *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(text);
        emit toastRequested("Copied to clipboard");
    }
}

void MobileAppController::onPingResult(const QString &serverId, int latencyMs) {
    m_serverModel.setPing(serverId, latencyMs);
    int idx = m_serverModel.findServerIndexById(serverId);
    if (idx != -1 && idx == m_activeServerIndex) {
        emit activeServerChanged();
    }
}

void MobileAppController::onServerLog(const QString &msg) {
    appendLog(msg);
}

void MobileAppController::onTraffic(quint64 bytesIn, quint64 bytesOut) {
    m_trafficMeter.addBytes(bytesIn, bytesOut);
}

void MobileAppController::onServerError(const QString &error) {
    appendLog(QString("[ERROR] Server error: %1").arg(error));
    emit toastRequested(QString("Error: %1").arg(error));
}

void MobileAppController::onConnectionCountChanged(int count) {
    m_connectionCount = count;
    emit connectionCountChanged();
}

void MobileAppController::appendLog(const QString &msg) {
    QString time = QDateTime::currentDateTime().toString("HH:mm:ss");
    m_logs.prepend(QString("[%1] %2").arg(time, msg));
    if (m_logs.size() > 500) {
        m_logs.removeLast();
    }
    emit logsUpdated();
}

void MobileAppController::fetchUserGeoLocation() {
    if (!m_netManager) return;
    QNetworkRequest req(QUrl("http://ip-api.com/json/?fields=status,country,city,lat,lon"));
    req.setHeader(QNetworkRequest::UserAgentHeader, "ShadowsocksClient/1.0");
    auto *reply = m_netManager->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            auto doc = QJsonDocument::fromJson(reply->readAll());
            if (doc.isObject()) {
                auto obj = doc.object();
                if (obj.value("status").toString() == "success") {
                    m_userCity = obj.value("city").toString();
                    m_userCountry = obj.value("country").toString();
                    m_userLat = obj.value("lat").toDouble();
                    m_userLon = obj.value("lon").toDouble();
                    emit userLocationChanged();
                }
            }
        }
    });
}

void MobileAppController::fetchServerGeoLocation(const QString &host) {
    if (!m_netManager || host.isEmpty()) return;
    QUrl url(QString("http://ip-api.com/json/%1?fields=status,country,city,lat,lon").arg(host));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, "ShadowsocksClient/1.0");
    auto *reply = m_netManager->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            auto doc = QJsonDocument::fromJson(reply->readAll());
            if (doc.isObject()) {
                auto obj = doc.object();
                if (obj.value("status").toString() == "success") {
                    m_serverCity = obj.value("city").toString();
                    m_serverCountry = obj.value("country").toString();
                    m_serverLat = obj.value("lat").toDouble();
                    m_serverLon = obj.value("lon").toDouble();
                    emit serverLocationChanged();
                }
            }
        }
    });
}

} // namespace Shadowsocks
