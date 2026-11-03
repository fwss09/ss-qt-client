#ifndef TRAFFICMETER_H
#define TRAFFICMETER_H

#include <QObject>
#include <QTimer>
#include <QList>
#include <QVariantList>

namespace Shadowsocks {

class TrafficMeter : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString downloadSpeedFormatted READ downloadSpeedFormatted NOTIFY statsUpdated)
    Q_PROPERTY(QString uploadSpeedFormatted READ uploadSpeedFormatted NOTIFY statsUpdated)
    Q_PROPERTY(QString totalDownloadFormatted READ totalDownloadFormatted NOTIFY statsUpdated)
    Q_PROPERTY(QString totalUploadFormatted READ totalUploadFormatted NOTIFY statsUpdated)
    Q_PROPERTY(quint64 currentDownloadSpeed READ currentDownloadSpeed NOTIFY statsUpdated)
    Q_PROPERTY(quint64 currentUploadSpeed READ currentUploadSpeed NOTIFY statsUpdated)
    Q_PROPERTY(QVariantList speedHistory READ speedHistory NOTIFY statsUpdated)

public:
    explicit TrafficMeter(QObject *parent = nullptr);

    void reset();
    void addBytes(quint64 bytesIn, quint64 bytesOut);

    QString downloadSpeedFormatted() const;
    QString uploadSpeedFormatted() const;
    QString totalDownloadFormatted() const;
    QString totalUploadFormatted() const;

    quint64 currentDownloadSpeed() const { return m_lastDownloadSpeed; }
    quint64 currentUploadSpeed() const { return m_lastUploadSpeed; }
    QVariantList speedHistory() const;

signals:
    void statsUpdated();

private slots:
    void onTick();

private:
    static QString formatBytes(quint64 bytes);
    static QString formatSpeed(quint64 bytesPerSec);

    QTimer m_timer;

    quint64 m_periodBytesIn = 0;
    quint64 m_periodBytesOut = 0;

    quint64 m_totalBytesIn = 0;
    quint64 m_totalBytesOut = 0;

    quint64 m_lastDownloadSpeed = 0;
    quint64 m_lastUploadSpeed = 0;

    const int m_maxHistoryPoints = 30;
    QList<double> m_downloadHistory;
};

}

#endif
