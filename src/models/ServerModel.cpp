#include "ServerModel.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFileInfo>
#include <QDir>

namespace Shadowsocks {

ServerModel::ServerModel(QObject *parent)
    : QAbstractListModel(parent) {
}

int ServerModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return m_servers.size();
}

QVariant ServerModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_servers.size()) {
        return QVariant();
    }

    const ServerConfig &cfg = m_servers[index.row()];

    switch (role) {
    case IdRole:
        return cfg.id;
    case NameRole:
        return cfg.name;
    case HostRole:
        return cfg.host;
    case PortRole:
        return cfg.port;
    case PasswordRole:
        return cfg.password;
    case MethodRole:
        return cfg.method;
    case PingRole:
        return cfg.ping;
    case FormattedAddressRole:
        return QString("%1:%2").arg(cfg.host).arg(cfg.port);
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ServerModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[HostRole] = "host";
    roles[PortRole] = "port";
    roles[PasswordRole] = "password";
    roles[MethodRole] = "method";
    roles[PingRole] = "ping";
    roles[FormattedAddressRole] = "formattedAddress";
    return roles;
}

void ServerModel::addServer(const ServerConfig &config) {
    beginInsertRows(QModelIndex(), m_servers.size(), m_servers.size());
    m_servers.append(config);
    endInsertRows();
}

void ServerModel::updateServer(int index, const ServerConfig &config) {
    if (index < 0 || index >= m_servers.size()) return;
    m_servers[index] = config;
    emit dataChanged(createIndex(index, 0), createIndex(index, 0));
}

void ServerModel::removeServer(int index) {
    if (index < 0 || index >= m_servers.size()) return;
    beginRemoveRows(QModelIndex(), index, index);
    m_servers.removeAt(index);
    endRemoveRows();
}

ServerConfig ServerModel::getServer(int index) const {
    if (index < 0 || index >= m_servers.size()) return ServerConfig();
    return m_servers[index];
}

int ServerModel::findServerIndexById(const QString &id) const {
    for (int i = 0; i < m_servers.size(); ++i) {
        if (m_servers[i].id == id) {
            return i;
        }
    }
    return -1;
}

void ServerModel::setPing(const QString &serverId, int pingMs) {
    int idx = findServerIndexById(serverId);
    if (idx != -1) {
        m_servers[idx].ping = pingMs;
        emit dataChanged(createIndex(idx, 0), createIndex(idx, 0), {PingRole});
    }
}

bool ServerModel::loadFromJson(const QString &filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) return false;

    beginResetModel();
    m_servers.clear();
    QJsonArray arr = doc.array();
    for (const auto &val : arr) {
        if (val.isObject()) {
            m_servers.append(ServerConfig::fromJson(val.toObject()));
        }
    }
    endResetModel();
    return true;
}

bool ServerModel::saveToJson(const QString &filePath) const {
    QFileInfo fi(filePath);
    QDir dir = fi.dir();
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QJsonArray arr;
    for (const auto &cfg : m_servers) {
        arr.append(cfg.toJson());
    }

    QJsonDocument doc(arr);
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return false;
    }

    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    return true;
}

}
