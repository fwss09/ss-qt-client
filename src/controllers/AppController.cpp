#include "AppController.h"
#include "SystemProxy.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QThread>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimeZone>

namespace Shadowsocks {

AppController::AppController(QObject *parent)
    : QObject(parent) {
    connect(&m_server, &ShadowsocksServer::trafficTransferred, this, &AppController::onTraffic);
    connect(&m_server, &ShadowsocksServer::logMessage, this, &AppController::onServerLog);
    connect(&m_server, &ShadowsocksServer::serverError, this, &AppController::onServerError);
    connect(&m_server, &ShadowsocksServer::connectionCountChanged, this, &AppController::onConnectionCountChanged);

    connect(&m_pingService, &PingService::pingResult, this, &AppController::onPingResult);

    m_vpnModeActive = SystemProxy::isTunModeActive();

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

    appendLog(QString("[SYSTEM] Application initialized. Config path: %1").arg(path));

    if (m_settings.autoConnect() && m_activeServerIndex != -1) {
        connectToServer(m_activeServerIndex);
    }
}

AppController::~AppController() {
    if (m_vpnModeActive) {
        SystemProxy::stopTunMode();
        m_vpnModeActive = false;
    }
    if (m_server.isRunning()) {
        m_server.stopServer();
    }
    if (m_settings.systemProxy()) {
        SystemProxy::clearSystemProxy();
    }
}

QString AppController::configFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    return configDir + "/servers.json";
}

QString AppController::activeServerName() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        return m_serverModel.getServer(m_activeServerIndex).name;
    }
    return "No server selected";
}

QString AppController::activeServerAddress() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        const auto &s = m_serverModel.getServer(m_activeServerIndex);
        return QString("%1:%2").arg(s.host).arg(s.port);
    }
    return "-";
}

QString AppController::activeServerMethod() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        return m_serverModel.getServer(m_activeServerIndex).method;
    }
    return "-";
}

int AppController::activeServerPing() const {
    if (m_activeServerIndex >= 0 && m_activeServerIndex < m_serverModel.rowCount()) {
        return m_serverModel.getServer(m_activeServerIndex).ping;
    }
    return -1;
}

QString AppController::shellExportCommand() const {
    return SystemProxy::getShellExportCommand("127.0.0.1", localSocksPort());
}

void AppController::toggleConnect() {
    if (m_isConnected) {
        disconnectFromServer();
    } else {
        if (m_activeServerIndex != -1) {
            connectToServer(m_activeServerIndex);
        } else if (m_serverModel.rowCount() > 0) {
            connectToServer(0);
        } else {
            emit toastRequested("Please add a server first!");
        }
    }
}

void AppController::connectToServer(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;

    if (m_isConnected) {
        disconnectFromServer();
    }

    m_activeServerIndex = index;
    ServerConfig cfg = m_serverModel.getServer(index);
    m_settings.setActiveServerId(cfg.id);
    fetchServerGeoLocation(cfg.host);

    m_isConnecting = true;
    emit stateChanged();
    emit activeServerChanged();

    appendLog(QString("[APP] Starting connection to '%1' (%2:%3)...")
              .arg(cfg.name).arg(cfg.host).arg(cfg.port));

    QHostAddress bindAddr(m_settings.localAddress());
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
    appendLog(QString("[APP] Shadowsocks engine running on 127.0.0.1:%1").arg(localPort));
    appendLog("[VPN] Requesting administrative authorization for system routing (TUN)...");

    auto *thread = QThread::create([this, cfg, localPort]() {
        bool tunOk = SystemProxy::startTunMode(cfg.host, localPort);

        QMetaObject::invokeMethod(this, [this, cfg, tunOk]() {
            m_isConnecting = false;
            if (tunOk) {
                m_isConnected = true;
                m_vpnModeActive = true;
                appendLog("[VPN] System-wide VPN Mode ACTIVE: All system traffic routed through Shadowsocks!");
                emit toastRequested(QString("VPN Connected: %1").arg(cfg.name));
            } else {
                appendLog("[VPN] Authorization cancelled. VPN cannot start without kernel routing permissions.");
                m_server.stopServer();
                m_isConnected = false;
                m_vpnModeActive = false;
                emit toastRequested("Authorization cancelled");
            }
            emit stateChanged();
        }, Qt::QueuedConnection);
    });

    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    thread->start();
}

void AppController::disconnectFromServer() {
    if (!m_isConnected && !m_server.isRunning() && !m_vpnModeActive) return;

    appendLog("[VPN] Disconnecting VPN...");
    m_isConnecting = true;
    emit stateChanged();

    bool stopTun = m_vpnModeActive;

    auto *thread = QThread::create([this, stopTun]() {
        if (stopTun) {
            SystemProxy::stopTunMode();
        }

        QMetaObject::invokeMethod(this, [this]() {
            m_vpnModeActive = false;
            m_server.stopServer();
            m_isConnected = false;
            m_isConnecting = false;
            appendLog("[VPN] TUN mode deactivated");
            emit stateChanged();
            emit toastRequested("VPN Disconnected");
        }, Qt::QueuedConnection);
    });

    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    thread->start();
}

void AppController::addServer(const QString &name, const QString &host, int port, const QString &password, const QString &method) {
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

void AppController::editServer(int index, const QString &name, const QString &host, int port, const QString &password, const QString &method) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;

    ServerConfig cfg = m_serverModel.getServer(index);
    cfg.name = name.trimmed();
    cfg.host = host.trimmed();
    cfg.port = static_cast<quint16>(port);
    cfg.password = password;
    cfg.method = method;

    m_serverModel.updateServer(index, cfg);
    m_serverModel.saveToJson(configFilePath());

    if (m_activeServerIndex == index) {
        fetchServerGeoLocation(cfg.host);
        emit activeServerChanged();
    }

    appendLog(QString("[CONFIG] Server updated: %1").arg(cfg.name));
    emit toastRequested("Server updated");
}

void AppController::removeServer(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;

    if (m_isConnected && m_activeServerIndex == index) {
        disconnectFromServer();
    }

    QString name = m_serverModel.getServer(index).name;
    m_serverModel.removeServer(index);
    m_serverModel.saveToJson(configFilePath());

    if (m_activeServerIndex == index) {
        m_activeServerIndex = m_serverModel.rowCount() > 0 ? 0 : -1;
        if (m_activeServerIndex != -1) {
            fetchServerGeoLocation(m_serverModel.getServer(m_activeServerIndex).host);
        }
        emit activeServerChanged();
    } else if (m_activeServerIndex > index) {
        m_activeServerIndex--;
        fetchServerGeoLocation(m_serverModel.getServer(m_activeServerIndex).host);
        emit activeServerChanged();
    }

    appendLog(QString("[CONFIG] Server removed: %1").arg(name));
    emit toastRequested(QString("Server '%1' removed").arg(name));
}

bool AppController::importFromUrl(const QString &url) {
    ServerConfig cfg;
    if (!ServerConfig::fromSsUrl(url, cfg)) {
        appendLog("[CONFIG] Failed to parse Shadowsocks URI");
        emit toastRequested("Invalid Shadowsocks URL");
        return false;
    }

    m_serverModel.addServer(cfg);
    m_serverModel.saveToJson(configFilePath());

    if (m_activeServerIndex == -1) {
        m_activeServerIndex = 0;
        fetchServerGeoLocation(cfg.host);
        emit activeServerChanged();
    }

    appendLog(QString("[CONFIG] Imported server from URL: %1 (%2:%3)").arg(cfg.name).arg(cfg.host).arg(cfg.port));
    emit toastRequested(QString("Imported '%1'").arg(cfg.name));

    pingServer(m_serverModel.rowCount() - 1);
    return true;
}

QString AppController::getServerSsUrl(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return "";
    return m_serverModel.getServer(index).toSsUrl();
}

void AppController::pingServer(int index) {
    if (index < 0 || index >= m_serverModel.rowCount()) return;
    const ServerConfig &s = m_serverModel.getServer(index);
    m_pingService.pingServer(s.id, s.host, s.port);
}

void AppController::pingAllServers() {
    appendLog("[PING] Testing latency for all servers...");
    for (const ServerConfig &s : m_serverModel.servers()) {
        m_pingService.pingServer(s.id, s.host, s.port);
    }
}

void AppController::setSystemProxy(bool enable) {
    m_settings.setSystemProxy(enable);
    if (m_isConnected) {
        if (enable) {
            SystemProxy::setSystemProxy("127.0.0.1", localSocksPort());
            appendLog("[SYSTEM] System proxy enabled");
        } else {
            SystemProxy::clearSystemProxy();
            appendLog("[SYSTEM] System proxy disabled");
        }
    }
    emit settingsChanged();
}

void AppController::setLocalSocksPort(int port) {
    if (port <= 0 || port > 65535) return;
    m_settings.setLocalPort(static_cast<quint16>(port));
    emit settingsChanged();
}

void AppController::setGlobeGreenColor(bool enable) {
    if (m_settings.globeGreenColor() != enable) {
        m_settings.setGlobeGreenColor(enable);
        emit globeStyleChanged();
    }
}

void AppController::setGlobeFilled(bool enable) {
    if (m_settings.globeFilled() != enable) {
        m_settings.setGlobeFilled(enable);
        emit globeStyleChanged();
    }
}

void AppController::clearLogs() {
    m_logs.clear();
    emit logsUpdated();
}

void AppController::copyToClipboard(const QString &text) {
    QClipboard *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(text);
        emit toastRequested("Copied to clipboard");
    }
}

void AppController::onPingResult(const QString &serverId, int latencyMs) {
    m_serverModel.setPing(serverId, latencyMs);
    if (m_activeServerIndex != -1 && m_serverModel.getServer(m_activeServerIndex).id == serverId) {
        emit activeServerChanged();
    }
}

void AppController::onServerLog(const QString &msg) {
    appendLog(msg);
}

void AppController::onTraffic(quint64 bytesIn, quint64 bytesOut) {
    m_trafficMeter.addBytes(bytesIn, bytesOut);
}

void AppController::onServerError(const QString &error) {
    appendLog(QString("[ERROR] %1").arg(error));
    emit toastRequested(error);
}

void AppController::onConnectionCountChanged(int count) {
    m_connectionCount = count;
    emit connectionCountChanged();
}

void AppController::appendLog(const QString &msg) {
    QString timeStr = QDateTime::currentDateTime().toString("hh:mm:ss");
    QString formatted = QString("[%1] %2").arg(timeStr, msg);
    m_logs.append(formatted);
    if (m_logs.size() > 500) {
        m_logs.removeFirst();
    }
    emit logsUpdated();
}

void AppController::fetchUserGeoLocation() {

    QString tzId = QString::fromUtf8(QTimeZone::systemTimeZone().id());
    if (tzId.contains("Kyiv", Qt::CaseInsensitive)) {
        m_userCity = "Kyiv";
        m_userCountry = "Ukraine";
        m_userLat = 50.45;
        m_userLon = 30.52;
    } else if (tzId.contains("Warsaw", Qt::CaseInsensitive)) {
        m_userCity = "Warsaw";
        m_userCountry = "Poland";
        m_userLat = 52.23;
        m_userLon = 21.01;
    } else {
        m_userCity = "Kyiv";
        m_userCountry = "Ukraine";
        m_userLat = 50.45;
        m_userLon = 30.52;
    }
    emit userLocationChanged();

    QUrl url("http://ip-api.com/json/?fields=status,country,countryCode,city,lat,lon");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ssclient/1.0");

    QNetworkReply *reply = m_netManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                QJsonObject obj = doc.object();
                if (obj.value("status").toString() == "success") {
                    m_userCity = obj.value("city").toString();
                    m_userCountry = obj.value("country").toString();
                    m_userLat = obj.value("lat").toDouble();
                    m_userLon = obj.value("lon").toDouble();
                    emit userLocationChanged();
                    appendLog(QString("[GEO] User location resolved: %1, %2 (%3, %4)")
                                  .arg(m_userCity, m_userCountry)
                                  .arg(m_userLat).arg(m_userLon));
                }
            }
        }
    });
}

void AppController::fetchServerGeoLocation(const QString &host) {
    if (host.isEmpty()) return;

    if (m_geoCache.contains(host)) {
        const auto &g = m_geoCache[host];
        m_serverCity = g.city;
        m_serverCountry = g.country;
        m_serverLat = g.lat;
        m_serverLon = g.lon;
        emit serverLocationChanged();
        return;
    }

    if (host.startsWith("34.") || host.startsWith("35.")) {
        m_serverCity = "Council Bluffs";
        m_serverCountry = "United States";
        m_serverLat = 41.26;
        m_serverLon = -95.86;
    } else if (host.startsWith("104.") || host.startsWith("172.")) {
        m_serverCity = "San Francisco";
        m_serverCountry = "United States";
        m_serverLat = 37.77;
        m_serverLon = -122.42;
    } else if (host.startsWith("185.") || host.startsWith("194.")) {
        m_serverCity = "Frankfurt";
        m_serverCountry = "Germany";
        m_serverLat = 50.11;
        m_serverLon = 8.68;
    }
    emit serverLocationChanged();

    QUrl url(QString("http://ip-api.com/json/%1?fields=status,country,countryCode,city,lat,lon").arg(host));
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ssclient/1.0");

    QNetworkReply *reply = m_netManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, host]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                QJsonObject obj = doc.object();
                if (obj.value("status").toString() == "success") {
                    GeoLocation g;
                    g.city = obj.value("city").toString();
                    g.country = obj.value("country").toString();
                    g.countryCode = obj.value("countryCode").toString();
                    g.lat = obj.value("lat").toDouble();
                    g.lon = obj.value("lon").toDouble();
                    m_geoCache[host] = g;

                    if (activeServerAddress().startsWith(host)) {
                        m_serverCity = g.city;
                        m_serverCountry = g.country;
                        m_serverLat = g.lat;
                        m_serverLon = g.lon;
                        emit serverLocationChanged();
                        appendLog(QString("[GEO] Server location resolved: %1, %2 (%3, %4)")
                                      .arg(m_serverCity, m_serverCountry)
                                      .arg(m_serverLat).arg(m_serverLon));
                    }
                }
            }
        }
    });
}

}
