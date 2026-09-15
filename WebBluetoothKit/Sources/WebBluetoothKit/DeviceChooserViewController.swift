import UIKit

final class DeviceChooserViewController: UITableViewController {
    
    var onSelect: ((UUID) -> Void)?
    var onCancel: (() -> Void)?
    
    private struct Row {
        var id: UUID
        var name: String
    }
    
    private var rows: [Row] = []
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var didFinish = false
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Bluetooth", bundle: .module, comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel", bundle: .module, comment: ""),
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
        
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "device")
        updateBackground()
    }
    
    func updateDevice(id: UUID, name: String) {
        if let index = rows.firstIndex(where: { $0.id == id }) {
            rows[index].name = name
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        } else {
            rows.append(Row(id: id, name: name))
            rows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            tableView.reloadData()
        }
        updateBackground()
    }
    
    private func updateBackground() {
        if rows.isEmpty {
            let label = UILabel()
            label.text = NSLocalizedString("Scanning…", bundle: .module, comment: "")
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
    
    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        spinner.stopAnimating()
    }
    
    @objc private func cancel() {
        finish()
        onCancel?()
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "device", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = rows[indexPath.row].name
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        finish()
        let id = rows[indexPath.row].id
        onSelect?(id)
        dismiss(animated: true)
    }
}
