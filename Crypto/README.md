# Data4LifeCrypto for iOS
Swift framework for handling all of the crypto operation for HCSDK.

## Usage
### Requirements
* Xcode 12.0+
* iOS 13.0+
* Swift 5.3+

### Install package manager and build frameworks
Check information in the main [README](https://github.com/gesundheitscloud/hc-sdk-ios#install-carthage) of the project.

### Crypto examples

#### Supported symmetric algorithms
`Data4LifeCrypto` supports two modes of symmetric crypto operations:
* `AES-SHA256-CBC-PKCS7`
* `AES-SHA256-GCM-NOPADDING`

*Note*: Provided by Apple Common Crypto and Cryptokit frameworks

#### Supported asymmetric algorithms
`Data4LifeCrypto` supports one mode of asymmetric crypto operations:
* `RSA-OAEP-SHA256`

*Note*: Provided by Apple Security framework

#### Storing and working with crypto keys
`KeyPair` is managed by Apple and has to be loaded using `Security` framework APIs that expect `tag`.
`Key` has to be stored manually in prefered storage of choice.

It's possible to generate `KeyPair` as it's stored on device, and use that to encrypt `Key`, that way it's possible to store data keys and encrypted sensitive information on the API.

Store keys and data:
* Generate `Key` for encrypting data (`KeyType.data`)
* Create key exchange format from the key type
* Encrypt sensitive data using generated `Key`
* Generate `KeyPair` for encrypting data key
* Convert data key from `Key` type to `Data` type (`Key` conforms to `Codable`)
* Encrypt key data using `KeyPair`
* Store ciphertext, iv and encrypted data key in some storage

Read keys and data:
* Load already created `KeyPair` from the device
* Load ciphertext, iv and encrypted data key from storage
* Decrypt data key using keypair
* Decrypt sensitive data using decrypted data key, ciphertext and iv

#### Key (symmetric)
Symmetric key used for encrypt/decrypt operations.
```swift
struct Key: Codable {
    let value: SymmetricKey
    var algorithm: AlgorithmType
    let keySize: KeySize
    let type: KeyType
}
```

Create new key
```swift
func generate(keySize: KeySize, algorithm: AlgorithmType, type: KeyType) throws -> Key
```

Loading already existing key
```swift
let keyData = Data(...) // load from some storage
let key = try JSONDecoder().decode(Key.self, from: keyData)
```

Exporting key for storage
```swift
let key = Key.generate(...)
let keyData = try JSONEncoder().encode(key)
```

Example of creating a key and ecrypting data
```swift
let keyType: KeyType = .data
let keyExchangeFormat = try KeyExhangeFactory.create(type: keyType)
let key = try Key.generate(keySize: keyExchangeFormat.size, algorithm: keyExchangeFormat.algorithm, type: type)
let iv = Data(bytes: [...]) // generate random IV

let plaintext: Data = Data(bytes: [0x00, 0x01, 0x02])
let ciphertext: Data = Data4LifeCryptor.symEncrypt(key: key, data: plaintext, iv: iv)
// Store ciphertext, iv and key in a safe way
```

Decrypt the data
```swift
let key: Key =  ... // fetch key from storage
let iv: Data = ... // fetch iv from storage
let ciphertext: Data =  ... // fetch ciphertext from storage
let plaintext: Data = try Data4LifeCryptor.symDecrypt(key: key, data: ciphertext, iv: iv)
```

#### KeyPair (asymmetric)
```swift
struct KeyPair: KeyPairType {
    let privateKey: AsymmetricKey
    let publicKey: AsymmetricKey
    let keySize: KeySize
    let algorithm: AlgorithmType
}
```

Helper methods for working with keypairs (wrapper around `Security` framework)
```swift
func generate(tag: String, keySize: Int, algorithm: AlgorithmType) throws -> KeyPair
func load(tag: String, algorithm: AlgorithmType) throws -> KeyPair
func destroy(tag: String) throws
```

Exporting public key can be done in one of two formats `PKCS#1` or `SPKI`
```swift
let keypair = try KeyPair.generate(...)

let pkcs1PubKey: String = keypair.publicKey.asBase64EncodedString()
let spkiPubKey: String = keypair.publicKey.asSPKIBase64EncodedString()
let pubKeyData: Data = JSONEncoder().encode(keypair) // will export `SPKI` encoded public key and ignore private key
```

Example of creating keypair and ecrypting data
```swift
let tag: String = "com.example.keypair"
let keyType: KeyType = .appPrivate
let keyExchangeFormat = try KeyExhangeFactory.create(type: type)
let keypair = try KeyPair.generate(tag: tag, keySize: keyExchangeFormat.size, algorithm: keyExchangeFormat.algorithm)

let plaintext: Data = Data(bytes: [0x00, 0x01, 0x02])
let ciphertext: Data = try Data4LifeCryptor.asymEncrypt(key: keypair, data: plaintext)
```

Decrypt the data
```swift
let tag: String = "com.example.keypair"
let keyType: KeyType = .appPrivate
let keyExchangeFormat = KeyExhangeFactory.create(type: type)
let keypair = try KeyPair.load(tag: tag, algorithm: keyExchangeFormat.algorithm)

let ciphertext: Data = ... // fetch ciphertext from storage
let plaintext: Data = try Data4LifeCryptor.asymDecrypt(key: keypair, data: ciphertext)
```
