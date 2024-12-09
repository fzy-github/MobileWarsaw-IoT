//
//  SensorDetailsView.swift
//  IotMobile
//
//  Created by Filip Zymek on 07/12/2024.
//
import SwiftUI
import CombineCoreBluetooth
import Dependencies

@Observable
final class SensorDetailsViewModel {
    
    private let sensor: PeripheralDiscovery
    
    @ObservationIgnored
    @Dependency(\.centralManager) private var centralManager
    
    private var cancellables: Set<AnyCancellable> = []
    private var rawMoistureValue: Result<Data, Error>?
    private var subscriptionTask: AnyCancellable?
    
    var connectionResult: Result<Peripheral, Error>? {
        didSet {
            if case .success = connectionResult {
                startServiceDiscovery()
            }
        }
    }
    
    var connectedPeripheral: Peripheral? {
        guard case let .success(peripheral) = connectionResult else { return nil }
        return peripheral
    }
    
    var connectionError: Error? {
        guard case let .failure(error) = connectionResult else { return nil }
        return error
    }
    
    var name: String {
        sensor.peripheral.name ?? "Unknown \(sensor.id.uuidString)"
    }
    
    var moistureReadError: Error? {
        guard case let .failure(error) = rawMoistureValue else { return nil }
        return error
    }
    
    var moistureValue: String? {
        guard let response = rawMoistureValue,
              case let .success(data) = response,
              let stringValue = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        
        return stringValue + " %"
    }
    
    init(sensor: PeripheralDiscovery) {
        self.sensor = sensor
    }
    
    deinit {
        stopSubscriptions()
        subscriptionTask?.cancel()
        subscriptionTask = nil
    }
    
    func connect() {
        centralManager.didDisconnectPeripheral
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripheral in
                self?.connectionResult = .failure(CBError(.connectionFailed))
                self?.stopSubscriptions()
            }
            .store(in: &cancellables)
        
        centralManager.connect(sensor.peripheral)
            .map(Result.success)
            .catch { Just(Result.failure($0)) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                self.connectionResult = $0
            })
            .store(in: &cancellables)
        
        
    }
    
    func disconnect() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        centralManager.cancelPeripheralConnection(sensor.peripheral)
    }
    
    func stopSubscriptions() {
        cancellables.forEach { $0.cancel() }
        subscriptionTask?.cancel()
        subscriptionTask = nil
    }
    
    func startServiceDiscovery() {
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral")
            connectionResult = .failure(CBError(.connectionFailed))
            return
        }
        
        peripheral.discoverServices(nil)
            .sink(receiveCompletion: {
                print("Service discovery completion: \($0)")
            }, receiveValue: { [weak self] services in
                services.forEach {
                    self?.startCharacteristicsDiscovery(for: $0)
                }
            })
            .store(in: &cancellables)
    }
    
    
    func startCharacteristicsDiscovery(for service: CBService) {
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral")
            connectionResult = .failure(CBError(.connectionFailed))
            stopSubscriptions()
            return
        }
        
        peripheral.discoverCharacteristics(nil, for: service)
            .sink(receiveCompletion: {
                print("Characteristics discovery completion: \($0)")
            }, receiveValue: { [weak self] characteristics in
                characteristics.forEach {
                    self?.handleDiscoveredCharacteristic($0)
                }
            })
            .store(in: &cancellables)
    }
    
    func handleDiscoveredCharacteristic(_ characteristic: CBCharacteristic) {
        print("Discovered characteristic: \(characteristic) in service \(characteristic.service?.uuid.uuidString ?? "Unknown")")
        
        if characteristic.uuid == moistureCharacteristicUUID {
            startObservingValueUpdates(from: characteristic)
        } else {
            readValue(from: characteristic)
        }
    }
    
    func readValue(from characteristic: CBCharacteristic) {
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral")
            connectionResult = .failure(CBError(.connectionFailed))
            stopSubscriptions()
            return
        }
        
        peripheral.readValue(for: characteristic)
            .sink(receiveCompletion: {
                print("Read value completion: \($0)")
            }, receiveValue: { [weak self] data in
                self?.printValue(data, characteristic: characteristic)
            })
            .store(in: &cancellables)
    }
    
    func startObservingValueUpdates(from characteristic: CBCharacteristic) {
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral")
            connectionResult = .failure(CBError(.connectionFailed))
            stopSubscriptions()
            return
        }
        
        subscriptionTask = peripheral.subscribeToUpdates(on: characteristic)
            .merge(with: peripheral.readValue(for: characteristic))
            .compactMap { $0 }
            .map(Result.success)
            .catch { Just(Result.failure($0)) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] result in
                if case let .success(value) = result {
                    self?.printValue(value, characteristic: characteristic)
                }
                self?.rawMoistureValue = result
            })
    }
    
    
    func printValue(_ data: Data?, characteristic: CBCharacteristic) {
        guard let data = data else {
            print("No data for characteristic \(characteristic.uuid)")
            return
        }
        
        let hexString = data.map { String(format: "%02x", $0) }.joined()
        print("Hex Value for characteristic \(characteristic.uuid): \(hexString)")
        
        if let stringValue = String(data: data, encoding: .utf8) {
            print("String Value for characteristic \(characteristic.uuid): \(stringValue)")
        }
    }
    
}
