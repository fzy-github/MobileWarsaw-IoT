//
//  SensorListViewModel.swift
//  IotMobile
//
//  Created by Filip Zymek on 06/12/2024.
//
import SwiftUI
import Combine
import CombineCoreBluetooth
import Dependencies

@Observable
final class SensorListViewModel: NSObject {
   
    var peripherals: [PeripheralDiscovery] = []
    var isBluetoothOn: Bool = true
    var isScanning: Bool { scanTask != nil }
    var showEnableBluetooth: Bool = false
    var connectedSensor: PeripheralDiscovery?
    
    @ObservationIgnored
    @Dependency(\.centralManager) private var centralManager
    private var scanTask: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    
    override init() {
        super.init()
        monitorBluetoothState()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    func startScanning() {
        
        guard isBluetoothOn else {
            showEnableBluetooth = true
            return
        }
        
        scanTask = centralManager.scanForPeripherals(withServices: [moistureServiceUUID])
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] discovery in
                guard let self = self else { return }
                if let index = self.peripherals.firstIndex(where: { $0.id == discovery.id }) {
                    self.peripherals[index] = discovery
                } else {
                    self.peripherals.append(discovery)
                }
            })
    }
    
    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        peripherals = []
    }
    
    func connect(to peripheral: PeripheralDiscovery) {
        connectedSensor = peripheral
    }
    
    func monitorBluetoothState() {
        centralManager.didUpdateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isBluetoothOn = state == .poweredOn
            }
            .store(in: &cancellables)
    }
    
}
