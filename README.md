# EvmKit.Swift

`EvmKit.Swift` is a native(Swift) toolkit for EVM compatible networks. It's implemented and used by [Unstoppable Wallet](https://github.com/horizontalsystems/unstoppable-wallet-ios), a multi-currency crypto wallet. Together with other libraries `Eip20Kit.Swift`, `NftKit.Swift`, `UniswapKit.Swift`, `OneInchKit.swift` it implements a lot of features of the DeFi world natively *(no need for WalletConnect)* out-of-the-box.

## Core Features

- [x] Restore with **mnemonic phrase**, **BIP39 Seed**, **EVM private key**, or simply an **Ethereum address**
- [x] Local storage of account data (ETH balance and transactions)
- [x] Synchronization over **HTTP/WebSocket**
- [x] **Watch accounts**. Restore with any address
- [x] Ethereum Name Service **(ENS) support**
- [x] **EIP-1559** Gas Prices with live updates
- [x] Reactive-functional API by [`RxSwift`](https://github.com/ReactiveX/RxSwift)
- [x] Implementation of Ethereum's JSON-RPC API
- [x] Support for Infura and Etherscan
- [x] Can be extended to natively support any smart contract

## Blockchains supported

Any EVM blockchain that supports the Ethereum's RPC API and has an Etherscan-like block explorer can be easily integrated to your wallet using `EvmKit.Swift`. The following blockchains are currently integrated to `Unstoppable Wallet`:

- Ethereum
- Binance Smart Chain
- Polygon
- ArbitrumOne
- Optimism
- Avalanche C-Chain


## Usage

### Initialization

First you need to initialize an `EvmKit.Kit` instance

```swift
import EvmKit

let address = try Address(hex: "0x...")

let evmKit = try Kit.instance(
        address: address,
        chain: .ethereum,
        rpcSource: .ethereumInfuraWebsocket(projectId: "...", projectSecret: "..."),
        transactionSource: .ethereumEtherscan(apiKey: "..."),
        walletId: "unique_wallet_id",
        minLogLevel: .error
)
```

### Starting and Stopping

`EvmKit.Kit` instance requires to be started with `start` command. This start the process of synchronization with the blockchain state.

```swift
evmKit.start()
evmKit.stop()
```

### Get wallet data

You can get `account state`, `last block height`, `sync state`, `transactions sync state` and some others synchronously: 

```swift
guard let state = evmKit.accountState else {
    return
}

state.balance    // 2937096768
state.nonce      // 10

evmKit.lastBlockHeight  // 10000000
```

You also can subscribe to Rx observables of those and more:

```swift
evmKit.accountStateObservable.subscribe(onNext: { state in print("balance: \(state.balance); nonce: \(state.nonce)") })
evmKit.lastBlockHeightObservable.subscribe(onNext: { height in print(height) })
evmKit.syncStateObservable.subscribe(onNext: { state in print(state) })

// Subscribe to ETH transactions synced by the kit
evmKit.transactionsObservable(tagQueries: [TransactionTagQuery(protocol: .native)]).subscribe(onNext: { transactions in print(transactions.count) })

// Subscribe to all EVM transactions
evmKit.allTransactionsObservable.subscribe(onNext: { transactions, initialSync in print(transactions.count) })
```

### Send Transaction

To send a transaction you need a Signer object. Here's how you can create it using Mnemonic seed phrase:

```swift
let words = ["mnemonic", "words", ...]

guard let seed = Mnemonic.seed(mnemonic: words) else {
    return
}

let signer = try Signer.instance(seed: seed, chain: .ethereum)
```


Now you can use it to sign an Ethereum transaction:


```swift
// This must be retained until the transaction send is completed
let disposeBag = DisposeBag()

let to = try EvmKit.Address(hex: "0x..recipient..address..here")
let amount = BigUInt("100000000000000000")                         // 0.1 ETH in WEIs
let gasPrice = GasPrice.legacy(gasPrice: 50_000_000_000)

// Construct TransactionData which is the key payload of any EVM transaction
let transactionData = evmKit.transferTransactionData(to: to, value: amount)

// Estimate gas for the transaction
let estimateGasSingle = evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)

// Generate a raw transaction which is ready to be signed. This step also synchronizes the nonce
let rawTransactionSingle = estimateGasSingle.flatMap { estimatedGasLimit in
    evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: estimatedGasLimit)
}

let sendSingle = rawTransactionSingle.flatMap { rawTransaction in
    // Sign the transaction
    let signature = try signer.signature(rawTransaction: rawTransaction)
    
    // Send the transaction to RPC node
    return evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
}

// This step is needed for Rx reactive code to run
sendSingle
    .subscribe(
        onSuccess: { fullTransaction in
            // sendSingle returns FullTransaction object that contains transaction and a transaction decoration
            let transaction = fullTransaction.transaction
            print("Transaction sent: \(transaction.hash.hs.hexString)")
            print("To: \(transaction.to!.eip55)")
            print("Amount: \(transaction.value!.description)")
        }, onError: { error in
            print("Send failed: \(error)")
        }
    )
    .disposed(by: disposeBag)
```

### Get ETH transactions

The following code retrieves the transactions that have `ETH` coin incoming or outgoing, including the transactions where `ETH` is received in internal transactions.

```swift
evmKit.transactionsSingle(tagQueries: [TransactionTagQuery(protocol: .native)])
    .subscribe(
        onSuccess: { fullTransactions in
            for fullTransaction in fullTransactions {
                let transaction = fullTransaction.transaction
                print("Transaction hash: \(transaction.hash.hs.hexString)")

                switch fullTransaction.decoration {
                case let decoration as IncomingDecoration:
                    print("From: \(decoration.from.eip55)")
                    print("Amount: \(decoration.value.description)")

                case let decoration as OutgoingDecoration:
                    print("To: \(decoration.to.eip55)")
                    print("Amount: \(decoration.value.description)")

                ...

                }
            }
        }, onError: { error in
            print("Couldn't get transactions: \(error)")
        }
    )
    .disposed(by: disposeBag)
}
```

## Extending


### Smart contract call

In order to send an EVM smart contract call transaction, you need to create an instance of `TransactionData` object. Then you can sign and send it as seen above. Please look in `Eip20Kit.Swift` and `UniswapKit.Swift` for an examples.


## Installation

### Swift Package Manager

[Swift Package Manager](https://www.swift.org/package-manager) is a dependency manager for Swift projects. You can install it with the following command:

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/EvmKit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## Prerequisites

* Xcode 10.0+
* Swift 5.5+
* iOS 13+


## Example Project

All features of the library are used in example project located in `iOS Example` folder. It can be referred as a starting point for usage of the library.

## License

The `EvmKit.Swift` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/ethereum-kit-ios/blob/master/LICENSE).

