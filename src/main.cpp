#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QIcon>
#include <QQuickWindow>
#include <QStyle>
#include <QFileSystemWatcher>
#include <QDirIterator>
#include <QKeyEvent>
#include <QTimer>
#include <QFileInfo>
#include <QFontDatabase>
#include <QDebug>
#include "controllers/AppController.h"

namespace {

class QmlHotReloader : public QObject {
public:
    QmlHotReloader(QQmlApplicationEngine *engine, const QUrl &mainUrl, const QString &watchDir, QObject *parent = nullptr)
        : QObject(parent), m_engine(engine), m_mainUrl(mainUrl), m_watchDir(watchDir) {
        m_debounceTimer.setSingleShot(true);
        m_debounceTimer.setInterval(120);
        connect(&m_debounceTimer, &QTimer::timeout, this, &QmlHotReloader::doReload);

        setupWatcher();
    }

    bool eventFilter(QObject *obj, QEvent *event) override {
        if (event->type() == QEvent::KeyPress) {
            auto *keyEvent = static_cast<QKeyEvent*>(event);
            if (keyEvent->key() == Qt::Key_F5) {
                qDebug() << "[HOT-RELOAD] Manual F5 trigger pressed";
                scheduleReload();
                return true;
            }
        }
        return QObject::eventFilter(obj, event);
    }

    void scheduleReload() {
        m_debounceTimer.start();
    }

private:
    void doReload() {
        qDebug() << "[HOT-RELOAD] Reloading QML interface from disk:" << m_mainUrl.toLocalFile();

        const auto rootObjects = m_engine->rootObjects();
        for (auto *obj : rootObjects) {
            delete obj;
        }

        m_engine->clearComponentCache();
        m_engine->load(m_mainUrl);

        setupWatcher();
    }

    void setupWatcher() {
        if (m_watcher) {
            m_watcher->disconnect(this);
            delete m_watcher;
        }

        m_watcher = new QFileSystemWatcher(this);

        if (QDir(m_watchDir).exists()) {
            QDirIterator it(m_watchDir, QStringList() << "*.qml", QDir::Files, QDirIterator::Subdirectories);
            while (it.hasNext()) {
                QString filePath = it.next();
                m_watcher->addPath(filePath);
            }
            m_watcher->addPath(m_watchDir);
            m_watcher->addPath(m_watchDir + "/components");
            m_watcher->addPath(m_watchDir + "/views");
            m_watcher->addPath(m_watchDir + "/dialogs");

            connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
                qDebug() << "[HOT-RELOAD] File changed:" << path;
                scheduleReload();
            });
            connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, [this]() {
                scheduleReload();
            });
        }
    }

    QQmlApplicationEngine *m_engine;
    QUrl m_mainUrl;
    QString m_watchDir;
    QFileSystemWatcher *m_watcher = nullptr;
    QTimer m_debounceTimer;
};

}

int main(int argc, char *argv[]) {
    QApplication::setOrganizationName("skugg");
    QApplication::setApplicationName("skugg");
    QApplication::setApplicationVersion("1.0.0");

    QApplication app(argc, argv);

    QString appDir = app.applicationDirPath();
    QString fontDir = appDir + "/../src/ui/assets/fonts";
    if (!QFile::exists(fontDir + "/InstrumentSans-Variable.ttf")) {
        fontDir = QDir::currentPath() + "/src/ui/assets/fonts";
    }
    QFontDatabase::addApplicationFont(fontDir + "/InstrumentSerif-Regular.ttf");
    QFontDatabase::addApplicationFont(fontDir + "/InstrumentSerif-Italic.ttf");
    QFontDatabase::addApplicationFont(fontDir + "/InstrumentSans-Variable.ttf");

    QQmlApplicationEngine engine;

    Shadowsocks::AppController controller;
    engine.rootContext()->setContextProperty("appController", &controller);

    QString devSourceDir = appDir + "/../src/ui/qml";
    if (!QFile::exists(devSourceDir + "/Main.qml")) {
        devSourceDir = QDir::currentPath() + "/src/ui/qml";
    }
    QString devMainQml = devSourceDir + "/Main.qml";
    bool isDevMode = QFile::exists(devMainQml);

    QUrl url = isDevMode ? QUrl::fromLocalFile(devMainQml)
                         : QUrl(QStringLiteral("qrc:/src/ui/qml/Main.qml"));

    if (isDevMode) {
        qDebug() << "[MODE] Development Hot-Reload ACTIVE! Loading directly from:" << devMainQml;
        qDebug() << "[MODE] Tips: Just press Ctrl+S in your code editor or hit F5 in the app to reload styles instantly!";
    } else {
        qDebug() << "[MODE] Production mode: loading compiled QRC resources";
    }

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load initial QML!";
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    QmlHotReloader *hotReloader = nullptr;
    if (isDevMode) {
        hotReloader = new QmlHotReloader(&engine, url, devSourceDir, &app);
        app.installEventFilter(hotReloader);
    }

    if (QSystemTrayIcon::isSystemTrayAvailable()) {
        auto *trayIcon = new QSystemTrayIcon(&app);
        trayIcon->setIcon(app.style()->standardIcon(QStyle::SP_DriveNetIcon));
        trayIcon->setToolTip("skugg");

        auto *trayMenu = new QMenu();
        auto *toggleAction = trayMenu->addAction("Toggle Connect");
        trayMenu->addSeparator();
        auto *showAction = trayMenu->addAction("Show Window");
        auto *quitAction = trayMenu->addAction("Quit");

        QObject::connect(toggleAction, &QAction::triggered, [&controller]() {
            controller.toggleConnect();
        });

        QObject::connect(showAction, &QAction::triggered, [&engine]() {
            const auto rootObjects = engine.rootObjects();
            for (auto *obj : rootObjects) {
                if (auto *window = qobject_cast<QQuickWindow*>(obj)) {
                    window->show();
                    window->raise();
                    window->requestActivate();
                }
            }
        });

        QObject::connect(quitAction, &QAction::triggered, &app, &QApplication::quit);

        trayIcon->setContextMenu(trayMenu);
        trayIcon->show();
    }

    return app.exec();
}
