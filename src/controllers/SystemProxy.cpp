#include "SystemProxy.h"
#include <QProcess>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QFile>
#include <QDir>

namespace Shadowsocks {

static QString scriptPath() {
    QString appDir = QCoreApplication::applicationDirPath();

    QString p1 = appDir + "/../scripts/vpn-route.sh";
    if (QFile::exists(p1)) return QDir(p1).canonicalPath();
    QString p2 = appDir + "/scripts/vpn-route.sh";
    if (QFile::exists(p2)) return QDir(p2).canonicalPath();
    QString p3 = QDir::currentPath() + "/scripts/vpn-route.sh";
    if (QFile::exists(p3)) return QDir(p3).canonicalPath();
    return p1;
}

SystemProxy::SystemProxy(QObject *parent)
    : QObject(parent) {
}

bool SystemProxy::hasCommand(const QString &cmd) {
    return !QStandardPaths::findExecutable(cmd).isEmpty();
}

bool SystemProxy::setSystemProxy(const QString &host, quint16 port) {
    bool applied = false;

    if (hasCommand("gsettings")) {
        QProcess::execute("gsettings", {"set", "org.gnome.system.proxy", "mode", "'manual'"});
        QProcess::execute("gsettings", {"set", "org.gnome.system.proxy.socks", "host", host});
        QProcess::execute("gsettings", {"set", "org.gnome.system.proxy.socks", "port", QString::number(port)});
        applied = true;
    }

    QString kwrite = hasCommand("kwriteconfig6") ? "kwriteconfig6" : (hasCommand("kwriteconfig5") ? "kwriteconfig5" : "");
    if (!kwrite.isEmpty()) {
        QProcess::execute(kwrite, {"--file", "kioslaverc", "--group", "Proxy Settings", "--key", "ProxyType", "1"});
        QProcess::execute(kwrite, {"--file", "kioslaverc", "--group", "Proxy Settings", "--key", "socksProxy",
                                   QString("socks://%1 %2").arg(host).arg(port)});
        if (hasCommand("dbus-send")) {
            QProcess::execute("dbus-send", {"--type=signal", "/KIO/Scheduler", "org.kde.KIO.Scheduler.reparseSlaveConfiguration", ""});
        }
        applied = true;
    }

    return applied;
}

bool SystemProxy::clearSystemProxy() {
    bool cleared = false;

    if (hasCommand("gsettings")) {
        QProcess::execute("gsettings", {"set", "org.gnome.system.proxy", "mode", "'none'"});
        cleared = true;
    }

    QString kwrite = hasCommand("kwriteconfig6") ? "kwriteconfig6" : (hasCommand("kwriteconfig5") ? "kwriteconfig5" : "");
    if (!kwrite.isEmpty()) {
        QProcess::execute(kwrite, {"--file", "kioslaverc", "--group", "Proxy Settings", "--key", "ProxyType", "0"});
        if (hasCommand("dbus-send")) {
            QProcess::execute("dbus-send", {"--type=signal", "/KIO/Scheduler", "org.kde.KIO.Scheduler.reparseSlaveConfiguration", ""});
        }
        cleared = true;
    }

    return cleared;
}

QString SystemProxy::getShellExportCommand(const QString &host, quint16 port) {
    return QString("export ALL_PROXY=\"socks5h://%1:%2\" http_proxy=\"socks5h://%1:%2\" https_proxy=\"socks5h://%1:%2\"")
            .arg(host).arg(port);
}

bool SystemProxy::startTunMode(const QString &serverHost, quint16 socksPort) {
    QString script = scriptPath();
    if (!QFile::exists(script)) return false;

    QString authCmd = hasCommand("pkexec") ? "pkexec" : (hasCommand("sudo") ? "sudo" : "");
    if (authCmd.isEmpty()) return false;

    int exitCode = QProcess::execute(authCmd, {script, "start", serverHost, QString::number(socksPort)});
    return exitCode == 0;
}

bool SystemProxy::stopTunMode() {
    QString script = scriptPath();
    if (!QFile::exists(script)) return false;

    QString authCmd = hasCommand("pkexec") ? "pkexec" : (hasCommand("sudo") ? "sudo" : "");
    if (authCmd.isEmpty()) return false;

    int exitCode = QProcess::execute(authCmd, {script, "stop"});
    return exitCode == 0;
}

bool SystemProxy::isTunModeActive() {
    QString script = scriptPath();
    if (!QFile::exists(script)) return false;

    QProcess proc;
    proc.start(script, {"status"});
    if (!proc.waitForFinished(1000)) return false;

    return proc.readAllStandardOutput().trimmed() == "active";
}

}
