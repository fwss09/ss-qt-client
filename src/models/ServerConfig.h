#ifndef SERVERCONFIG_H
#define SERVERCONFIG_H

#include <QString>
#include <QJsonObject>

namespace Shadowsocks {

struct ServerConfig {
    QString id;
    QString name;
    QString host;
    quint16 port = 8388;
    QString password;
    QString method = "chacha20-poly1305";
    int ping = -1;

    QJsonObject toJson() const;
    static ServerConfig fromJson(const QJsonObject &obj);

    QString toSsUrl() const;
    static bool fromSsUrl(const QString &url, ServerConfig &out);
};

}

#endif
