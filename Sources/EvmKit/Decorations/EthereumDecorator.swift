import BigInt

class EthereumDecorator {
    private let address: Address

    init(address: Address) {
        self.address = address
    }
}

extension EthereumDecorator: ITransactionDecorator {
    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions _: [InternalTransaction], eventInstances _: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from, let value else {
            return nil
        }

        guard let to else {
            return ContractCreationDecoration()
        }

        if let contractMethod, contractMethod is EmptyMethod {
            if from == address {
                return OutgoingDecoration(to: to, value: value, sentToSelf: to == address)
            }

            if to == address {
                return IncomingDecoration(from: from, value: value)
            }
        }

        return nil
    }
}
