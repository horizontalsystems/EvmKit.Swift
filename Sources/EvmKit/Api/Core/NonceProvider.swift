class NonceProvider: INonceProvider {
    var providers: [INonceProvider] = []

    func add(provider: INonceProvider) {
        providers.append(provider)
    }
}

extension NonceProvider {
    func nonce(defaultBlockParameter: DefaultBlockParameter) async throws -> Int {
        var maxNonce = -1
        
        for provider in providers {
            // avoid downtime for some rpc-nodes
            if let nonce = try? await provider.nonce(defaultBlockParameter: defaultBlockParameter) {
                maxNonce = max(maxNonce, nonce)
            }
        }
        
        guard maxNonce > -1 else {
            throw NonceError.noAnyNonceProvider
        }

        return maxNonce
    }
}

extension NonceProvider {
    enum NonceError: Error {
        case noAnyNonceProvider
    }
}
