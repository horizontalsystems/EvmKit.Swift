public class ContractCreationDecoration: TransactionDecoration {
    override public func tags() -> [TransactionTag] {
        [
            TransactionTag(type: .contractCreation),
        ]
    }
}
