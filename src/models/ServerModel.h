#ifndef SERVERMODEL_H
#define SERVERMODEL_H

#include <QAbstractListModel>
#include <QList>
#include "ServerConfig.h"

namespace Shadowsocks {

class ServerModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum ServerRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        HostRole,
        PortRole,
        PasswordRole,
        MethodRole,
        PingRole,
        FormattedAddressRole
    };

    explicit ServerModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addServer(const ServerConfig &config);
    void updateServer(int index, const ServerConfig &config);
    void removeServer(int index);
    ServerConfig getServer(int index) const;
    int findServerIndexById(const QString &id) const;

    void setPing(const QString &serverId, int pingMs);

    bool loadFromJson(const QString &filePath);
    bool saveToJson(const QString &filePath) const;

    const QList<ServerConfig>& servers() const { return m_servers; }

private:
    QList<ServerConfig> m_servers;
};

}

#endif
