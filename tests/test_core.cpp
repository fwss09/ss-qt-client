#include <cassert>
#include <iostream>
#include <QCoreApplication>
#include "core/Crypto.h"
#include "models/ServerConfig.h"

using namespace Shadowsocks;

void testMasterKey() {
    std::cout << "[TEST] Master key derivation..." << std::endl;
    QByteArray key = CryptoHelper::deriveMasterKey("test-password", 32);
    assert(key.size() == 32);
    std::cout << "  OK: key size = " << key.size() << std::endl;
}

void testAeadRoundtrip(const QString &method) {
    std::cout << "[TEST] AEAD stream roundtrip for " << method.toStdString() << "..." << std::endl;
    const CipherInfo *info = CryptoHelper::getCipherInfo(method);
    assert(info != nullptr);

    QByteArray masterKey = CryptoHelper::deriveMasterKey("secret-password", info->keySize);
    QByteArray salt = CryptoHelper::generateRandomBytes(info->saltSize);

    AeadStreamEncryptor encryptor;
    bool initEnc = encryptor.init(method, masterKey, salt);
    assert(initEnc);

    AeadStreamDecryptor decryptor;
    bool initDec = decryptor.init(method, masterKey, salt);
    assert(initDec);

    QByteArray testData = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: ShadowsocksClient\r\n\r\n";
    QByteArray encrypted = encryptor.encryptChunk(testData);
    assert(!encrypted.isEmpty());

    QList<QByteArray> decryptedPayloads;
    bool feedOk = decryptor.feed(encrypted, decryptedPayloads);
    assert(feedOk);
    assert(decryptedPayloads.size() == 1);
    assert(decryptedPayloads[0] == testData);

    std::cout << "  OK: Successfully encrypted and decrypted payload: " << decryptedPayloads[0].toStdString() << std::endl;
}

void testSsUrlParsing() {
    std::cout << "[TEST] Shadowsocks URI SIP002 parsing and generation..." << std::endl;
    ServerConfig cfg;
    cfg.id = "test-1";
    cfg.name = "My Tokyo Server";
    cfg.host = "192.0.2.1";
    cfg.port = 8388;
    cfg.password = "secretpass";
    cfg.method = "chacha20-poly1305";

    QString url = cfg.toSsUrl();
    std::cout << "  Generated URI: " << url.toStdString() << std::endl;

    ServerConfig parsed;
    bool ok = ServerConfig::fromSsUrl(url, parsed);
    assert(ok);
    assert(parsed.host == cfg.host);
    assert(parsed.port == cfg.port);
    assert(parsed.password == cfg.password);
    assert(parsed.method == cfg.method);
    assert(parsed.name == cfg.name);

    std::cout << "  OK: URI parsed matching all fields perfectly!" << std::endl;
}

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);

    testMasterKey();
    testAeadRoundtrip("chacha20-poly1305");
    testAeadRoundtrip("aes-256-gcm");
    testAeadRoundtrip("aes-128-gcm");
    testSsUrlParsing();

    std::cout << "\n>>> ALL UNIT TESTS PASSED SUCCESSFULLY! <<<" << std::endl;
    return 0;
}
