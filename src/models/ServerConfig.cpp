#include "ServerConfig.h"
#include <QUuid>
#include <QUrl>
#include <QRegularExpression>

namespace Shadowsocks {

QJsonObject ServerConfig::toJson() const {
    QJsonObject obj;
    obj["id"] = id;
    obj["name"] = name;
    obj["host"] = host;
    obj["port"] = static_cast<int>(port);
    obj["password"] = password;
    obj["method"] = method;
    return obj;
}

ServerConfig ServerConfig::fromJson(const QJsonObject &obj) {
    ServerConfig cfg;
    cfg.id = obj["id"].toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
    cfg.name = obj["name"].toString("SS Server");
    cfg.host = obj["host"].toString();
    cfg.port = static_cast<quint16>(obj["port"].toInt(8388));
    cfg.password = obj["password"].toString();
    cfg.method = obj["method"].toString("chacha20-poly1305");
    cfg.ping = -1;
    return cfg;
}

QString ServerConfig::toSsUrl() const {

    QString userinfo = QString("%1:%2").arg(method, password);
    QByteArray b64 = userinfo.toUtf8().toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals);
    QString tag = QUrl::toPercentEncoding(name);
    return QString("ss://%1@%2:%3#%4").arg(QString::fromLatin1(b64), host).arg(port).arg(tag);
}

static QByteArray safeBase64Decode(QString s) {
    s = s.trimmed();

    s.replace('-', '+').replace('_', '/');
    while (s.size() % 4 != 0) {
        s.append('=');
    }
    return QByteArray::fromBase64(s.toUtf8());
}

bool ServerConfig::fromSsUrl(const QString &urlStr, ServerConfig &out) {
    QString trimmed = urlStr.trimmed();
    if (!trimmed.startsWith("ss://", Qt::CaseInsensitive)) {
        return false;
    }

    QString withoutScheme = trimmed.mid(5);

    QString tag;
    int hashIdx = withoutScheme.indexOf('#');
    if (hashIdx != -1) {
        tag = QUrl::fromPercentEncoding(withoutScheme.mid(hashIdx + 1).toUtf8());
        withoutScheme = withoutScheme.left(hashIdx);
    }

    int atIdx = withoutScheme.lastIndexOf('@');
    if (atIdx != -1) {

        QString userinfoB64 = withoutScheme.left(atIdx);
        QString hostPort = withoutScheme.mid(atIdx + 1);

        QByteArray decodedUserinfo = safeBase64Decode(userinfoB64);
        QString userinfoStr = QString::fromUtf8(decodedUserinfo);
        int colonIdx = userinfoStr.indexOf(':');
        if (colonIdx == -1) return false;

        out.method = userinfoStr.left(colonIdx).trimmed();
        out.password = userinfoStr.mid(colonIdx + 1);

        int portColonIdx = hostPort.lastIndexOf(':');
        if (portColonIdx == -1) return false;

        out.host = hostPort.left(portColonIdx).trimmed();

        if (out.host.startsWith('[') && out.host.endsWith(']')) {
            out.host = out.host.mid(1, out.host.size() - 2);
        }
        out.port = static_cast<quint16>(hostPort.mid(portColonIdx + 1).toInt());
    } else {

        QByteArray decoded = safeBase64Decode(withoutScheme);
        QString fullStr = QString::fromUtf8(decoded);

        int atLegacy = fullStr.lastIndexOf('@');
        if (atLegacy == -1) return false;

        QString userinfo = fullStr.left(atLegacy);
        QString hostPort = fullStr.mid(atLegacy + 1);

        int userColon = userinfo.indexOf(':');
        if (userColon == -1) return false;

        out.method = userinfo.left(userColon).trimmed();
        out.password = userinfo.mid(userColon + 1);

        int portColon = hostPort.lastIndexOf(':');
        if (portColon == -1) return false;

        out.host = hostPort.left(portColon).trimmed();
        out.port = static_cast<quint16>(hostPort.mid(portColon + 1).toInt());
    }

    if (out.host.isEmpty() || out.port == 0 || out.method.isEmpty() || out.password.isEmpty()) {
        return false;
    }

    out.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    out.name = tag.isEmpty() ? QString("%1:%2").arg(out.host).arg(out.port) : tag;
    out.ping = -1;
    return true;
}

}
