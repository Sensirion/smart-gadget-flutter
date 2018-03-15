# Smart Gadget Demo

A simple demo flutter application that shows how to communicate with
a Sensirion smart gadget.

The app supports scanning for smart gadgets, connect to gadgets and
read the temperature and humidity characteristics, as well as
disconnecting from smart gadgets.


## Getting Started

### Usage

The app requires a smart phone with bluetooth low energy support
to work.

Turn on bluetooth and click on the scan button on the
bottom right to scan for near-by smart gadgets. A list of gadgets
found is displayed. Scanning again will clear the current list
and disconnect from all connected gadgets at the moment.

Click on a smart gadget to show the detail screen and connect
to the gadget, if not already connected. On the detail screen
you will see the current temperature, humidity and connection
status.

Long press on a connected gadget in the list view will disconnect
from that gadget.

### Development

This app uses [redux](https://pub.dartlang.org/packages/flutter_redux)
to manage the data flow, and the [flutter blue](https://pub.dartlang.org/packages/flutter_blue)
plugin to handle the bluetooth stack.

All bluetooth related code can be found in `ble_middleware.dart`.
Currently we register two characteristics of the smart gadget:

* Temperature `GUID('00002235-b38d-4985-720e-0f993a68ee41')`
* Humidity `Guid('00001235-b38d-4985-720e-0f993a68ee41')`

The values we receive from those characteristics arrive in little
endian. To extract the double values we use the following code, which
is located in `little_endian_extractor.dart`:

```
static double extractDouble(final List<int> value) {
  var data = new ByteData.view(Uint8List.fromList(value).buffer);
  return data.getFloat32(0, Endian.little);
}
```

For help getting started with Flutter, view the online
[documentation](https://flutter.io/).
