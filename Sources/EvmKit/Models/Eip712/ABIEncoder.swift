// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import BigInt
import Foundation
import HsCryptoKit

/// Encodes fields according to Ethereum's Application Binary Interface Specification
///
/// - SeeAlso: https://solidity.readthedocs.io/en/develop/abi-spec.html
public final class ABIEncoder {
    static let encodedIntSize = 32

    /// Encoded data
    public var data = Data()

    /// Creates an `ABIEncoder`.
    public init() {}

    /// Encodes an `ABIValue`
    public func encode(_ value: ABIValue) throws {
        switch value {
        case let .uint(_, value):
            try encode(value)
        case let .int(_, value):
            try encode(value)
        case let .address(address):
            try encode(address)
        case let .bool(value):
            try encode(value)
        case let .fixed(_, _, value):
            try encode(value)
        case let .ufixed(_, _, value):
            try encode(value)
        case let .bytes(data):
            try encode(data, static: true)
        case let .function(f, args):
            try encode(signature: f.description)
            try encode(tuple: args)
        case let .array(type, array):
            precondition(!array.contains(where: { $0.type != type }), "Array can only contain values of type \(type)")
            try encode(tuple: array)
        case let .dynamicBytes(data):
            try encode(data, static: false)
        case let .string(string):
            try encode(string)
        case let .dynamicArray(type, array):
            precondition(!array.contains(where: { $0.type != type }), "Array can only contain values of type \(type)")
            try encode(array.count)
            try encode(tuple: array)
        case let .tuple(array):
            try encode(tuple: array)
        }
    }

    /// Encodes a tuple
    public func encode(tuple: [ABIValue]) throws {
        var headSize = 0
        for subvalue in tuple {
            if subvalue.isDynamic {
                headSize += 32
            } else {
                headSize += subvalue.length
            }
        }

        var dynamicOffset = 0
        for subvalue in tuple {
            if subvalue.isDynamic {
                try encode(headSize + dynamicOffset)
                dynamicOffset += subvalue.length
            } else {
                try encode(subvalue)
            }
        }

        for subvalue in tuple where subvalue.isDynamic {
            try encode(subvalue)
        }
    }

    /// Encodes a function call
    public func encode(function: Function, arguments: [Any]) throws {
        try encode(signature: function.description)
        try encode(tuple: function.castArguments(arguments))
    }

    /// Encodes a boolean field.
    public func encode(_ value: Bool) throws {
        data.append(Data(repeating: 0, count: ABIEncoder.encodedIntSize - 1))
        data.append(value ? 1 : 0)
    }

    /// Encodes an unsigned integer.
    public func encode(_ value: UInt) throws {
        try encode(BigUInt(value))
    }

    /// Encodes a `BigUInt` field.
    ///
    /// - Throws: `ABIError.integerOverflow` if the value has more than 256 bits.
    public func encode(_ value: BigUInt) throws {
        let valueData = value.serialize()
        if valueData.count > ABIEncoder.encodedIntSize {
            throw ABIError.integerOverflow
        }

        data.append(Data(repeating: 0, count: ABIEncoder.encodedIntSize - valueData.count))
        data.append(valueData)
    }

    /// Encodes a signed integer.
    public func encode(_ value: Int) throws {
        try encode(BigInt(value))
    }

    /// Encodes a `BigInt` field.
    ///
    /// - Throws: `ABIError.integerOverflow` if the value has more than 256 bits.
    public func encode(_ value: BigInt) throws {
        guard let serialized = value.serialize(bitWidth: ABIEncoder.encodedIntSize) else {
            throw ABIError.integerOverflow
        }
        data.append(serialized)
    }

    /// Encodes a static or dynamic byte array
    public func encode(_ bytes: Data, static: Bool) throws {
        if !`static` {
            try encode(bytes.count)
        }
        let count = min(32, bytes.count)
        let padding = ((count + 31) / 32) * 32 - count
        data.append(bytes[0 ..< count])
        data.append(Data(repeating: 0, count: padding))
    }

    /// Encodes an address
    public func encode(_ address: EthereumAddress) throws {
        let padding = ((address.data.count + 31) / 32) * 32 - address.data.count
        data.append(Data(repeating: 0, count: padding))
        data.append(address.data)
    }

    /// Encodes a string
    ///
    /// - Throws: `ABIError.invalidUTF8String` if the string cannot be encoded as UTF8.
    public func encode(_ string: String) throws {
        guard let bytes = string.data(using: .utf8) else {
            throw ABIError.invalidUTF8String
        }
        try encode(bytes, static: false)
    }

    /// Encodes a function signature
    public func encode(signature: String) throws {
        try data.append(ABIEncoder.encode(signature: signature))
    }

    /// Encodes a function signature
    public static func encode(signature: String) throws -> Data {
        guard let bytes = signature.data(using: .utf8) else {
            throw ABIError.invalidUTF8String
        }
        let hash = Crypto.sha3(bytes)
        return hash[0 ..< 4]
    }
}
