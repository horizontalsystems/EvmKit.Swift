// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
// import TrezorCrypto

/// Ethereum address.
public struct EthereumAddress: AddressProtocol, Hashable {
    public static let size = 20

    /// Validates that the raw data is a valid address.
    public static func isValid(data: Data) -> Bool {
        data.count == EthereumAddress.size
    }

    /// Validates that the string is a valid address.
    public static func isValid(string: String) -> Bool {
        guard let data = string.hs.hexData else {
            return false
        }
        return EthereumAddress.isValid(data: data)
    }

    /// Raw address bytes, length 20.
    public let data: Data

    /// EIP55 representation of the address.
    public let eip55String: String

    /// Creates an address with `Data`.
    ///
    /// - Precondition: data contains exactly 20 bytes
    public init?(data: Data) {
        if !EthereumAddress.isValid(data: data) {
            return nil
        }
        self.data = data
        eip55String = EthereumChecksum.computeString(for: data, type: .eip55)
    }

    /// Creates an address with an hexadecimal string representation.
    public init?(string: String) {
        guard let data = string.hs.hexData, EthereumAddress.isValid(data: data) else {
            return nil
        }
        self.init(data: data)
    }

    public var description: String {
        eip55String
    }

    public var hashValue: Int {
        data.hashValue
    }

    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        lhs.data == rhs.data
    }
}
