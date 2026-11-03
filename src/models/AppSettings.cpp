#include "AppSettings.h"
#include <QStandardPaths>
#include <QDir>

namespace Shadowsocks {

AppSettings::AppSettings(QObject *parent)
    : QObject(parent),
      m_settings("ShadowsocksQt", "ssclient") {
}

quint16 AppSettings::localPort() const {
    return static_cast<quint16>(m_settings.value("localPort", 1080).toUInt());
}

void AppSettings::setLocalPort(quint16 port) {
    m_settings.setValue("localPort", port);
}

QString AppSettings::localAddress() const {
    return m_settings.value("localAddress", "127.0.0.1").toString();
}

void AppSettings::setLocalAddress(const QString &addr) {
    m_settings.setValue("localAddress", addr);
}

QString AppSettings::activeServerId() const {
    return m_settings.value("activeServerId", "").toString();
}

void AppSettings::setActiveServerId(const QString &id) {
    m_settings.setValue("activeServerId", id);
}

bool AppSettings::autoConnect() const {
    return m_settings.value("autoConnect", false).toBool();
}

void AppSettings::setAutoConnect(bool enable) {
    m_settings.setValue("autoConnect", enable);
}

bool AppSettings::systemProxy() const {
    return m_settings.value("systemProxy", false).toBool();
}

void AppSettings::setSystemProxy(bool enable) {
    m_settings.setValue("systemProxy", enable);
}

bool AppSettings::globeGreenColor() const {
    return m_settings.value("globeGreenColor", true).toBool();
}

void AppSettings::setGlobeGreenColor(bool enable) {
    m_settings.setValue("globeGreenColor", enable);
}

bool AppSettings::globeFilled() const {
    return m_settings.value("globeFilled", true).toBool();
}

void AppSettings::setGlobeFilled(bool enable) {
    m_settings.setValue("globeFilled", enable);
}

}
