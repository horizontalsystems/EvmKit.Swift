import Combine
import EvmKit
import HsExtensions
import SnapKit
import UIKit

class SendController: UIViewController {
    private let adapter: EthereumAdapter = Manager.shared.adapter
    private let feeHistoryProvider = EIP1559GasPriceProvider(evmKit: Manager.shared.evmKit)
//    private var gasPrice = GasPrice.legacy(gasPrice: 50_000_000_000)
    private var gasPrice = GasPrice.eip1559(maxFeePerGas: 150_000_000_000, maxPriorityFeePerGas: 600_000_000)
    private var estimateGasLimit: Int?
    private var cancellables = Set<AnyCancellable>()

    private let addressTextField = UITextField()
    private let amountTextField = UITextField()
    private let gasPriceLabel = UILabel()
    private let sendButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"

        let addressLabel = UILabel()

        view.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = .gray
        addressLabel.text = "Address:"

        let addressTextFieldWrapper = UIView()

        view.addSubview(addressTextFieldWrapper)
        addressTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(addressLabel.snp.bottom).offset(8)
        }

        addressTextFieldWrapper.borderWidth = 1
        addressTextFieldWrapper.borderColor = .black.withAlphaComponent(0.1)
        addressTextFieldWrapper.layer.cornerRadius = 8

        addressTextFieldWrapper.addSubview(addressTextField)
        addressTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        addressTextField.font = .systemFont(ofSize: 13)

        let amountLabel = UILabel()

        view.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(addressTextFieldWrapper.snp.bottom).offset(24)
        }

        amountLabel.font = .systemFont(ofSize: 14)
        amountLabel.textColor = .gray
        amountLabel.text = "Amount:"

        let amountTextFieldWrapper = UIView()

        view.addSubview(amountTextFieldWrapper)
        amountTextFieldWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
        }

        amountTextFieldWrapper.borderWidth = 1
        amountTextFieldWrapper.borderColor = .black.withAlphaComponent(0.1)
        amountTextFieldWrapper.layer.cornerRadius = 8

        amountTextFieldWrapper.addSubview(amountTextField)
        amountTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        amountTextField.font = .systemFont(ofSize: 13)

        let ethLabel = UILabel()

        view.addSubview(ethLabel)
        ethLabel.snp.makeConstraints { make in
            make.leading.equalTo(amountTextFieldWrapper.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(amountTextFieldWrapper)
        }

        ethLabel.font = .systemFont(ofSize: 13)
        ethLabel.textColor = .black
        ethLabel.text = "ETH"

        view.addSubview(gasPriceLabel)
        gasPriceLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(amountTextFieldWrapper.snp.bottom).offset(24)
        }

        gasPriceLabel.font = .systemFont(ofSize: 12)
        gasPriceLabel.textColor = .gray

        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(gasPriceLabel.snp.bottom).offset(24)
        }

        sendButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.setTitleColor(.lightGray, for: .disabled)
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        feeHistoryProvider.feeHistoryPublisher(blocksCount: 2, rewardPercentile: [50])
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    print("FeeHistoryError: \(error)")
                default: ()
                }
            }, receiveValue: { [weak self] history in
                self?.handle(feeHistory: history)
            })
            .store(in: &cancellables)

        addressTextField.addTarget(self, action: #selector(updateEstimatedGasPrice), for: .editingChanged)
        amountTextField.addTarget(self, action: #selector(updateEstimatedGasPrice), for: .editingChanged)

        updateEstimatedGasPrice()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc private func updateEstimatedGasPrice() {
        updateGasLimit(value: nil)

        guard let addressHex = addressTextField.text?.trimmingCharacters(in: .whitespaces),
              let valueText = amountTextField.text,
              let value = Decimal(string: valueText),
              !value.isZero
        else {
            return
        }

        guard let address = try? Address(hex: addressHex) else {
            return
        }

        gasPriceLabel.text = "Loading..."

        Task { [weak self, adapter, gasPrice] in
            do {
                let gasLimit = try await adapter.estimatedGasLimit(to: address, value: value, gasPrice: gasPrice)
                self?.updateGasLimit(value: gasLimit)
            } catch {
                print(error)
                self?.updateGasLimit(value: nil)
            }
        }
    }

    @objc private func send() {
        guard let addressHex = addressTextField.text?.trimmingCharacters(in: .whitespaces),
              let estimateGasLimit
        else {
            return
        }

        guard let address = try? Address(hex: addressHex) else {
            show(error: "Invalid address")
            return
        }

        guard let amountString = amountTextField.text, let amount = Decimal(string: amountString) else {
            show(error: "Invalid amount")
            return
        }

        Task { [weak self, adapter, gasPrice] in
            do {
                try await adapter.send(to: address, amount: amount, gasLimit: estimateGasLimit, gasPrice: gasPrice)
                self?.handleSuccess(address: address, amount: amount)
            } catch {
                self?.show(error: "Send failed: \(error)")
            }
        }
    }

    private func handle(feeHistory: FeeHistory) {
        var recommendedBaseFee: Int? = nil
        var recommendedPriorityFee: Int? = nil

        if let baseFee = feeHistory.baseFeePerGas.last {
            recommendedBaseFee = baseFee
        }

        var priorityFeeSum = 0
        var priorityFeesCount = 0
        for priorityFeeArray in feeHistory.reward {
            if let priorityFee = priorityFeeArray.first {
                priorityFeeSum += priorityFee
                priorityFeesCount += 1
            }
        }

        if priorityFeesCount > 0 {
            recommendedPriorityFee = priorityFeeSum / feeHistory.reward.count
        }

        if let baseFee = recommendedBaseFee, let tip = recommendedPriorityFee {
            gasPrice = .eip1559(maxFeePerGas: baseFee + tip, maxPriorityFeePerGas: tip)
        }
    }

    @MainActor
    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    @MainActor
    private func handleSuccess(address: Address, amount: Decimal) {
        addressTextField.text = ""
        amountTextField.text = ""

        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    @MainActor
    private func updateGasLimit(value: Int?) {
        sendButton.isEnabled = value != nil
        estimateGasLimit = value

        let gasLimitPrefix = "Gas limit: "

        if let value {
            gasPriceLabel.text = gasLimitPrefix + "\(value)"
        } else {
            gasPriceLabel.text = gasLimitPrefix + "n/a"
        }
    }
}
