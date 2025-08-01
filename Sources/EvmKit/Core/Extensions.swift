import BigInt
import GRDB

extension BigUInt: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BigUInt? {
        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
            return BigUInt(value)
        }

        return nil
    }
}

func isOptional(_ type: (some Any).Type) -> Bool {
    type is OptionalProtocol.Type
}

protocol OptionalProtocol {
    static var wrappedType: Any.Type { get }
}

extension Optional: OptionalProtocol {
    static var wrappedType: Any.Type {
        Wrapped.self
    }
}
