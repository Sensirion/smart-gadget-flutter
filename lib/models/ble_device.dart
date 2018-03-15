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
import 'package:synchronized/synchronized.dart';

import 'package:flutter_blue/flutter_blue.dart';

class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice device;

  double _temperature = double.nan;
  double _humidity = double.nan;
  var _gatLock = Lock();

  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription deviceConnection;
  Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  List<BluetoothService> services;

  BleDevice(this.id, this.rssi, this.device, {this.name = ''});

  BleDevice copyWith(
      {String id, String name, int rssi, BluetoothDevice device}) {
    return new BleDevice(
      id ?? this.id,
      rssi ?? this.rssi,
      device ?? this.device,
      name: name ?? this.name,
    );
  }

  bool isConnected() {
    return deviceState == BluetoothDeviceState.connected;
  }

  bool isConnecting() {
    return deviceState == BluetoothDeviceState.connecting;
  }

  bool isDisconnected() {
    return deviceState == BluetoothDeviceState.disconnected;
  }

  bool isIdle() {
    return deviceState == BluetoothDeviceState.connected ||
        deviceState == BluetoothDeviceState.disconnected;
  }

  void setTemperature(double temperature) {
    _temperature = temperature;
  }

  void setHumidity(double humidity) {
    _humidity = humidity;
  }

  Future setNotification(BluetoothCharacteristic c, Function callback) async {
    if (!c.isNotifying) {
      await _gatLock.synchronized(() {
        device.setNotifyValue(c, true);
        valueChangedSubscriptions[c.uuid] =
            device.onValueChanged(c).listen(callback);
      });
    }
  }

  void disconnect() {
    valueChangedSubscriptions.forEach((uuid, sub) => sub.cancel());
    valueChangedSubscriptions.clear();
    deviceConnection?.cancel();
    deviceConnection = null;
  }

  String get temperature => '${_temperature.toStringAsFixed(2)} °C';

  String get humidity => '${_humidity.toStringAsFixed(2)} %';

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BleDevice && id == other.id;
}
