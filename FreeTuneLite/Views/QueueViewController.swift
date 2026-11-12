import UIKit

final class QueueViewController: UIViewController {
    private let table = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Queue"
        view.backgroundColor = Theme.bg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(tapDone)
        )

        table.backgroundColor = .clear
        table.separatorColor = Theme.separator
        table.rowHeight = 58
        table.dataSource = self
        table.delegate = self
        table.contentInsetAdjustmentBehavior = .never

        view.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        PlayerManager.shared.listen(self) { [weak self] in
            self?.table.reloadData()
        }
        table.reloadData()
    }

    @objc private func tapDone() {
        dismiss(animated: true, completion: nil)
    }
}

extension QueueViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PlayerManager.shared.queue.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QueueCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "QueueCell")
        let p = PlayerManager.shared
        let track = p.queue[indexPath.row]
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: indexPath.row == p.index ? .bold : .regular)
        cell.textLabel?.textColor = indexPath.row == p.index ? Theme.accent : Theme.text
        cell.textLabel?.text = track.name
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 11)
        cell.detailTextLabel?.textColor = Theme.textDim
        cell.detailTextLabel?.text = track.artistName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerManager.shared.jumpTo(indexPath.row)
        table.reloadData()
    }
}
