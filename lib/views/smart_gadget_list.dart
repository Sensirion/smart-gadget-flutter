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
import 'package:smart_gadget_demo/view_models/scan_button_view_model.dart';
import 'package:smart_gadget_demo/view_models/scan_results_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class SmartGadgetList extends StatelessWidget {
  final String title;

  SmartGadgetList({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _buildScanningButton() {
      return new StoreConnector<AppState, ScanButtonViewModel>(
        converter: ScanButtonViewModel.fromStore,
        builder: (context, viewModel) {
          return viewModel.button;
        },
      );
    }

    _buildScanResults(BuildContext context) {
      return new StoreConnector<AppState, ScanResultsViewModel>(
        converter: (store) => ScanResultsViewModel.fromStore(store, context),
        builder: (context, viewModel) {
          return viewModel.scanResults;
        },
      );
    }

    return new StoreBuilder<AppState>(
      onInit: (store) => store.dispatch(new BleInitAction()),
      builder: (context, Store<AppState> store) {
        return new Scaffold(
          appBar: new AppBar(
            title: new Text(this.title),
          ),
          body: new StoreConnector<AppState, AppState>(
            converter: (store) => store.state,
            builder: (context, state) {
              return _buildScanResults(context);
            },
          ),
          floatingActionButton: _buildScanningButton(),
        );
      },
    );
  }
}
