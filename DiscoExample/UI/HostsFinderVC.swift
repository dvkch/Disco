//
//  HostsFinderVC.swift
//  DiscoExample
//
//  Created by syan on 19/06/2023.
//

import UIKit
import Disco
import Network

class HostsFinderVC: ViewController {
    
    init(interface: IPv4Interface) {
        self.interface = interface
        self.finder = .init(interfaces: [interface])
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hosts reachable via \(interface.name)"
        scanButton.target = self
        scanButton.action = #selector(scanButtonTap)
        navigationItem.rightBarButtonItem = scanButton

        tableView.register(DetailedCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        finder.delegate = self
        finder.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        finder.stop()
    }
    
    // MARK: Properties
    let interface: IPv4Interface
    private let finder: HostsFinder
    private var hosts: [IPv4Address] = [] {
        didSet {
            if hosts != oldValue {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: Views
    private let scanButton = UIBarButtonItem()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: Actions
    @objc private func scanButtonTap() {
        if finder.isRunning {
            finder.stop()
        }
        else {
            finder.start()
            hosts = []
        }
    }
    
    // MARK: Content
    private func updateStatusButton(progress: Float?) {
        if let progress {
            scanButton.title = "\(Int(progress * 100))%"
        }
        else {
            scanButton.title = "Scan"
        }
    }
}

extension HostsFinderVC: HostsFinderDelegate {
    func hostsFinder(_ hostsFinder: HostsFinder, found ip: IPv4Address) {
        var hosts = self.hosts
        hosts.append(ip)
        hosts.sort(by: { $0.decimalRepresentation < $1.decimalRepresentation })
        self.hosts = hosts
    }
    
    func hostsFinder(_ hostsFinder: HostsFinder, progressUpdated progress: Float) {
        updateStatusButton(progress: progress)
    }

    func hostsFinder(_ hostsFinder: HostsFinder, stopped completed: Bool) {
        updateStatusButton(progress: nil)
    }
}

extension HostsFinderVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let host = hosts[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = host.stringRepresentation
        cell.detailTextLabel?.text = HostnameResolver.shared.hostname(for: host.stringRepresentation) ?? "<no hostname>"
        return cell
    }
}

extension HostsFinderVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
