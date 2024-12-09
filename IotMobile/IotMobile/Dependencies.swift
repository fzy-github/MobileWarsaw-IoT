//
//  Dependencies.swift
//  IotMobile
//
//  Created by Filip Zymek on 07/12/2024.
//

import Dependencies
import CombineCoreBluetooth

extension CentralManager: @retroactive DependencyKey {
    static public var liveValue: CentralManager = .live()
    public static var testValue: CentralManager = .unimplemented()
}

extension DependencyValues {
  var centralManager: CentralManager {
    get { self[CentralManager.self] }
    set { self[CentralManager.self] = newValue }
  }
}
