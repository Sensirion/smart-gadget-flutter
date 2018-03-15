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
import 'package:flutter_blue/flutter_blue.dart';
import 'package:smart_gadget_demo/models/ble_device.dart';
import 'package:smart_gadget_demo/states/states.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

class SmartGadgetDetailViewModel {
  final Container gadgetDetail;
  static final String humidityIcon = 'lib/assets/images/humidity_icon.png';
  static final String temperatureIcon =
      'lib/assets/images/temperature_icon.png';

  SmartGadgetDetailViewModel({@required this.gadgetDetail});

  static Container _buildGadgetDetail(BleDevice device) {
    String temperature = double.nan.toString();
    String humidity = double.nan.toString();
    Icon deviceState = const Icon(Icons.signal_wifi_off);
    Text connectionState = const Text('not connected');
    CircularProgressIndicator progressIndicator;

    if (device != null) {
      temperature = device.temperature;
      humidity = device.humidity;
      if (device.isConnected()) {
        deviceState = const Icon(Icons.signal_wifi_4_bar);
        connectionState = const Text('connected');
      } else if (device.deviceState == BluetoothDeviceState.connecting) {
        connectionState = const Text('connecting');
        progressIndicator = CircularProgressIndicator();
      }
    }

    Card _buildCard(leading, title, trailing) {
      return Card(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: new Stack(
              children: <Widget>[
                ListTile(
                  leading: leading,
                  title: title,
                  trailing: trailing,
                ),
              ],
            ),
          ),
        ],
      ));
    }

    return Container(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0,
                horizontal: 12.0),
            child: _buildCard(ImageIcon(AssetImage(temperatureIcon)),
                Text('Temperature'), Text(temperature)),
           ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0,
                horizontal: 12.0),
            child: _buildCard(ImageIcon(AssetImage(humidityIcon)),
                Text('Humidity'), Text(humidity)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0,
                horizontal: 12.0),
            child: _buildCard(deviceState, connectionState, progressIndicator),
          )
        ],
    ));
  }

  static SmartGadgetDetailViewModel fromStore(Store<AppState> store) {
    return SmartGadgetDetailViewModel(
        gadgetDetail: _buildGadgetDetail(store.state.selectedDevice));
  }
}
