import Foundation
import RxSwift
import EvmKit
import HdWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    var evmKit: Kit!
    var signer: Signer!
    var adapter: EthereumAdapter!

    init() {
        if let words = savedWords {
            try? initKit(words: words)
        } else if let address = savedAddress {
            try? initKit(address: address)
        }
    }

    private func initKit(address: Address, configuration: Configuration, signer: Signer?) throws {
        let evmKit = try Kit.instance(
                address: address,
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        adapter = EthereumAdapter(evmKit: evmKit, signer: signer)

        self.evmKit = evmKit
        self.signer = signer

        evmKit.start()
    }


    private func initKit(words: [String]) throws {
        let configuration = Configuration.shared

        guard let seed = Mnemonic.seed(mnemonic: words) else {
            throw LoginError.seedGenerationFailed
        }

        let signer = try Signer.instance(seed: seed, chain: configuration.chain)

        try initKit(
                address: try Signer.address(seed: seed, chain: configuration.chain),
                configuration: configuration,
                signer: signer
        )
    }

    private func initKit(address: Address) throws {
        let configuration = Configuration.shared

        try initKit(address: address, configuration: configuration, signer: nil)
    }

    private var savedWords: [String]? {
        guard let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String else {
            return nil
        }

        return wordsString.split(separator: " ").map(String.init)
    }

    private var savedAddress: Address? {
        guard let addressString = UserDefaults.standard.value(forKey: keyAddress) as? String else {
            return nil
        }

        return try? Address(hex: addressString)
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

}

extension Manager {

    func login(words: [String]) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        try initKit(words: words)
    }

    func watch(address: Address) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(address: address.hex)
        try initKit(address: address)
    }

    func logout() {
        clearStorage()

        signer = nil
        evmKit = nil
        adapter = nil
    }

}

extension Manager {

    enum LoginError: Error {
        case seedGenerationFailed
    }

}
