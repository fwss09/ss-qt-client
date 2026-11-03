#include "TrafficMeter.h"

namespace Shadowsocks {

TrafficMeter::TrafficMeter(QObject *parent)
    : QObject(parent) {

    for (int i = 0; i < m_maxHistoryPoints; ++i) {
        m_downloadHistory.append(0.0);
    }

    connect(&m_timer, &QTimer::timeout, this, &TrafficMeter::onTick);
    m_timer.start(1000);
}

void TrafficMeter::reset() {
    m_periodBytesIn = 0;
    m_periodBytesOut = 0;
    m_totalBytesIn = 0;
    m_totalBytesOut = 0;
    m_lastDownloadSpeed = 0;
    m_lastUploadSpeed = 0;

    m_downloadHistory.clear();
    for (int i = 0; i < m_maxHistoryPoints; ++i) {
        m_downloadHistory.append(0.0);
    }

    emit statsUpdated();
}

void TrafficMeter::addBytes(quint64 bytesIn, quint64 bytesOut) {
    m_periodBytesIn += bytesIn;
    m_periodBytesOut += bytesOut;

    m_totalBytesIn += bytesIn;
    m_totalBytesOut += bytesOut;
}

void TrafficMeter::onTick() {
    m_lastDownloadSpeed = m_periodBytesIn;
    m_lastUploadSpeed = m_periodBytesOut;

    m_periodBytesIn = 0;
    m_periodBytesOut = 0;

    if (m_downloadHistory.size() >= m_maxHistoryPoints) {
        m_downloadHistory.removeFirst();
    }
    m_downloadHistory.append(static_cast<double>(m_lastDownloadSpeed));

    emit statsUpdated();
}

QVariantList TrafficMeter::speedHistory() const {
    QVariantList list;
    for (double val : m_downloadHistory) {
        list.append(val);
    }
    return list;
}

QString TrafficMeter::downloadSpeedFormatted() const {
    return formatSpeed(m_lastDownloadSpeed);
}

QString TrafficMeter::uploadSpeedFormatted() const {
    return formatSpeed(m_lastUploadSpeed);
}

QString TrafficMeter::totalDownloadFormatted() const {
    return formatBytes(m_totalBytesIn);
}

QString TrafficMeter::totalUploadFormatted() const {
    return formatBytes(m_totalBytesOut);
}

QString TrafficMeter::formatBytes(quint64 bytes) {
    if (bytes < 1024) {
        return QString("%1 B").arg(bytes);
    } else if (bytes < 1024 * 1024) {
        return QString("%1 KB").arg(QString::number(bytes / 1024.0, 'f', 1));
    } else if (bytes < 1024ULL * 1024 * 1024) {
        return QString("%1 MB").arg(QString::number(bytes / (1024.0 * 1024.0), 'f', 2));
    } else {
        return QString("%1 GB").arg(QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 2));
    }
}

QString TrafficMeter::formatSpeed(quint64 bytesPerSec) {
    return formatBytes(bytesPerSec) + "/s";
}

}
