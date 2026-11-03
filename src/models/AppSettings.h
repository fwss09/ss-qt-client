#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>

namespace Shadowsocks {

class AppSettings : public QObject {
    Q_OBJECT

public:
    explicit AppSettings(QObject *parent = nullptr);

    quint16 localPort() const;
    void setLocalPort(quint16 port);

    QString localAddress() const;
    void setLocalAddress(const QString &addr);

    QString activeServerId() const;
    void setActiveServerId(const QString &id);

    bool autoConnect() const;
    void setAutoConnect(bool enable);

    bool systemProxy() const;
    void setSystemProxy(bool enable);

    bool globeGreenColor() const;
    void setGlobeGreenColor(bool enable);

    bool globeFilled() const;
    void setGlobeFilled(bool enable);

private:
    QSettings m_settings;
};

}

#endif
