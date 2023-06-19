//
//  HostFinder.swift
//  Disco
//
//  Created by Stanislas Chevallier on 28/11/2018.
//  Copyright © 2018 Syan. All rights reserved.
//

import UIKit
import GBPing

public protocol HostFinderDelegate: NSObjectProtocol {
    func hostFinder(_ hostFinder: HostFinder, progressUpdated progress: Float)
    func hostFinder(_ hostFinder: HostFinder, found ip: String)
    func hostFinder(_ hostFinder: HostFinder, stopped completed: Bool)
}

public class HostFinder: NSObject {
    
    // MARK: Init
    public init(interfaces: [IPv4Interface]) {
        self.interfaces = interfaces
        self.queue.name = String(describing: HostFinder.self)
        self.queue.maxConcurrentOperationCount = 20
        self.queue.qualityOfService = .utility
        super.init()
    }
    
    // MARK: Properties
    public weak var delegate: HostFinderDelegate?
    private let interfaces: [IPv4Interface]

    private var totalCount: Int = 0
    private var finishedCount: Int = 0

    private var queue = OperationQueue()
    private var isRunning: Bool = false
    
    // MARK: Public methods
    public func start() {
        guard !Thread.isMainThread else {
            DispatchQueue.global(qos: .background).async {
                self.start()
            }
            return
        }
        
        guard !isRunning else { return }
        isRunning = true
        
        let queuedIPs = interfaces
            .map { $0.addressesOnSubnet(ignoringMine: true) }
            .reduce([], +)
            .map { $0.stringRepresentation }
        
        totalCount = queuedIPs.count
        
        queuedIPs.forEach { ip in
            let operation = PingOperation(host: ip) { [weak self] available in
                DispatchQueue.main.async {
                    self?.pingFinished(ip, available: available)
                }
            }
            queue.addOperation(operation)
        }
    }
    
    public func stop() {
        queue.cancelAllOperations()
        delegate?.hostFinder(self, stopped: false)
    }
    
    private func pingFinished(_ ip: String, available: Bool) {
        finishedCount += 1

        if available {
            delegate?.hostFinder(self, found: ip)
        }
        
        if finishedCount < totalCount {
            delegate?.hostFinder(self, progressUpdated: Float(finishedCount) / Float(totalCount))
        }
        else {
            isRunning = false
            delegate?.hostFinder(self, stopped: true)
        }
    }
}

private class PingOperation: Operation, GBPingDelegate {
    
    init(host: String, completion: @escaping (_ available: Bool) -> ()) {
        self.host = host
        self.completion = completion
        super.init()
    }

    fileprivate let host: String
    private let completion: (_ available: Bool) -> ()
    private let ping = GBPing()
    
    private var pingDispatchGroup = DispatchGroup()
    private var stats: (successes: Int, failures: Int) = (0, 0)

    override func main() {
        super.main()
        preparePing()
        runPing()
    }
    
    private func preparePing() {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        ping.host = host
        ping.delegate = self
        ping.pingPeriod = 0.2
        ping.timeout = 1
        ping.setup { success, _ in
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        runPing()
    }
    
    private func runPing() {
        guard ping.isReady else { return }
        
        pingDispatchGroup.enter()
        ping.startPinging()
        pingDispatchGroup.wait()
    }
    
    private func updateStats(success: Bool) {
        guard !Thread.isMainThread else {
            DispatchQueue.global(qos: .background).async {
                self.updateStats(success: success)
            }
            return
        }

        if success {
            stats.successes += 1
        }
        else {
            stats.failures += 1
        }

        if stats.successes + stats.failures == 3 {
            // prevent a crash in which GBPing continues pinging even though it was stopped, and it causes an assert crash
            // because stopping releases a lot of properties necessaries to ping. we're shutting down the loop early and
            // waiting a bit before properly stopping
            ping.setValue(false, forKey: "isPinging")
            usleep(UInt32(ping.pingPeriod * TimeInterval(1_000_000)))

            ping.stop()
            pingDispatchGroup.leave()
            
            completion(stats.successes >= stats.failures)
        }
    }
    
    func ping(_ pinger: GBPing, didReceiveReplyWith summary: GBPingSummary) {
        updateStats(success: true)
    }

    func ping(_ pinger: GBPing, didReceiveUnexpectedReplyWith summary: GBPingSummary) {
        updateStats(success: true)
    }

    func ping(_ pinger: GBPing, didTimeoutWith summary: GBPingSummary) {
        updateStats(success: false)
    }

    func ping(_ pinger: GBPing, didFailWithError error: Error) {
        updateStats(success: false)
    }

    func ping(_ pinger: GBPing, didFailToSendPingWith summary: GBPingSummary, error: Error) {
        updateStats(success: false)
    }
}
