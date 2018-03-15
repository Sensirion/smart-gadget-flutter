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
import 'package:smart_gadget_demo/actions/actions.dart';
import 'package:smart_gadget_demo/models/ble_device.dart';
import 'package:smart_gadget_demo/states/states.dart';
import 'package:smart_gadget_demo/views/smart_gadget_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

class ScanResultsViewModel {
  final Stack scanResults;
  final BuildContext context;

  ScanResultsViewModel({
    @required this.scanResults,
    @required this.context,
  });

  static ScanResultsViewModel fromStore(Store<AppState> store,
      BuildContext context) {
    final widgets = <Widget>[];
    if (store.state.state == BleState.UNAVAILABLE) {
      widgets.add(_buildAlertTile('Bluetooth is not available!', context));
    } else if (store.state.state == BleState.OFF) {
      widgets.add(_buildAlertTile('Bluetooth is not turned on!', context));
    }

    if (store.state.devices.length > 0) {
      widgets.add(_buildDevicesList(store));
    }

    return new ScanResultsViewModel(
        scanResults: Stack(
          children: widgets,
        ),
        context: context);
  }

  static _buildAlertTile(String text, BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          text,
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  static Widget _buildDevicesList(Store<AppState> store) {
    var devices = store.state.devices.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        if (i.isOdd) return Divider();

        final index = i ~/ 2;
        final BleDevice device = devices[index];
        Icon connectionIndicator = Icon(Icons.signal_wifi_off);
        CircularProgressIndicator progressIndicator;

        if (device.isConnected()) {
          connectionIndicator = Icon(Icons.signal_wifi_4_bar);
        } else if (device.isConnecting()) {
          progressIndicator = CircularProgressIndicator();
        }

        return ListTile(
          title: Text(device.name),
          subtitle: Text(device.id),
          leading: Text(device.rssi.toString()),
          trailing: progressIndicator ?? connectionIndicator,
          onTap: () {
            if (device.isDisconnected()) {
              store.dispatch(BleDeviceConnectAction(device: device));
            }
            store.state.selectDevice(device);
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => SmartGadgetDetail(
                    title: device.name)));
          },
          onLongPress: () {
            if(device.isConnected()) {
              store.dispatch(BleDeviceDisconnectAction(device: device));
            }
          },
        );
      },
      itemCount: 2 * devices.length,
    );
  }
}
