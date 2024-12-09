//
//  SensorDetailsView.swift
//  IotMobile
//
//  Created by Filip Zymek on 07/12/2024.
//

import SwiftUI
import CombineCoreBluetooth

struct SensorDetailsView: View {
    @State private var model: SensorDetailsViewModel
    
    init(sensor: PeripheralDiscovery) {
        self._model = .init(initialValue: .init(sensor: sensor))
    }
    
    var body: some View {
        VStack {
            if model.connectionResult != nil {
                if let error = model.connectionError {
                    ContentUnavailableView(
                        "Connection error",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Failed to connect to sensor: \(error.localizedDescription)")
                    )
                } else if let peripheral = model.connectedPeripheral {
                    Text("Connected to \(peripheral.name ?? "Unknown (\(peripheral.identifier.uuidString))")")
                        .font(.subheadline)
                    
                    Spacer()
                    if let error = model.moistureReadError {
                        ContentUnavailableView(
                            "Moisture read error",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Failed to read moisture level: \(error.localizedDescription)")
                        )
                    } else if let moistureValue = model.moistureValue {
                        Label("Moisture level", systemImage: "drop.degreesign")
                            .font(.title2)
                        Text(moistureValue)
                            .font(.title3)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: moistureValue)
                    }                    
                    Spacer()
                }
            } else {
                Button("Connect to \(model.name)") {
                    model.connect()
                }
            }
        }
        .onAppear {
            model.connect()
        }
        .onDisappear {
            model.disconnect()
        }
    }
}
