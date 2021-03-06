import CLibOpaque

public enum Opaque {
    
    public struct RegistrationToken: PersistableData, Equatable, PersistableData_Internal {
        
        let raw: opq_registration_token
        
    }

    public struct Salt: PersistableData, PersistableData_Internal {
        
        let raw: opq_salt
        
    }
    
    public struct EncryptedPassword: PersistableData, PersistableData_Internal {
        
        let raw: opq_encrypted_password
        
    }
    
    public struct EncryptedSaltedPassword: PersistableData, PersistableData_Internal {
        
        let raw: opq_encrypted_salted_password
        
    }
    
    public struct PasswordKey {
        
        fileprivate let raw: opq_password_key
        
    }
    
    public struct EncryptedPrivateKey: PersistableData, PersistableData_Internal {
        
        let raw: opq_encrypted_private_key
        
    }
    
    public struct PublicKey: PersistableData, PersistableData_Internal {
        
        let raw: opq_public_key
        
    }
    
    public struct VerificationNonce: PersistableData, PersistableData_Internal {
        
        var raw: opq_verification_nonce
        
        init(raw: opq_verification_nonce) {
            self.raw = raw
        }
        
        public init() {
            self.raw = opq_verification_nonce()
        }
        
    }
    
    public struct Verification: PersistableData, PersistableData_Internal {
        
        let raw: opq_verification
        
    }

}

extension Opaque.RegistrationToken {
    
    public static func random() throws -> Opaque.RegistrationToken {
        var raw = opq_registration_token()
        try opq_generate_registration_token(&raw).throwIfError()
        return Opaque.RegistrationToken(raw: raw)
    }
    
}

extension Opaque.Salt {
    
    public static func random() throws -> Opaque.Salt {
        var raw = opq_salt()
        try opq_generate_random_salt(&raw).throwIfError()
        return Opaque.Salt(raw: raw)
    }
    
}

extension Opaque {
    
    public static func encrypt(_ password: String) throws
        -> (encryptedPassword: EncryptedPassword, passwordKey: PasswordKey)
    {
        var encryptedPassword = opq_encrypted_password()
        var passwordKey = opq_password_key()
        try password.withCString({ cString in
            opq_encrypt_password(
                &encryptedPassword,
                &passwordKey,
                cString)
        }).throwIfError()
        
        return (EncryptedPassword(raw: encryptedPassword), PasswordKey(raw: passwordKey))
    }
    
}

extension Opaque.EncryptedPassword {
    
    public func salted(with salt: Opaque.Salt) throws -> Opaque.EncryptedSaltedPassword {
        var raw = opq_encrypted_salted_password()
        try withUnsafePointer(to: self.raw) { encryptedPasswordPointer in
            withUnsafePointer(to: salt.raw) { saltPointer in
                opq_salt_encrypted_password(&raw, encryptedPasswordPointer, saltPointer)
            }
        }.throwIfError()
        return Opaque.EncryptedSaltedPassword(raw: raw)
    }
    
}

extension Opaque {
    
    public static func generateKeys(_ encryptedSaltedPassword: EncryptedSaltedPassword, _ passwordKey: PasswordKey) throws
        -> (encryptedPrivateKey: EncryptedPrivateKey, publicKey: PublicKey)
    {
        var encryptedPrivateKey = opq_encrypted_private_key()
        var publicKey = opq_public_key()
        try withUnsafePointer(to: encryptedSaltedPassword.raw) { encryptedSaltedPasswordPointer in
            withUnsafePointer(to: passwordKey.raw) { passwordKeyPointer  in
                opq_generate_keys(&encryptedPrivateKey, &publicKey, encryptedSaltedPasswordPointer, passwordKeyPointer)
            }
        }.throwIfError()
        
        return (encryptedPrivateKey: EncryptedPrivateKey(raw: encryptedPrivateKey), PublicKey(raw: publicKey))
    }
    
}

extension Opaque.VerificationNonce {
    
    public static let zero = Opaque.VerificationNonce(raw: opq_verification_nonce())
    
    public mutating func increment() throws {
        try opq_increment_verification_nonce(&raw).throwIfError()
    }
    
}

extension Opaque.Verification {
    
    public init(
        _ encryptedPrivateKey: Opaque.EncryptedPrivateKey,
        _ verificationNonce: Opaque.VerificationNonce,
        _ encryptedSaltedPassword: Opaque.EncryptedSaltedPassword,
        _ passwordKey: Opaque.PasswordKey) throws
    {
        var raw = opq_verification()
        try withUnsafePointer(to: encryptedPrivateKey.raw) { encryptedPrivateKeyPointer in
            withUnsafePointer(to: verificationNonce.raw) { verificationNoncePointer in
                withUnsafePointer(to: encryptedSaltedPassword.raw) { encryptedSaltedPasswordPointer in
                    withUnsafePointer(to: passwordKey.raw) { passwordKeyPointer in
                        opq_generate_verification(
                            &raw,
                            encryptedPrivateKeyPointer,
                            verificationNoncePointer,
                            encryptedSaltedPasswordPointer,
                            passwordKeyPointer)
                    }
                }
            }
        }.throwIfError()
        self.raw = raw
    }
    
    public func validate(_ publicKey: Opaque.PublicKey, _ verificationNonce: Opaque.VerificationNonce) throws {
        try withUnsafePointer(to: raw) { verificationPointer in
            withUnsafePointer(to: publicKey.raw) { publicKeyPointer in
                withUnsafePointer(to: verificationNonce.raw) { verificationNoncePointer in
                    opq_validate_verification(publicKeyPointer, verificationNoncePointer, verificationPointer)
                }
            }
        }.throwIfError()
    }
    
}

// MARK: - ExhaustiveBinaryRepresentable

extension opq_registration_token: ExhaustiveBinaryRepresentable { }
extension opq_salt: ExhaustiveBinaryRepresentable { }
extension opq_encrypted_password: ExhaustiveBinaryRepresentable { }
extension opq_encrypted_salted_password: ExhaustiveBinaryRepresentable { }
extension opq_encrypted_private_key: ExhaustiveBinaryRepresentable { }
extension opq_public_key: ExhaustiveBinaryRepresentable { }
extension opq_verification_nonce: ExhaustiveBinaryRepresentable { }
extension opq_verification: ExhaustiveBinaryRepresentable { }
