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
    
    var devicesView: some View {
        List {
            Section("Moisture sensors") {
                ForEach(model.peripherals) { peripheral in
                    Button {
                        model.connect(to: peripheral)
                    } label: {
                        PeripheralListViewItem(peripheral: peripheral)
                    }
                }
            }
        }
    }
}

struct PeripheralListViewItem: View {
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
            Text(moistureValue)
        }
    }
}
#Preview {
    SensorListView()
}
