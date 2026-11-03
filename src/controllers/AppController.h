#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include <QStringList>
#include <QMap>
#include <QNetworkAccessManager>
#include "core/ShadowsocksServer.h"
#include "core/TrafficMeter.h"
#include "core/PingService.h"
#include "models/ServerModel.h"
#include "models/AppSettings.h"

namespace Shadowsocks {

class AppController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool isConnected READ isConnected NOTIFY stateChanged)
    Q_PROPERTY(bool isConnecting READ isConnecting NOTIFY stateChanged)
    Q_PROPERTY(int activeServerIndex READ activeServerIndex NOTIFY activeServerChanged)
    Q_PROPERTY(QString activeServerName READ activeServerName NOTIFY activeServerChanged)
    Q_PROPERTY(QString activeServerAddress READ activeServerAddress NOTIFY activeServerChanged)
    Q_PROPERTY(QString activeServerMethod READ activeServerMethod NOTIFY activeServerChanged)
    Q_PROPERTY(int activeServerPing READ activeServerPing NOTIFY activeServerChanged)
    Q_PROPERTY(quint16 localSocksPort READ localSocksPort WRITE setLocalSocksPort NOTIFY settingsChanged)
    Q_PROPERTY(bool vpnModeActive READ vpnModeActive NOTIFY stateChanged)
    Q_PROPERTY(QString shellExportCommand READ shellExportCommand NOTIFY settingsChanged)
    Q_PROPERTY(QStringList logs READ logs NOTIFY logsUpdated)
    Q_PROPERTY(ServerModel* serverModel READ serverModel CONSTANT)
    Q_PROPERTY(TrafficMeter* trafficMeter READ trafficMeter CONSTANT)
    Q_PROPERTY(int connectionCount READ connectionCount NOTIFY connectionCountChanged)
    Q_PROPERTY(QString userCity READ userCity NOTIFY userLocationChanged)
    Q_PROPERTY(QString userCountry READ userCountry NOTIFY userLocationChanged)
    Q_PROPERTY(qreal userLat READ userLat NOTIFY userLocationChanged)
    Q_PROPERTY(qreal userLon READ userLon NOTIFY userLocationChanged)
    Q_PROPERTY(QString serverCity READ serverCity NOTIFY serverLocationChanged)
    Q_PROPERTY(QString serverCountry READ serverCountry NOTIFY serverLocationChanged)
    Q_PROPERTY(qreal serverLat READ serverLat NOTIFY serverLocationChanged)
    Q_PROPERTY(qreal serverLon READ serverLon NOTIFY serverLocationChanged)
    Q_PROPERTY(bool globeGreenColor READ globeGreenColor WRITE setGlobeGreenColor NOTIFY globeStyleChanged)
    Q_PROPERTY(bool globeFilled READ globeFilled WRITE setGlobeFilled NOTIFY globeStyleChanged)

public:
    explicit AppController(QObject *parent = nullptr);
    ~AppController() override;

    bool isConnected() const { return m_isConnected; }
    bool isConnecting() const { return m_isConnecting; }
    int activeServerIndex() const { return m_activeServerIndex; }
    QString activeServerName() const;
    QString activeServerAddress() const;
    QString activeServerMethod() const;
    int activeServerPing() const;
    quint16 localSocksPort() const { return m_settings.localPort(); }
    bool vpnModeActive() const { return m_vpnModeActive; }
    QString shellExportCommand() const;
    QStringList logs() const { return m_logs; }
    ServerModel* serverModel() { return &m_serverModel; }
    TrafficMeter* trafficMeter() { return &m_trafficMeter; }
    int connectionCount() const { return m_connectionCount; }

    QString userCity() const { return m_userCity; }
    QString userCountry() const { return m_userCountry; }
    qreal userLat() const { return m_userLat; }
    qreal userLon() const { return m_userLon; }

    QString serverCity() const { return m_serverCity; }
    QString serverCountry() const { return m_serverCountry; }
    qreal serverLat() const { return m_serverLat; }
    qreal serverLon() const { return m_serverLon; }

    bool globeGreenColor() const { return m_settings.globeGreenColor(); }
    bool globeFilled() const { return m_settings.globeFilled(); }

    Q_INVOKABLE void setGlobeGreenColor(bool enable);
    Q_INVOKABLE void setGlobeFilled(bool enable);

    Q_INVOKABLE void toggleConnect();
    Q_INVOKABLE void connectToServer(int index);
    Q_INVOKABLE void disconnectFromServer();

    Q_INVOKABLE void addServer(const QString &name, const QString &host, int port, const QString &password, const QString &method);
    Q_INVOKABLE void editServer(int index, const QString &name, const QString &host, int port, const QString &password, const QString &method);
    Q_INVOKABLE void removeServer(int index);

    Q_INVOKABLE bool importFromUrl(const QString &url);
    Q_INVOKABLE QString getServerSsUrl(int index);

    Q_INVOKABLE void pingServer(int index);
    Q_INVOKABLE void pingAllServers();

    Q_INVOKABLE void setSystemProxy(bool enable);
    Q_INVOKABLE void setLocalSocksPort(int port);
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void copyToClipboard(const QString &text);

signals:
    void stateChanged();
    void activeServerChanged();
    void settingsChanged();
    void vpnModeChanged();
    void logsUpdated();
    void connectionCountChanged();
    void toastRequested(const QString &message);
    void userLocationChanged();
    void serverLocationChanged();
    void globeStyleChanged();

private slots:
    void onPingResult(const QString &serverId, int latencyMs);
    void onServerLog(const QString &msg);
    void onTraffic(quint64 bytesIn, quint64 bytesOut);
    void onServerError(const QString &error);
    void onConnectionCountChanged(int count);

private:
    void appendLog(const QString &msg);
    QString configFilePath() const;
    void fetchUserGeoLocation();
    void fetchServerGeoLocation(const QString &host);

    ShadowsocksServer m_server;
    TrafficMeter m_trafficMeter;
    PingService m_pingService;
    ServerModel m_serverModel;
    AppSettings m_settings;

    struct GeoLocation {
        QString city;
        QString country;
        QString countryCode;
        qreal lat = 0.0;
        qreal lon = 0.0;
    };
    QMap<QString, GeoLocation> m_geoCache;
    QNetworkAccessManager *m_netManager = nullptr;

    QString m_userCity = "Kyiv";
    QString m_userCountry = "Ukraine";
    qreal m_userLat = 50.45;
    qreal m_userLon = 30.52;

    QString m_serverCity = "Council Bluffs";
    QString m_serverCountry = "United States";
    qreal m_serverLat = 41.26;
    qreal m_serverLon = -95.86;

    bool m_isConnected = false;
    bool m_isConnecting = false;
    bool m_vpnModeActive = false;
    int m_activeServerIndex = -1;
    int m_connectionCount = 0;
    QStringList m_logs;
};

}

#endif
