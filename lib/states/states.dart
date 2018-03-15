/*
Copyright (c) 2018, Sensirion AG
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of Sensirion AG nor the names of its
    contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
import 'dart:async';
import 'dart:collection';

import 'package:smart_gadget_demo/models/ble_device.dart';
import 'package:flutter_blue/flutter_blue.dart';

enum BleState {
  UNKNOWN,
  UNAVAILABLE,
  OFF,
  IDLE,
  BUSY,
}

enum BleBusyState {
  IDLE,
  SCANNING,
  CONNECTING,
  DISCONNECTING,
}

class AppState {
  final BleState state;
  final BleBusyState busyState;
  SplayTreeMap<int, BleDevice> devices;
  StreamSubscription scanSubscription;
  BleDevice selectedDevice;

  AppState({
    this.state = BleState.UNKNOWN,
    this.busyState = BleBusyState.IDLE,
    this.selectedDevice,
    SplayTreeMap<int, BleDevice> devices}) :
        this.devices = devices  ?? new SplayTreeMap();

  AppState copyWith({BleState state, BleBusyState busyState,
    BleDevice selectedDevice, BluetoothDeviceState deviceState}) =>
      new AppState(
          state: state ?? this.state,
          busyState: busyState ?? this.busyState,
          selectedDevice: this.selectedDevice,
          devices: this.devices);

  void addDevice(BleDevice device) {
    if (!devices.containsValue(device)) {
      devices[-1 * device.rssi] = device;
    }
  }

  void selectDevice(BleDevice device) {
    if (!devices.containsValue(device)) {
      addDevice(device);
    }
    selectedDevice = device;
  }
}
