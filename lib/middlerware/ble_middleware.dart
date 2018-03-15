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

import 'package:smart_gadget_demo/actions/actions.dart';
import 'package:smart_gadget_demo/models/ble_device.dart';
import 'package:smart_gadget_demo/states/states.dart';
import 'package:smart_gadget_demo/utils/little_endian_extractor.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:redux/redux.dart';

void bleMiddleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is BleInitAction) {
    handleBleInit(store);
  }

  // only allow scanning bluetooth state is idle
  if (action is BleScanAction && store.state.state == BleState.IDLE) {
    handleBleScan(store);
  }

  if (action is BleAbortScanAction &&
      store.state.busyState == BleBusyState.SCANNING) {
    _stopScan(store);
  }

  if (action is BleDeviceConnectAction) {
    handleDeviceConnection(store, action.device);
  }

  if (action is BleDeviceDisconnectAction) {
    handleDeviceDisconnect(store, action.device);
  }

  if (action is BleNewTemperatureCharacteristic) {
    registerTemperatureNotifications(
        store, action.device, action.characteristic);
  }

  if (action is BleNewHumidityCharacteristic) {
    // workaround to make sure the BluetoothGat communication is freed
    Future.delayed(new Duration(milliseconds: 400), () {
      registerHumidityNotifications(
          store, action.device, action.characteristic);
    });
  }

  next(action);
}

// Cancel scan subscription
void _stopScan(Store<AppState> store) {
  store.state.scanSubscription?.cancel();
  store.state.scanSubscription = null;
  store.dispatch(new BleScanDoneAction());
}

// handle ble initialization and subscribe to bluetooth state changes
void handleBleInit(Store<AppState> store) {
  final flutterBlue = FlutterBlue.instance;

  // init Bluetooth
  flutterBlue.state.then((s) {
    if (s == BluetoothState.on) {
      store.dispatch(new BleOnAction());
    } else if (s == BluetoothState.off) {
      store.dispatch(new BleOffAction());
    } else {
      store.dispatch(new BleFailedAction());
    }
  });

  // monitor bluetooth state
  flutterBlue.onStateChanged().listen((s) {
    if (s == BluetoothState.on) {
      store.dispatch(new BleOnAction());
    } else if (s == BluetoothState.turningOff) {
      store.dispatch(new BleOffAction());
    } else if (s == BluetoothState.unavailable ||
        s == BluetoothState.unauthorized) {
      store.dispatch(new BleFailedAction());
    }
  });
}

// handle ble scanning
void handleBleScan(Store<AppState> store) {
  final flutterBlue = FlutterBlue.instance;

  final List<String> supportedDevices = ['Smart Humigadget'];

  // disconnect and clear stored devices
  for (BleDevice device in store.state.devices.values) {
    device.disconnect();
  }
  store.state.devices.clear();

  store.state.scanSubscription = flutterBlue
      .scan(
    timeout: const Duration(seconds: 5),
  )
      .listen((scanResult) {
    if (supportedDevices.contains(scanResult.device.name)) {
      store.dispatch(new BleScanResultReadyAction(
          device: new BleDevice(scanResult.device.id.toString(),
              scanResult.rssi, scanResult.device,
              name: scanResult.device.name)));
    }
  }, onDone: () => _stopScan(store));
}

void handleDeviceConnection(Store<AppState> store, BleDevice device) {
  final flutterBlue = FlutterBlue.instance;

  device.deviceState = BluetoothDeviceState.connecting;
  store.dispatch(new BleDeviceConnectingAction(device: device));

  device.deviceConnection = flutterBlue
      .connect(device.device, timeout: Duration(seconds: 60))
      .listen((s) {
    device.deviceState = s;

    if (s == BluetoothDeviceState.connected) {
      store.dispatch(new BleDeviceConnectedAction(device: device));

      device.device.discoverServices().then((s) {
        device.services = s;
        for (BluetoothService service in device.services) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid == new Guid('00002235-b38d-4985-720e-0f993a68ee41')) {
              store.dispatch(new BleNewTemperatureCharacteristic(
                  device: device, characteristic: c));
            }
            if (c.uuid == new Guid('00001235-b38d-4985-720e-0f993a68ee41')) {
              store.dispatch(new BleNewHumidityCharacteristic(
                  device: device, characteristic: c));
            }
          }
        }
      });
    }
  }, onDone: () {
    handleDeviceDisconnect(store, device);
  }, onError: (var error) {
    print("onError: " + error.toString());
    handleDeviceDisconnect(store, device);
  });
}

void handleDeviceDisconnect(Store<AppState> store, BleDevice device) {
  if (device.isDisconnected()) {
    return;
  }
  device.disconnect();
  device.deviceState = BluetoothDeviceState.disconnected;
  store.dispatch(new BleDeviceDisconnectedAction(device: device));
}

void registerHumidityNotifications(Store<AppState> store, BleDevice device,
    BluetoothCharacteristic humidityCharacteristic) async {
  device.setNotification(humidityCharacteristic, (value) {
    device.setHumidity(LittleEndianExtractor.extractDouble(value));
    store.dispatch(new BleDeviceNewValue(device: device));
  });
}

void registerTemperatureNotifications(Store<AppState> store, BleDevice device,
    BluetoothCharacteristic temperatureCharacteristic) async {
  device.setNotification(temperatureCharacteristic, (value) {
    device.setTemperature(LittleEndianExtractor.extractDouble(value));
    store.dispatch(new BleDeviceNewValue(device: device));
  });
}
