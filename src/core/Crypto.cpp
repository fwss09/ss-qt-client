#include "Crypto.h"
#include <openssl/kdf.h>
#include <openssl/core_names.h>
#include <openssl/params.h>
#include <openssl/rand.h>
#include <QtEndian>
#include <QCryptographicHash>
#include <algorithm>
#include <cstring>

namespace Shadowsocks {

static const CipherInfo g_supportedCiphers[] = {
    {"chacha20-poly1305", 32, 32, 12, 16},
    {"aes-256-gcm",       32, 32, 12, 16},
    {"aes-128-gcm",       16, 16, 12, 16}
};

const CipherInfo* CryptoHelper::getCipherInfo(const QString &method) {
    QString m = method.toLower().trimmed();
    for (const auto &info : g_supportedCiphers) {
        if (info.name == m) {
            return &info;
        }
    }

    return &g_supportedCiphers[0];
}

const EVP_CIPHER* CryptoHelper::getEvpCipher(const QString &method) {
    QString m = method.toLower().trimmed();
    if (m == "chacha20-poly1305") {
        return EVP_chacha20_poly1305();
    } else if (m == "aes-256-gcm") {
        return EVP_aes_256_gcm();
    } else if (m == "aes-128-gcm") {
        return EVP_aes_128_gcm();
    }
    return EVP_chacha20_poly1305();
}

QByteArray CryptoHelper::deriveMasterKey(const QString &password, int keyLen) {
    QByteArray passUtf8 = password.toUtf8();
    QByteArray key;
    QByteArray prev;
    while (key.size() < keyLen) {
        QCryptographicHash hash(QCryptographicHash::Md5);
        if (!prev.isEmpty()) {
            hash.addData(prev);
        }
        hash.addData(passUtf8);
        prev = hash.result();
        key.append(prev);
    }
    key.truncate(keyLen);
    return key;
}

QByteArray CryptoHelper::deriveSubkey(const QByteArray &masterKey, const QByteArray &salt, int keyLen) {
    EVP_KDF *kdf = EVP_KDF_fetch(nullptr, "HKDF", nullptr);
    if (!kdf) return {};

    EVP_KDF_CTX *kctx = EVP_KDF_CTX_new(kdf);
    EVP_KDF_free(kdf);
    if (!kctx) return {};

    char digest[] = "SHA1";
    char info[] = "ss-subkey";
    QByteArray out;
    out.resize(keyLen);

    OSSL_PARAM params[5];
    params[0] = OSSL_PARAM_construct_utf8_string(OSSL_KDF_PARAM_DIGEST, digest, 0);
    params[1] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_KEY, const_cast<char*>(masterKey.constData()), masterKey.size());
    params[2] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_SALT, const_cast<char*>(salt.constData()), salt.size());
    params[3] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_INFO, info, sizeof(info) - 1);
    params[4] = OSSL_PARAM_construct_end();

    int res = EVP_KDF_derive(kctx, reinterpret_cast<unsigned char*>(out.data()), keyLen, params);
    EVP_KDF_CTX_free(kctx);

    if (res <= 0) return {};
    return out;
}

QByteArray CryptoHelper::generateRandomBytes(int size) {
    QByteArray bytes;
    bytes.resize(size);
    RAND_bytes(reinterpret_cast<unsigned char*>(bytes.data()), size);
    return bytes;
}

void CryptoHelper::incrementNonce(uint8_t *nonce, size_t nonceLen) {
    for (size_t i = 0; i < nonceLen; ++i) {
        if (++nonce[i] != 0) {
            break;
        }
    }
}

bool CryptoHelper::encryptAead(const EVP_CIPHER *cipher,
                               const uint8_t *subkey,
                               const uint8_t *nonce,
                               const uint8_t *plaintext, size_t plainLen,
                               uint8_t *ciphertext,
                               uint8_t *tag, size_t tagLen) {
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) return false;

    bool ok = true;
    int outl = 0;
    int finalL = 0;

    if (EVP_EncryptInit_ex(ctx, cipher, nullptr, nullptr, nullptr) <= 0 ||
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_IVLEN, 12, nullptr) <= 0 ||
        EVP_EncryptInit_ex(ctx, nullptr, nullptr, subkey, nonce) <= 0 ||
        EVP_EncryptUpdate(ctx, ciphertext, &outl, plaintext, static_cast<int>(plainLen)) <= 0 ||
        EVP_EncryptFinal_ex(ctx, ciphertext + outl, &finalL) <= 0 ||
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_GET_TAG, static_cast<int>(tagLen), tag) <= 0) {
        ok = false;
    }

    EVP_CIPHER_CTX_free(ctx);
    return ok;
}

bool CryptoHelper::decryptAead(const EVP_CIPHER *cipher,
                               const uint8_t *subkey,
                               const uint8_t *nonce,
                               const uint8_t *ciphertext, size_t cipherLen,
                               const uint8_t *tag, size_t tagLen,
                               uint8_t *plaintext) {
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) return false;

    bool ok = true;
    int outl = 0;
    int finalL = 0;

    if (EVP_DecryptInit_ex(ctx, cipher, nullptr, nullptr, nullptr) <= 0 ||
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_IVLEN, 12, nullptr) <= 0 ||
        EVP_DecryptInit_ex(ctx, nullptr, nullptr, subkey, nonce) <= 0 ||
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_TAG, static_cast<int>(tagLen), const_cast<uint8_t*>(tag)) <= 0 ||
        EVP_DecryptUpdate(ctx, plaintext, &outl, ciphertext, static_cast<int>(cipherLen)) <= 0 ||
        EVP_DecryptFinal_ex(ctx, plaintext + outl, &finalL) <= 0) {
        ok = false;
    }

    EVP_CIPHER_CTX_free(ctx);
    return ok;
}

QByteArray CryptoHelper::encryptUdpPacket(const QString &method, const QByteArray &masterKey, const QByteArray &payload) {
    if (payload.isEmpty()) return {};

    const CipherInfo *info = getCipherInfo(method);
    const EVP_CIPHER *cipher = getEvpCipher(method);
    if (!info || !cipher) return {};

    QByteArray salt = generateRandomBytes(info->saltSize);
    QByteArray subkey = deriveSubkey(masterKey, salt, info->keySize);
    if (subkey.isEmpty()) return {};

    uint8_t zeroNonce[12];
    std::memset(zeroNonce, 0, sizeof(zeroNonce));

    QByteArray ciphertext;
    ciphertext.resize(payload.size());
    uint8_t tag[16];

    if (!encryptAead(cipher,
                     reinterpret_cast<const uint8_t*>(subkey.constData()),
                     zeroNonce,
                     reinterpret_cast<const uint8_t*>(payload.constData()), payload.size(),
                     reinterpret_cast<uint8_t*>(ciphertext.data()),
                     tag, 16)) {
        return {};
    }

    QByteArray packet;
    packet.append(salt);
    packet.append(ciphertext);
    packet.append(reinterpret_cast<const char*>(tag), 16);
    return packet;
}

QByteArray CryptoHelper::decryptUdpPacket(const QString &method, const QByteArray &masterKey, const QByteArray &packet) {
    const CipherInfo *info = getCipherInfo(method);
    const EVP_CIPHER *cipher = getEvpCipher(method);
    if (!info || !cipher) return {};

    int minLen = info->saltSize + 16;
    if (packet.size() < minLen) return {};

    QByteArray salt = packet.left(info->saltSize);
    int cipherLen = packet.size() - info->saltSize - 16;
    const uint8_t *ciphertext = reinterpret_cast<const uint8_t*>(packet.constData() + info->saltSize);
    const uint8_t *tag = reinterpret_cast<const uint8_t*>(packet.constData() + packet.size() - 16);

    QByteArray subkey = deriveSubkey(masterKey, salt, info->keySize);
    if (subkey.isEmpty()) return {};

    uint8_t zeroNonce[12];
    std::memset(zeroNonce, 0, sizeof(zeroNonce));

    QByteArray plaintext;
    plaintext.resize(cipherLen);

    if (!decryptAead(cipher,
                     reinterpret_cast<const uint8_t*>(subkey.constData()),
                     zeroNonce,
                     ciphertext, cipherLen,
                     tag, 16,
                     reinterpret_cast<uint8_t*>(plaintext.data()))) {
        return {};
    }

    return plaintext;
}

AeadStreamEncryptor::AeadStreamEncryptor() {
    std::memset(m_nonce, 0, sizeof(m_nonce));
}

bool AeadStreamEncryptor::init(const QString &method, const QByteArray &masterKey, const QByteArray &salt) {
    m_info = CryptoHelper::getCipherInfo(method);
    m_cipher = CryptoHelper::getEvpCipher(method);
    if (!m_info || !m_cipher) return false;

    m_subkey = CryptoHelper::deriveSubkey(masterKey, salt, m_info->keySize);
    if (m_subkey.isEmpty()) return false;

    std::memset(m_nonce, 0, sizeof(m_nonce));
    m_initialized = true;
    return true;
}

QByteArray AeadStreamEncryptor::encryptChunk(const QByteArray &payload) {
    if (!m_initialized || payload.isEmpty()) return {};

    const int maxChunk = 0x3FFF;
    QByteArray result;

    int offset = 0;
    while (offset < payload.size()) {
        int chunkLen = std::min(maxChunk, static_cast<int>(payload.size() - offset));
        const uint8_t *plainChunk = reinterpret_cast<const uint8_t*>(payload.constData() + offset);

        uint16_t lenBe = qToBigEndian<uint16_t>(static_cast<uint16_t>(chunkLen));
        uint8_t lenCipher[2];
        uint8_t lenTag[16];

        if (!CryptoHelper::encryptAead(m_cipher,
                                       reinterpret_cast<const uint8_t*>(m_subkey.constData()),
                                       m_nonce,
                                       reinterpret_cast<const uint8_t*>(&lenBe), 2,
                                       lenCipher,
                                       lenTag, 16)) {
            return {};
        }
        CryptoHelper::incrementNonce(m_nonce, sizeof(m_nonce));

        QByteArray chunkCipher;
        chunkCipher.resize(chunkLen);
        uint8_t payloadTag[16];

        if (!CryptoHelper::encryptAead(m_cipher,
                                       reinterpret_cast<const uint8_t*>(m_subkey.constData()),
                                       m_nonce,
                                       plainChunk, chunkLen,
                                       reinterpret_cast<uint8_t*>(chunkCipher.data()),
                                       payloadTag, 16)) {
            return {};
        }
        CryptoHelper::incrementNonce(m_nonce, sizeof(m_nonce));

        result.append(reinterpret_cast<const char*>(lenCipher), 2);
        result.append(reinterpret_cast<const char*>(lenTag), 16);
        result.append(chunkCipher);
        result.append(reinterpret_cast<const char*>(payloadTag), 16);

        offset += chunkLen;
    }

    return result;
}

AeadStreamDecryptor::AeadStreamDecryptor() {
    std::memset(m_nonce, 0, sizeof(m_nonce));
}

bool AeadStreamDecryptor::init(const QString &method, const QByteArray &masterKey, const QByteArray &salt) {
    m_info = CryptoHelper::getCipherInfo(method);
    m_cipher = CryptoHelper::getEvpCipher(method);
    if (!m_info || !m_cipher) return false;

    m_subkey = CryptoHelper::deriveSubkey(masterKey, salt, m_info->keySize);
    if (m_subkey.isEmpty()) return false;

    std::memset(m_nonce, 0, sizeof(m_nonce));
    m_buffer.clear();
    m_state = ReadingLength;
    m_expectedPayloadLen = 0;
    m_initialized = true;
    return true;
}

bool AeadStreamDecryptor::feed(const QByteArray &data, QList<QByteArray> &outPayloads) {
    if (!m_initialized) return false;

    m_buffer.append(data);

    while (true) {
        if (m_state == ReadingLength) {

            if (m_buffer.size() < 18) {
                break;
            }

            const uint8_t *lenCipher = reinterpret_cast<const uint8_t*>(m_buffer.constData());
            const uint8_t *lenTag = reinterpret_cast<const uint8_t*>(m_buffer.constData() + 2);

            uint16_t lenBe = 0;
            if (!CryptoHelper::decryptAead(m_cipher,
                                           reinterpret_cast<const uint8_t*>(m_subkey.constData()),
                                           m_nonce,
                                           lenCipher, 2,
                                           lenTag, 16,
                                           reinterpret_cast<uint8_t*>(&lenBe))) {
                return false;
            }
            CryptoHelper::incrementNonce(m_nonce, sizeof(m_nonce));

            m_expectedPayloadLen = qFromBigEndian<uint16_t>(lenBe);
            if (m_expectedPayloadLen > 0x3FFF) {
                return false;
            }

            m_buffer.remove(0, 18);
            m_state = ReadingPayload;
        }

        if (m_state == ReadingPayload) {
            int needed = m_expectedPayloadLen + 16;
            if (m_buffer.size() < needed) {
                break;
            }

            const uint8_t *payloadCipher = reinterpret_cast<const uint8_t*>(m_buffer.constData());
            const uint8_t *payloadTag = reinterpret_cast<const uint8_t*>(m_buffer.constData() + m_expectedPayloadLen);

            QByteArray plainPayload;
            plainPayload.resize(m_expectedPayloadLen);

            if (!CryptoHelper::decryptAead(m_cipher,
                                           reinterpret_cast<const uint8_t*>(m_subkey.constData()),
                                           m_nonce,
                                           payloadCipher, m_expectedPayloadLen,
                                           payloadTag, 16,
                                           reinterpret_cast<uint8_t*>(plainPayload.data()))) {
                return false;
            }
            CryptoHelper::incrementNonce(m_nonce, sizeof(m_nonce));

            outPayloads.append(plainPayload);
            m_buffer.remove(0, needed);
            m_state = ReadingLength;
        }
    }

    return true;
}

}
