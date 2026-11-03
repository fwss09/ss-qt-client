#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QFileSystemWatcher>
#include <QDirIterator>
#include <QTimer>
#include <QKeyEvent>
#include <QFile>
#include <QFileInfo>
#include <QDebug>
#include "controllers/MobileAppController.h"

#ifndef Q_OS_ANDROID
namespace {

class MobileQmlHotReloader : public QObject {
public:
    MobileQmlHotReloader(QQmlApplicationEngine *engine, const QUrl &mainUrl, const QString &watchDir, QObject *parent = nullptr)
        : QObject(parent), m_engine(engine), m_mainUrl(mainUrl), m_watchDir(watchDir) {
        m_debounceTimer.setSingleShot(true);
        m_debounceTimer.setInterval(150);
        connect(&m_debounceTimer, &QTimer::timeout, this, &MobileQmlHotReloader::doReload);

        if (!m_watchDir.isEmpty() && QDir(m_watchDir).exists()) {
            setupWatcher();
        }
    }

    bool eventFilter(QObject *obj, QEvent *event) override {
        if (event->type() == QEvent::KeyPress) {
            auto *keyEvent = static_cast<QKeyEvent*>(event);
            if (keyEvent->key() == Qt::Key_F5 || (keyEvent->modifiers() & Qt::ControlModifier && keyEvent->key() == Qt::Key_R)) {
                qDebug() << "[MOBILE HOT-RELOAD] Manual reload triggered (F5 / Ctrl+R)";
                m_debounceTimer.start();
                return true;
            }
        }
        return QObject::eventFilter(obj, event);
    }

private:
    void setupWatcher() {
        QDirIterator it(m_watchDir, QStringList() << "*.qml" << "*.js", QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            QString filePath = it.next();
            m_watcher.addPath(filePath);
        }
        connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
            qDebug() << "[MOBILE HOT-RELOAD] Detected change in:" << path;
            m_watcher.addPath(path); // Re-add for atomic editor saves
            m_debounceTimer.start();
        });
    }

    void doReload() {
        qDebug() << "[MOBILE HOT-RELOAD] Live-reloading mobile UI from:" << m_mainUrl.toLocalFile();
        const auto rootObjects = m_engine->rootObjects();
        for (auto *obj : rootObjects) {
            delete obj;
        }
        m_engine->clearComponentCache();
        m_engine->load(m_mainUrl);
    }

    QQmlApplicationEngine *m_engine;
    QUrl m_mainUrl;
    QString m_watchDir;
    QFileSystemWatcher m_watcher;
    QTimer m_debounceTimer;
};

} // namespace
#endif

#ifdef Q_OS_ANDROID
#include <android/log.h>
static void androidLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    Q_UNUSED(context)
    int prio = ANDROID_LOG_INFO;
    if (type == QtWarningMsg) prio = ANDROID_LOG_WARN;
    else if (type == QtCriticalMsg || type == QtFatalMsg) prio = ANDROID_LOG_ERROR;
    __android_log_print(prio, "SS_MOBILE", "%s", qPrintable(msg));
}
#endif

int main(int argc, char *argv[]) {
#ifdef Q_OS_ANDROID
    qInstallMessageHandler(androidLogHandler);
#endif
    QGuiApplication app(argc, argv);
    app.setApplicationName("Shadowsocks Mobile");
    app.setOrganizationName("Shadowsocks");
    app.setApplicationVersion("1.0.0");

    QQmlApplicationEngine engine;

    Shadowsocks::MobileAppController controller;
    engine.rootContext()->setContextProperty("appController", &controller);

#ifdef Q_OS_ANDROID
    const QUrl mainUrl("qrc:/src/ui/qml/MainMobile.qml");
    qDebug() << "[MOBILE APP] Loaded from embedded resource on Android:" << mainUrl;
#else
    QStringList candidates = {
        app.applicationDirPath() + "/../src/ui/qml/MainMobile.qml",
        app.applicationDirPath() + "/mobile/src/ui/qml/MainMobile.qml",
        app.applicationDirPath() + "/src/ui/qml/MainMobile.qml",
        QDir::currentPath() + "/mobile/src/ui/qml/MainMobile.qml",
        QDir::currentPath() + "/src/ui/qml/MainMobile.qml"
    };

    QString diskQml;
    for (const auto &c : candidates) {
        if (QFile::exists(c)) {
            diskQml = QFileInfo(c).canonicalFilePath();
            break;
        }
    }

    QUrl mainUrl;
    QString watchDir;
    if (!diskQml.isEmpty()) {
        mainUrl = QUrl::fromLocalFile(diskQml);
        watchDir = QFileInfo(diskQml).dir().path();
        qDebug() << "[MOBILE APP] Running in Live Hot-Reload mode from disk:" << mainUrl;
        qDebug() << "[MOBILE APP] Watching directory for live edits:" << watchDir;
    } else {
        mainUrl = QUrl("qrc:/src/ui/qml/MainMobile.qml");
        qDebug() << "[MOBILE APP] Loaded from embedded resource:" << mainUrl;
    }

    auto *reloader = new MobileQmlHotReloader(&engine, mainUrl, watchDir, &app);
    app.installEventFilter(reloader);
#endif

    engine.load(mainUrl);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML root object";
        return -1;
    }

    return app.exec();
}
