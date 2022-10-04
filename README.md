# EvmKit.Swift

`EvmKit.Swift` is a native (Swift), secure, reactive and extensible EVM client toolkit for iOS platform. It can be used by ETH / ERC20 wallet or by dApp client for any kind of interactions with Ethereum and other EVM blockchains.

## Features

- Ethereum wallet support, including internal Ether transfer transactions
- Reactive-functional API
- Implementation of Ethereum's JSON-RPC client API over HTTP or WebSocket
- Support for Infura
- Support for Etherscan
- Sync account state/balance
- Sync / Send / Receive Ethereum transactions 
- Internal transactions retrieved from Etherscan
- Reactive API for Smart Contracts
- Reactive API for wallet
- Restore with mnemonic phrase

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

`EvmKit.Kit` instance requires to be started with `start` command:

```swift
evmKit.start()
evmKit.stop()
```

### Getting wallet data

You can get `account state`, `last block height`, `sync state`, `transactions sync state` and some others synchronously: 

```swift
guard let state = evmKit.accountState else {
    return
}

state.balance    // 2937096768
state.nonce      // 10

evmKit.lastBlockHeight  // 10000000
```

You also can subscribe to Rx observables of those and some others:

```swift
evmKit.accountStateObservable.subscribe(onNext: { state in print("balance: \(state.balance); nonce: \(state.nonce)") })
evmKit.lastBlockHeightObservable.subscribe(onNext: { height in print(height) })
evmKit.syncStateObservable.subscribe(onNext: { state in print(state) })
evmKit.transactionsSyncStateObservable.subscribe(onNext: { state in print(state) })

// Subscribe to all EVM transactions synced by the kit
evmKit.allTransactionsObservable.subscribe(onNext: { transactions, initialSync in print(transactions.count) })
```

### Send Transaction

```swift
let decimalAmount: Decimal = 0.1
let amount = BigUInt(decimalAmount.roundedString(decimal: decimal))!
let address = try Address(hex: "0x...")

evmKit
        .sendSingle(address: address, value: amount, gasPrice: 50_000_000_000, gasLimit: 1_000_000_000_000)
        .subscribe(onSuccess: { transaction in 
            print(transaction.transaction.hash.hex)  // sendSingle returns FullTransaction object which contains transaction, receiptWithLogs and internalTransactions
        })
```

### Estimate Gas Limit

```swift
let decimalAmount: Decimal = 0.1
let amount = BigUInt(decimalAmount.roundedString(decimal: decimal))!
let address = try Address(hex: "0x...")

evmKit
        .estimateGas(to: address, amount: amount, gasPrice: 50_000_000_000)
        .subscribe(onSuccess: { gasLimit in 
            print(gasLimit)
        })
```

## Extending

### Add transaction syncer

Some smart contracts store some information concerning your address, which you can't retrieve in a standard way over RPC. If you have an external API to get them from, you can create a custom syncer and add it to EvmKit. It will sync all the transactions your syncer gives.

[Eip20TransactionSyncer](https://github.com/horizontalsystems/Eip20Kit.Swift/blob/master/Sources/Eip20Kit/Core/Eip20TransactionSyncer.swift) is a good example of this. It gets token transfer transactions from Etherscan and feeds EvmKit syncer with them. It is added to EvmKit as following:
```swift
let transactionSyncer = Eip20TransactionSyncer(...)
evmKit.add(syncer: transactionSyncer)
```

### Smart contract call

In order to make a call to any smart contract, you can use `evmKit.sendSingle(transactionData:,gasPrice:,gasLimit:)` method. You need to create an instance of `TransactionData` object. Currently, we don't have an ABI or source code parser. Please, look in `Eip20Kit.Swift` and `UniswapKit.Swift` to see how `TransactionData` object is formed.

## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 13+

## Installation

### Swift Package Manager

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/EvmKit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## Example Project

All features of the library are used in example project located in `iOS Example` folder. It can be referred as a starting point for usage of the library.

## License

The `EvmKit.Swift` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/ethereum-kit-ios/blob/master/LICENSE).

