#ifndef SYSTEMPROXY_H
#define SYSTEMPROXY_H

#include <QObject>
#include <QString>

namespace Shadowsocks {

class SystemProxy : public QObject {
    Q_OBJECT

public:
    explicit SystemProxy(QObject *parent = nullptr);

    static bool setSystemProxy(const QString &host, quint16 port);
    static bool clearSystemProxy();
    static QString getShellExportCommand(const QString &host, quint16 port);

    static bool startTunMode(const QString &serverHost, quint16 socksPort);
    static bool stopTunMode();
    static bool isTunModeActive();

private:
    static bool hasCommand(const QString &cmd);
};

}

#endif
