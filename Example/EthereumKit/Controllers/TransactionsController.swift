import UIKit
import UIExtensions
import RxSwift

class TransactionsController: UITableViewController {
    private let limit = 20

    private let adapter: EthereumAdapter = Manager.shared.adapter
    private let disposeBag = DisposeBag()

    private var transactions = [TransactionRecord]()
    private var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Transactions"

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero

        adapter.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.tableView.reloadData()
                })
                .disposed(by: disposeBag)

        adapter.transactionsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onTransactionsUpdated()
                })
                .disposed(by: disposeBag)

        loadNext()
    }

    private func onTransactionsUpdated() {
        transactions = []
        loading = false
        loadNext()
    }

    private func loadNext() {
        guard !loading else {
            return
        }

        loading = true

        adapter.transactionsSingle(from: transactions.last?.transactionHashData, limit: limit)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.onLoad(transactions: transactions)
                })
                .disposed(by: disposeBag)
    }

    private func onLoad(transactions: [TransactionRecord]) {
        self.transactions.append(contentsOf: transactions)

        tableView.reloadData()

        if transactions.count == limit {
            loading = false
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: TransactionCell.self), for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(transaction: transactions[indexPath.row], coin: adapter.coin, lastBlockHeight: adapter.lastBlockHeight)
        }

        if indexPath.row > transactions.count - 3 {
            loadNext()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions[indexPath.row]

        UIPasteboard.general.string = transaction.transactionHash

        let alert = UIAlertController(title: "Success", message: "Transaction Hash copied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}
