//
//  PeripheralDiscovery+.swift
//  IotMobile
//
//  Created by Filip Zymek on 07/12/2024.
//

import CombineCoreBluetooth

extension PeripheralDiscovery: @retroactive Hashable {
    
    public static func == (lhs: PeripheralDiscovery, rhs: PeripheralDiscovery) -> Bool {
        lhs.peripheral == rhs.peripheral && lhs.advertisementData.manufacturerData == rhs.advertisementData.manufacturerData
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral)
        hasher.combine(advertisementData.manufacturerData)
    }
    
    
    var isMoistureSensor: Bool {
        advertisementData.serviceUUIDs?.contains(moistureServiceUUID) ?? false
    }
}
