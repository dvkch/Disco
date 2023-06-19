//
//  IPv4Interface.swift
//  Disco
//
//  Created by Stanislas Chevallier on 30/11/2018.
//  Copyright © 2018 Syan. All rights reserved.
//

import UIKit
import Network

public struct IPv4Interface {

    // MARK: Init
    public init(address: IPv4Address, netmask: IPv4Address, name: String) {
        self.address = address
        self.netmask = netmask
        self.name = name
    }
    
    // MARK: Properties
    public let address: IPv4Address
    public let netmask: IPv4Address
    public let name: String
    
    // MARK: IPv4 methods
    public func addressesOnSubnet(ignoringMine: Bool) -> [IPv4Address] {
        
        let decimalIP   = address.decimalRepresentation
        let decimalMask = netmask.decimalRepresentation
        
        let firstIP =  decimalMask & decimalIP
        let count   = ~decimalMask;
        
        var IPs = (0..<count)
            .compactMap { IPv4Address(decimal: $0 + firstIP) }
            .filter { $0.isValid }
        
        if ignoringMine {
            IPs = IPs.filter { $0.decimalRepresentation != decimalIP }
        }
        
        return IPs
    }
}

extension IPv4Interface : CustomStringConvertible {
    public var description: String {
        return "IPv4Interface: if=\(name), ip=\(address.stringRepresentation), sub=\(netmask.stringRepresentation)"
    }
}

extension IPv4Address {
    public var stringRepresentation: String {
        return debugDescription
    }
    
    public var decimalRepresentation: UInt32 {
        assert(rawValue.count == 4)
        return rawValue.withUnsafeBytes { bytes in
            return bytes.assumingMemoryBound(to: UInt32.self).first!.bigEndian
        }
    }
    
    public init?(decimal: UInt32) {
        var value = decimal.bigEndian
        let data = Data(bytes: &value, count: MemoryLayout<UInt32>.size)
        self.init(data)
    }
    
    public var isValid: Bool {
        let low = (decimalRepresentation >>  0) & 0xFF
        return low > 0 && low < 255
    }
}

extension IPv4Interface {
    public static func deviceNetworks(onlyLocal: Bool, onlyRunning: Bool, allowLoopback: Bool) -> [IPv4Interface] {
        
        // Get list of all interfaces on the local machine
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        defer { freeifaddrs(ifaddr) }
        guard let firstAddr = ifaddr else { return [] }
        
        // Iterate over interfaces
        let nativeInterfaces = sequence(first: firstAddr, next: { $0.pointee.ifa_next })
        return nativeInterfaces.compactMap { interface -> IPv4Interface? in
            
            // Retreive name
            let name = String(utf8String: interface.pointee.ifa_name) ?? ""
            guard name.hasPrefix("en") || !onlyLocal else { return nil }
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            guard interface.pointee.isRunning || !onlyRunning else { return nil }
            guard !interface.pointee.isLoopback || allowLoopback else { return nil }
            
            // Find valid addresses
            guard let address = interface.pointee.address as? IPv4Address else { return nil }
            guard let netmask = interface.pointee.netmask as? IPv4Address else { return nil }
            
            return IPv4Interface(address: address, netmask: netmask, name: name)
        }
    }
}

fileprivate extension ifaddrs {
    var isRunning: Bool {
        return Int32(ifa_flags) & (IFF_UP|IFF_RUNNING) == (IFF_UP|IFF_RUNNING)
    }
    
    var isLoopback: Bool {
        return Int32(ifa_flags) & IFF_LOOPBACK == IFF_LOOPBACK
    }
    
    var address: IPAddress? {
        ifa_addr.address
    }
    
    var netmask: IPAddress? {
        ifa_netmask.address
    }
}

fileprivate extension UnsafeMutablePointer where Pointee == sockaddr {
    var address: IPAddress? {
        if pointee.sa_family == AF_INET {
            return self.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { pointer in
                var addr = pointer.pointee.sin_addr
                var chars = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                inet_ntop(
                    AF_INET,
                    &addr,
                    &chars,
                    socklen_t(INET_ADDRSTRLEN)
                )
                let string = String(cString: chars)
                return IPv4Address(string)
            }
        }
        if pointee.sa_family == AF_INET6 {
            return self.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { pointer in
                var addr = pointer.pointee.sin6_addr
                var chars = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                inet_ntop(
                    AF_INET6,
                    &addr,
                    &chars,
                    socklen_t(INET6_ADDRSTRLEN)
                )
                let string = String(cString: chars)
                return IPv6Address(string)
            }
        }
        return nil
    }
}
