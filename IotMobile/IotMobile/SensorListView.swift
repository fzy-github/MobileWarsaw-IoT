//
//  ContentView.swift
//  IotMobile
//
//  Created by Filip Zymek on 06/12/2024.
//

import SwiftUI
import CombineCoreBluetooth

struct SensorListView: View {
    
    @State private var model: SensorListViewModel
    
    init(model: SensorListViewModel = .init()) {
        self.model = model
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack {
                    if model.isScanning {
                        if model.peripherals.isEmpty {
                            emptyView
                        } else {
                            devicesView
                        }
                    } else {
                        Button("Start Scanning") {
                            model.startScanning()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                noBluetoothView
            }
            .navigationDestination(item: $model.connectedSensor) {
                SensorDetailsView(sensor: $0)
            }
        }
        .alert(isPresented: $model.showEnableBluetooth) {
            Alert(
                title: Text("Bluetooth is off"),
                message: Text("Enable Bluetooth in Settings"),
                primaryButton: .default(Text("Ok")),
                secondaryButton: .cancel()
            )
        }
    }
    
    @ViewBuilder
    var noBluetoothView: some View {
        if !model.isBluetoothOn {
            HStack {
                Text("Bluetooth is off")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        }
    }
    
    var emptyView: some View {
        HStack {
            Text("Looking for devices...")
            Spacer()
            ProgressView().progressViewStyle(.circular)
        }
        .padding()
    }
    
    @ViewBuilder
    var devicesView: some View {
        let moistureSensors = model.peripherals.filter(\.isMoistureSensor)
        let other = model.peripherals.filter { !$0.isMoistureSensor }
        List {
            Section("Moisture sensors") {
                if moistureSensors.isEmpty {
                    Text("No moisture sensors found")
                } else {
                    ForEach(moistureSensors) { peripheral in
                        Button {
                            model.connect(to: peripheral)
                        } label: {
                            MoistureSensorListViewItem(peripheral: peripheral)
                        }
                    }
                }
            }
            
            Section("Other") {
                if other.isEmpty {
                    Text("No BLE devices found")
                        .font(.caption)
                } else {
                    ForEach(other) { peripheral in
                        OtherDeviceListViewItem(peripheral: peripheral)
                    }
                }
            }
        }
    }
}

struct MoistureSensorListViewItem: View {
    let peripheral: PeripheralDiscovery
    
    var moistureValue: String {
        guard let data = peripheral.advertisementData.manufacturerData,
              let value = String(data: data, encoding: .utf8) else {
            return "-- %"
        }
        return value + " %"
    }
    
    var body: some View {
        HStack {
            Text(peripheral.peripheral.name ?? "Unknown Peripheral")
            Spacer()
            Label(moistureValue, systemImage: "drop.degreesign")
        }
    }
}

struct OtherDeviceListViewItem: View {
    let peripheral: PeripheralDiscovery
    
    var rssi: String {
        guard let rssi = peripheral.rssi else {
            return "-- dB"
        }
        let intVal = Int(rssi)
        return "\(intVal) dB"
    }
    
    var body: some View {
        HStack {
            Text(peripheral.peripheral.name ?? "Unknown Peripheral")
            Spacer()
            Text(rssi)
        }
    }
}
#Preview {
    SensorListView()
}
