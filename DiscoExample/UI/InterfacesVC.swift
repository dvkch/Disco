//
//  InterfacesVC.swift
//  DiscoExample
//
//  Created by syan on 19/06/2023.
//

import UIKit
import Disco

class InterfacesVC: ViewController {
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interfaces"
        
        kindSegmentView.selectedSegmentIndex = 1
        kindSegmentView.addTarget(self, action: #selector(kindChanged), for: .valueChanged)
        tableView.tableHeaderView = kindSegmentView

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

        updateInterfaces(reloadAfter: 5)
    }
    
    // MARK: Properties
    private var interfaces: [any IPInterface] = [] {
        didSet {
            updateVisibleInterfaces()
        }
    }
    
    private var visibleInterfaces: [any IPInterface] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: Views
    private let kindSegmentView = UISegmentedControl(items: ["All", "IPv4", "IPv6"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // MARK: Actions
    @objc private func kindChanged() {
        updateVisibleInterfaces()
    }
    
    // MARK: Content
    private func updateInterfaces(reloadAfter: TimeInterval) {
        interfaces = (
            IPv4Interface.availableInterfaces() +
            IPv6Interface.availableInterfaces()
        ).sorted(by: { $0.name < $1.name })

        DispatchQueue.main.asyncAfter(deadline: .now() + reloadAfter) {
            self.updateInterfaces(reloadAfter: reloadAfter)
        }
    }
    
    private func updateVisibleInterfaces() {
        visibleInterfaces = interfaces.filter { interface in
            if interface is IPv4Interface {
                return kindSegmentView.selectedSegmentIndex == 0 || kindSegmentView.selectedSegmentIndex == 1
            }
            if interface is IPv6Interface {
                return kindSegmentView.selectedSegmentIndex == 0 || kindSegmentView.selectedSegmentIndex == 2
            }
            return false
        }
    }
}

extension InterfacesVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleInterfaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let iface = visibleInterfaces[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(iface.name): \(iface.address) - \(iface.netmask)"
        cell.detailTextLabel?.text = [
            iface.isRunning  ? "Running"  : "Not running",
            iface.isLocal    ? "Local"    : "Not local",
            iface.isLoopback ? "Loopback" : "Not loopback",
        ].joined(separator: " - ")

        if iface.isLocal, iface is IPv4Interface {
            cell.accessoryType = .disclosureIndicator
        }
        else {
            cell.accessoryType = .none
        }
        return cell
    }
}

extension InterfacesVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let iface = visibleInterfaces[indexPath.row]
        if iface.isLocal, let ip4Iface = iface as? IPv4Interface {
            navigationController?.pushViewController(HostsFinderVC(interface: ip4Iface), animated: true)
        }
    }
}
