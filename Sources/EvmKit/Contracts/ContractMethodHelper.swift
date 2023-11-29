import BigInt
import Foundation
import HsCryptoKit
import HsExtensions

public class ContractMethodHelper {
    public struct DynamicStructParameter {
        let arguments: [Any]

        public init(_ arguments: [Any]) {
            self.arguments = arguments
        }
    }

    public struct StaticStructParameter {
        let arguments: [Any]

        public init(_ arguments: [Any]) {
            self.arguments = arguments
        }
    }

    public struct MulticallParameters {
        let arguments: [Any]

        public init(_ arguments: [Any]) {
            self.arguments = arguments
        }
    }

    public static func encodedABI(methodId: Data, arguments: [Any]) -> Data {
        var data = methodId
        var arraysData = Data()

        for argument in arguments {
            switch argument {
            case let argument as BigUInt:
                data += prePad(data32: argument.serialize())
            case let argument as String:
                data += prePad(data32: argument.hs.hexData ?? Data())
            case let argument as Address:
                data += prePad(data32: argument.raw)
            case let argument as [Address]:
                data += prePad(data32: BigUInt(arguments.count * 32 + arraysData.count).serialize())
                arraysData += encode(data32Array: argument.map(\.raw))
            case let argument as Data:
                data += prePad(data32: BigUInt(arguments.count * 32 + arraysData.count).serialize())
                arraysData += prePad(data32: BigUInt(argument.count).serialize()) + argument
            case let argument as DynamicStructParameter:
                data += prePad(data32: BigUInt(arguments.count * 32 + arraysData.count).serialize())
                arraysData += encodedABI(methodId: Data(), arguments: argument.arguments)
            case let argument as MulticallParameters:
                data += prePad(data32: BigUInt(arguments.count * 32 + arraysData.count).serialize())
                arraysData += encode(dataArray: argument.arguments.compactMap { $0 as? Data })
            default:
                ()
            }
        }

        return data + arraysData
    }

    public class func decodeABI(inputArguments: Data, argumentTypes: [Any]) -> [Any] {
        var position = 0
        var parsedArguments = [Any]()

        for type in argumentTypes {
            switch type {
            case is BigUInt.Type:
                let data = Data(inputArguments[position ..< position + 32])
                parsedArguments.append(BigUInt(data))
                position += 32

            case is [BigUInt].Type:
                let arrayPosition = parseInt(data: inputArguments[position ..< position + 32])
                let array: [BigUInt] = parseBigUInt(startPosition: arrayPosition, inputArguments: inputArguments)
                parsedArguments.append(array)
                position += 32

            case is Address.Type:
                let data = Data(inputArguments[position ..< position + 32])
                parsedArguments.append(Address(raw: data))
                position += 32

            case is [Address].Type:
                let arrayPosition = parseInt(data: inputArguments[position ..< position + 32])
                let array: [Address] = parseAddresses(startPosition: arrayPosition, inputArguments: inputArguments)
                parsedArguments.append(array)
                position += 32

            case is Data.Type:
                let dataPosition = parseInt(data: inputArguments[position ..< position + 32])
                let data: Data = parseData(startPosition: dataPosition, inputArguments: inputArguments)
                parsedArguments.append(data)
                position += 32

            case is [Data].Type:
                let dataPosition = parseInt(data: inputArguments[position ..< position + 32])
                let data: [Data] = parseDataArray(startPosition: dataPosition, inputArguments: inputArguments)
                parsedArguments.append(data)
                position += 32

            case is MulticallParameters.Type:
                let dataPosition = parseInt(data: inputArguments[position ..< position + 32])
                let data: [Data] = parseContractDataArray(startPosition: dataPosition, inputArguments: inputArguments)
                parsedArguments.append(data)
                position += 32

            case let object as DynamicStructParameter:
                let argumentsPosition = parseInt(data: inputArguments[position ..< position + 32])
                let data: [Any] = decodeABI(inputArguments: Data(inputArguments[argumentsPosition ..< inputArguments.count]), argumentTypes: object.arguments)
                parsedArguments.append(data)
                position += 32

            case let object as StaticStructParameter:
                let data: [Any] = decodeABI(inputArguments: Data(inputArguments[position ..< inputArguments.count]), argumentTypes: object.arguments)
                parsedArguments.append(data)
                position += 32 * object.arguments.count

            default: ()
            }
        }

        return parsedArguments
    }

    public static func methodId(signature: String) -> Data {
        Crypto.sha3(signature.data(using: .ascii)!)[0 ... 3]
    }

    private class func parseInt(data: Data) -> Int {
        Data(data.reversed()).hs.to(type: Int.self)
    }

    private class func parseAddresses(startPosition: Int, inputArguments: Data) -> [Address] {
        let arrayStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition ..< arrayStartPosition])
        var addresses = [Address]()

        for i in 0 ..< size {
            let addressData = Data(inputArguments[(arrayStartPosition + 32 * i) ..< (arrayStartPosition + 32 * (i + 1))])
            addresses.append(Address(raw: addressData))
        }

        return addresses
    }

    private class func parseBigUInt(startPosition: Int, inputArguments: Data) -> [BigUInt] {
        let arrayStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition ..< arrayStartPosition])
        var bigUInts = [BigUInt]()

        for i in 0 ..< size {
            let bigUIntData = Data(inputArguments[(arrayStartPosition + 32 * i) ..< (arrayStartPosition + 32 * (i + 1))])
            bigUInts.append(BigUInt(bigUIntData))
        }

        return bigUInts
    }

    private class func parseData(startPosition: Int, inputArguments: Data) -> Data {
        let dataStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition ..< dataStartPosition])
        return Data(inputArguments[dataStartPosition ..< (dataStartPosition + size)])
    }

    private class func parseContractDataArray(startPosition: Int, inputArguments: Data) -> [Data] {
        let arrayStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition ..< arrayStartPosition])
        var dataArray = [Data]()

        for i in 0 ..< size {
            let position = parseInt(data: inputArguments[(arrayStartPosition + 32 * i) ..< (arrayStartPosition + 32 * (i + 1))])

            let startMethodPosition = arrayStartPosition + position
            let methodSize = parseInt(data: inputArguments[startMethodPosition ..< startMethodPosition + 32])
            let method = inputArguments[startMethodPosition + 32 ..< startMethodPosition + 32 + methodSize]
            dataArray.append(method)
        }

        return dataArray
    }

    private class func parseDataArray(startPosition: Int, inputArguments: Data) -> [Data] {
        let arrayStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition ..< arrayStartPosition])
        var dataArray = [Data]()

        for i in 0 ..< size {
            dataArray.append(Data(inputArguments[(arrayStartPosition + 32 * i) ..< (arrayStartPosition + 32 * (i + 1))]))
        }

        return dataArray
    }

    private static func encode(data32Array: [Data]) -> Data {
        var data = prePad(data32: BigUInt(data32Array.count).serialize())

        for item in data32Array {
            data += prePad(data32: item)
        }

        return data
    }

    private static func encode(dataArray: [Data]) -> Data {
        var data = prePad(data32: BigUInt(dataArray.count).serialize())

        let correctedArray = dataArray.map { postPad(data: $0) }

        for index in 0 ..< correctedArray.count {
            let previousData = correctedArray.prefix(index)
            let previousDataLength = previousData.reduce(0) { $0 + $1.count + 32 }
            data += prePad(data32: BigUInt(32 * correctedArray.count + previousDataLength).serialize())
        }

        for index in 0 ..< correctedArray.count {
            data += prePad(data32: BigUInt(dataArray[index].count).serialize())
            data += correctedArray[index]
        }

        return data
    }

    private static func prePad(data32: Data) -> Data {
        Data(repeating: 0, count: max(0, 32 - data32.count)) + data32
    }

    private static func postPad(data: Data) -> Data {
        guard (data.count % 32) != 0 else {
            return data
        }

        return data + Data(repeating: 0, count: max(0, 32 - data.count % 32))
    }
}
