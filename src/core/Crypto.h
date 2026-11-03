#ifndef CRYPTO_H
#define CRYPTO_H

#include <QByteArray>
#include <QString>
#include <QList>
#include <cstdint>
#include <openssl/evp.h>

namespace Shadowsocks {

struct CipherInfo {
    QString name;
    int keySize;
    int saltSize;
    int nonceSize;
    int tagSize;
};

class CryptoHelper {
public:
    static const CipherInfo* getCipherInfo(const QString &method);
    static const EVP_CIPHER* getEvpCipher(const QString &method);
    static QByteArray deriveMasterKey(const QString &password, int keyLen);
    static QByteArray deriveSubkey(const QByteArray &masterKey, const QByteArray &salt, int keyLen);
    static QByteArray generateRandomBytes(int size);
    static void incrementNonce(uint8_t *nonce, size_t nonceLen = 12);

    static bool encryptAead(const EVP_CIPHER *cipher,
                            const uint8_t *subkey,
                            const uint8_t *nonce,
                            const uint8_t *plaintext, size_t plainLen,
                            uint8_t *ciphertext,
                            uint8_t *tag, size_t tagLen = 16);

    static bool decryptAead(const EVP_CIPHER *cipher,
                            const uint8_t *subkey,
                            const uint8_t *nonce,
                            const uint8_t *ciphertext, size_t cipherLen,
                            const uint8_t *tag, size_t tagLen,
                            uint8_t *plaintext);

    static QByteArray encryptUdpPacket(const QString &method, const QByteArray &masterKey, const QByteArray &payload);
    static QByteArray decryptUdpPacket(const QString &method, const QByteArray &masterKey, const QByteArray &packet);
};

class AeadStreamEncryptor {
public:
    AeadStreamEncryptor();
    bool init(const QString &method, const QByteArray &masterKey, const QByteArray &salt);
    QByteArray encryptChunk(const QByteArray &payload);

private:
    const EVP_CIPHER *m_cipher = nullptr;
    const CipherInfo *m_info = nullptr;
    QByteArray m_subkey;
    uint8_t m_nonce[12];
    bool m_initialized = false;
};

class AeadStreamDecryptor {
public:
    enum State {
        ReadingLength,
        ReadingPayload
    };

    AeadStreamDecryptor();
    bool init(const QString &method, const QByteArray &masterKey, const QByteArray &salt);
    bool feed(const QByteArray &data, QList<QByteArray> &outPayloads);

private:
    const EVP_CIPHER *m_cipher = nullptr;
    const CipherInfo *m_info = nullptr;
    QByteArray m_subkey;
    uint8_t m_nonce[12];
    QByteArray m_buffer;
    State m_state = ReadingLength;
    int m_expectedPayloadLen = 0;
    bool m_initialized = false;
};

}

#endif
