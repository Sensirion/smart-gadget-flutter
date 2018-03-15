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
import 'package:smart_gadget_demo/states/states.dart';

AppState appReducer(AppState state, dynamic action) {
  BleState bleState = state.state;

  // can't recover from ble unavailable
  if (bleState == BleState.UNAVAILABLE) {
    return state;
  }

  // update view (no state change for device connection actions)
  if (action is BleDeviceConnectingAction ||
      action is BleDeviceConnectedAction ||
      action is BleDeviceDisconnectedAction) {
    return state.copyWith();
  }

  if (action is BleDeviceNewValue && action.device == state.selectedDevice) {
    return state.copyWith();
  }

  // initial state
  if (bleState == BleState.UNKNOWN) {
    if (action is BleFailedAction) {
      return state.copyWith(state: BleState.UNAVAILABLE);
    }

    if (action is BleOffAction) {
      return state.copyWith(state: BleState.OFF);
    }

    if (action is BleOnAction) {
      return state.copyWith(state: BleState.IDLE);
    }
  }

  // ble was off
  if (bleState == BleState.OFF) {
    if (action is BleFailedAction) {
      return state.copyWith(state: BleState.UNAVAILABLE);
    }

    if (action is BleOnAction) {
      return state.copyWith(state: BleState.IDLE);
    }
  }

  // was idle
  if (bleState == BleState.IDLE) {
    if (action is BleOffAction) {
      return state.copyWith(state: BleState.OFF, busyState: BleBusyState.IDLE);
    }

    // scanning
    if (action is BleScanAction) {
      return state.copyWith(
          state: BleState.BUSY, busyState: BleBusyState.SCANNING);
    }
  }

  // was busy
  if (bleState == BleState.BUSY) {
    if (action is BleOffAction) {
      return state.copyWith(state: BleState.OFF, busyState: BleBusyState.IDLE);
    }

    // busy action done
    if (action is BleScanDoneAction) {
      return state.copyWith(state: BleState.IDLE, busyState: BleBusyState.IDLE);
    }

    // no state chane when scan result is ready
    if (action is BleScanResultReadyAction) {
      state.addDevice(action.device);
      return state;
    }
  }

  return state;
}
