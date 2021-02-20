import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fireuser/page_bluetooth/bluetooth.dart';

//設定背景執行相關
void startServiceInPlatform() async {
  if (Platform.isAndroid) {
    var methodChannel = MethodChannel("decide background");
    String data = await methodChannel.invokeMethod("startService");
    debugPrint(data);
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);
  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    //get a specific device
    if (result.device.name == 'NTUT_LAB321_Product') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
              child: Text(
            "訊號強度 " + result.rssi.toString(),
          )),
        ],
      );
    } else {
      return Text(
        result.device.id.toString(),
      );
    }
  }

  //讀取設備相關參數
  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.caption,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach(
      (id, bytes) {
        res.add(
            '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
      },
    );
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach(
      (id, bytes) {
        res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
      },
    );
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (result.device.name == 'NTUT_LAB321_Product') {
      //只顯現固定裝置

      return Padding(
        padding: EdgeInsets.all(20.5),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.redAccent,
                        blurRadius: 20.0,
                        offset: Offset(0, 10))
                  ]),
              child: ListTile(
                title: _buildTitle(context),
                subtitle: Center(
                  child: Text(
                    result.device.id.toString(),
                    overflow: TextOverflow.ellipsis,
                    //style: Theme.of(context).textTheme.caption,
                  ),
                ),
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.device_unknown,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                trailing: RaisedButton(
                  color: Colors.redAccent,
                  highlightColor: Colors.greenAccent,
                  child: Text('未連線'),
                  onPressed:
                      (result.advertisementData.connectable) ? onTap : null,
                ),
              ),
            ),
          ],
        ),
      );

//          ExpansionTile(
//
//           title: _buildTitle(context),
//          //backgroundColor: Colors.redAccent,
//
//         leading: Text(
//          result.rssi.toString(),
//        ),
//        trailing: RaisedButton(
//          color: Colors.redAccent,
//
//          highlightColor: Colors.greenAccent,
//          child: Text('未連線'),
//          onPressed: (result.advertisementData.connectable) ? onTap : null,
//        ),
//        children: <Widget>[
//          _buildAdvRow(context, 'Complete Local Name',
//              result.advertisementData.localName),
//          _buildAdvRow(context, 'Tx Power Level',
//              '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
//          _buildAdvRow(
//              context,
//              'Manufacturer Data',
//              getNiceManufacturerData(
//                  result.advertisementData.manufacturerData) ??
//                  'N/A'),
//          _buildAdvRow(
//              context,
//              'Service UUIDs',
//              (result.advertisementData.serviceUuids.isNotEmpty)
//                  ? result.advertisementData.serviceUuids
//                  .join(', ')
//                  .toUpperCase()
//                  : 'N/A'),
//          _buildAdvRow(
//              context,
//              'Service Data',
//              getNiceServiceData(result.advertisementData.serviceData) ??
//                  'N/A'),
//        ],
//      );

    } else {
      return Container(
        width: 0,
        height: 0,
      );
    }
  }
}

//每個不同的UUID對應到不同的frame設定
class ServiceTile extends StatefulWidget {
  ServiceTile({@required this.service, this.characteristicTiles, Key key});
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  @override
  _ServiceTile createState() =>
      _ServiceTile(service: service, characteristicTiles: characteristicTiles);
}

class _ServiceTile extends State<ServiceTile> {
  _ServiceTile({@required this.service, this.characteristicTiles, Key key});
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;
  var selectItemValue, selectItemValue1, selectItemValue2;

  @override
  Widget build(BuildContext context) {
    startServiceInPlatform(); //開啟背景執行

    //用不到的將它遮蔽
    if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
        '0x1523') {
      return Container(
        width: 0,
        height: 0,
      );
    }

    //顯示對應硬體的最後一筆資料
    if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
        '0x1801') {
      if (allID.indexWhere(
              (allID) => allID.startsWith('${service.deviceId.toString()}')) ==
          -1) {
        allID.insert(0, '${service.deviceId.toString()}' + '00');
      }
      if ( //如果資料找的到，則顯示最後一筆資料及上次設定床號，用於OPEN
          alldata.indexWhere((alldata) =>
                  alldata.startsWith('${service.deviceId.toString()}')) !=
              -1) {
        return //顯示最後一筆資料跟設定床號資訊
            Card(
                child: Column(children: <Widget>[
          Container(
              child: Text('最後一筆資料:' +
                  alldata[alldata.indexWhere((alldata) =>
                          alldata.startsWith('${service.deviceId.toString()}'))]
                      .substring(17))),
          Container(
              child: Text('上次設定床號:' +
                  allID[allID.indexWhere((allID) =>
                          allID.startsWith('${service.deviceId.toString()}'))]
                      .substring(17)))
        ]));
      } else {
        //如果資料找不到，則不顯示，用於Connect
        return Container(
          height: 0.0,
        );
      }
    }
    //設定可下拉是選擇室與床號
    if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
        '0x1800') {
      return ListView(
        shrinkWrap: true,
        children: <Widget>[
          Card(
            child: Card(
              child: Row(
                children: <Widget>[
                  Text(
                    '下拉選單請選擇室、床號 ',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Builder(
                    //設定室
                    builder: (BuildContext context) {
                      return DropdownButtonHideUnderline(
                        child: new DropdownButton(
                          hint: new Text('室'),
                          //設置這個value之後，選中對應位置的item,
                          //再次呼出下拉菜單，會自動定位item位置在當前按鈕顯示的位置處
                          value: selectItemValue,
                          items: generateItemList(),
                          onChanged: (T) {
                            setState(
                              () {
                                selectItemValue = T;
                                //依照deviceID上傳對應firebase的documentID
                                if (selectItemValue != null &&
                                    selectItemValue1 != null) {
                                  allID.insert(
                                      0,
                                      '${service.deviceId.toString()}' +
                                          selectItemValue +
                                          '-' +
                                          selectItemValue1);
                                  FirebaseFirestore.instance
                                      .collection('NTUTLab321')
                                      .doc('${service.deviceId.toString()}')
                                      .update(
                                    {
                                      'judge': selectItemValue +
                                          '-' +
                                          selectItemValue1,
                                    },
                                  );
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Builder(
                    //設定床號
                    builder: (BuildContext context) {
                      return DropdownButtonHideUnderline(
                        child: new DropdownButton(
                          hint: new Text('床號'),
                          value: selectItemValue1,
                          items: generateItemList1(),
                          onChanged: (T) {
                            setState(
                              () {
                                selectItemValue1 = T;
                                if (selectItemValue != null &&
                                    selectItemValue1 != null) {
                                  //記錄在全域變數並傳送至firebase
                                  allID.insert(
                                      0,
                                      '${service.deviceId.toString()}' +
                                          selectItemValue +
                                          '-' +
                                          selectItemValue1);
                                  FirebaseFirestore.instance
                                      .collection('NTUTLab321')
                                      .doc('${service.deviceId.toString()}')
                                      .update(
                                    {
                                      'judge': selectItemValue +
                                          '-' +
                                          selectItemValue1,
                                    },
                                  );
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (characteristicTiles.length > 0) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('裝置資訊'),
            Text(
              '請點選展開  (${service.uuid.toString().toUpperCase().substring(4, 8)})',
              style: Theme.of(context)
                  .textTheme
                  .bodyText2
                  .copyWith(color: Theme.of(context).textTheme.caption.color),
            )
          ],
        ),
        children: characteristicTiles,
        initiallyExpanded: true,
        trailing: Icon(Icons.info_outline),
      );
    } else {
      return ListTile(
        title: Text('Service'),
        subtitle:
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

//不同UUID對應不同的frame
class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;
  const CharacteristicTile(
      {Key key,
      this.characteristic,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> messagewigets = [];
    List<String> messagemodewigets = [];
    messagemodewigets.insert(0, '1'); //用於模式
    messagewigets.insert(0, '已更換'); //用於狀態
    List<DateTime> _events = []; //用於時間
//

    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        //液體狀態設定，先判斷是否需要更換，後判斷是否與上一筆資料相同
        //若資料相同則不上傳
        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
            '0x1504') {
          if (value.toString() == '[1]') {
            _events.insert(
              0,
              new DateTime.now().toUtc(),
            ); //紀錄時間

            messagewigets.insert(0, '需更換'); //紀錄狀態
            //顯示液體狀態及建立可滑動wigets來顯示每筆資料
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                Card(
                  child: Row(
                    children: <Widget>[
                      Chip(
                        label: Text(
                          '液體狀態',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Container(
                        child: Text(
                          'check',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  color: Colors.black12,
                  height: 50,
                  child: new ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (BuildContext context, int index) {
                      DateTime timestamp = _events[index];
                      String message2 = messagewigets[index];
                      //如果資料一樣則不上傳
                      if (messagewigets[1] == null ||
                          (messagewigets[1] != messagewigets[0] &&
                              messagewigets[1] != null)) {
                        FirebaseFirestore.instance
                            .collection("NTUTLab321")
                            .doc('${characteristic.deviceId.toString()}')
                            .update(
                          {
                            'change': value.toString().substring(1, 2),
//                          'time': DateFormat("MM-dd HH:mm:ss")
//                              .format(_events[0]) +messagewigets[0]
                          },
                        );
                      }
                      return InputDecorator(
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                left: 10.0, top: 10.0, bottom: 0.0),
                            labelStyle: TextStyle(fontSize: 20.0),
                            labelText: message2),
                        child: new Text(
                          new DateFormat("MM-dd HH:mm:ss").format(timestamp),
                          style: TextStyle(fontSize: 16.0),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (value.toString() == '[0]') {
            _events.insert(0, new DateTime.now().toUtc()); //記錄當下時間，儲存在events
            messagewigets.insert(0, '已更換');
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                Card(
                  child: Row(
                    children: <Widget>[
                      Chip(
                        label: Text(
                          '液體狀態',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  color: Colors.black12,
                  height: 50,
                  child: new ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (BuildContext context, int index) {
                      DateTime timestamp = _events[index];
                      String message2 = messagewigets[index];
                      //如果資料一樣則不上傳
                      if (messagewigets[1] == null ||
                          (messagewigets[1] != messagewigets[0] &&
                              messagewigets[1] != null)) {
                        FirebaseFirestore.instance
                            .collection("NTUTLab321")
                            .doc('${characteristic.deviceId.toString()}')
                            .update(
                          {
                            'change': value.toString().substring(1, 2),
                            'time': FieldValue.arrayUnion([
                              {
                                'timestamp':
                                    Timestamp.fromDate(_events[0]).toDate(),
                                'log': '已更換',
                                'test': DateFormat.MMMd().format(_events[0])
                              }
                            ])
                            // DateFormat("yyyy年MM月dd日 HH:mm").format(_events[0]) +messagewigets[0]
                          },
                        );
                      }
                      return InputDecorator(
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                left: 10.0, top: 10.0, bottom: 0.0),
                            labelStyle: TextStyle(fontSize: 20.0),
                            labelText: message2),
                        child: new Text(
                          new DateFormat("MM-dd HH:mm:ss").format(timestamp),
                          style: TextStyle(fontSize: 16.0),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        }
        //設定模式相關設定，先判斷是點滴還尿袋，後判斷是否與上一筆資料一樣，如果一樣則不上傳
        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
            '0x1505') {
          if (value.toString() == '[1]') {
            _events.insert(0, new DateTime.now().toUtc());

            messagemodewigets.insert(0, '點滴模式');
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                Card(
                  child: Row(
                    children: <Widget>[
                      Chip(
                        label: Text(
                          '設備模式',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Container(
                        child: Text(
                          '點滴模式',
                          style: TextStyle(fontSize: 20.0),
                        ),
                        width: 100,
                        height: 25,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  color: Colors.black12,
                  height: 50,
                  child: new ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (BuildContext context, int index) {
                      DateTime timestamp = _events[index];
                      String message2 = messagemodewigets[index];
                      //如果資料一樣則不上傳
                      if (messagemodewigets[1] == null ||
                          (messagemodewigets[1] != messagemodewigets[0] &&
                              messagemodewigets[1] != null)) {
                        FirebaseFirestore.instance
                            .collection("NTUTLab321")
                            .doc('${characteristic.deviceId.toString()}')
                            .update(
                          {
                            'modedescription': '點滴',
//                          'time': DateFormat("MM-dd HH:mm:ss")
//                              .format(_events[0]) +messagemodewigets[0]
                          },
                        );
                      }
                      return InputDecorator(
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                left: 10.0, top: 10.0, bottom: 0.0),
                            labelStyle: TextStyle(fontSize: 20.0),
                            labelText: message2),
                        child: new Text(
                          new DateFormat("MM-dd HH:mm:ss").format(timestamp),
                          style: TextStyle(fontSize: 16.0),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (value.toString() == '[0]') {
            _events.insert(0, new DateTime.now().toUtc());
            messagemodewigets.insert(0, '尿袋模式');
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                Card(
                  child: Row(
                    children: <Widget>[
                      Chip(
                        label: Text(
                          '設備模式',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Container(
                        child: Text(
                          '尿袋模式',
                          style: TextStyle(fontSize: 20.0),
                        ),
                        width: 100,
                        height: 25,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  color: Colors.black12,
                  height: 50,
                  child: new ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (BuildContext context, int index) {
                      DateTime timestamp = _events[index];
                      String message2 = messagemodewigets[index];
                      //如果資料一樣則不上傳
                      if (messagemodewigets[1] == null ||
                          (messagemodewigets[1] != messagemodewigets[0] &&
                              messagemodewigets[1] != null)) {
                        FirebaseFirestore.instance
                            .collection("NTUTLab321")
                            .doc('${characteristic.deviceId.toString()}')
                            .update(
                          {
                            'modedescription': '尿袋',
//                          'time': DateFormat("MM-dd HH:mm:ss")
//                              .format(_events[0]) +messagemodewigets[0]
                          },
                        );
                      }
                      return InputDecorator(
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                left: 10.0, top: 10.0, bottom: 0.0),
                            labelStyle: TextStyle(fontSize: 20.0),
                            labelText: message2),
                        child: new Text(
                          new DateFormat("MM-dd HH:mm:ss").format(timestamp),
                          style: TextStyle(fontSize: 16.0),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        }
        //顯示電量
        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
            '0x1514') {
          if (value.isNotEmpty) {
            return Card(
              child: Row(
                children: <Widget>[
                  Chip(
                    label: Text(
                      '剩餘電力',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                  Container(
                    height: 20,
                    child: Row(
                      children: <Widget>[
                        Text(value.toString() + "%",
                            style: TextStyle(fontSize: 20.0)),
//                   Icon(Icons.battery_full,color: Colors.green,),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }

        //其他版面設定，未用到
        return ExpansionTile(
          title: ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('資料'),
                Text(
                  '請載入或更新資料  (${characteristic.uuid.toString().toUpperCase().substring(4, 8)})',
                  style: Theme.of(context).textTheme.bodyText2.copyWith(
                      color: Theme.of(context).textTheme.caption.color),
                )
              ],
            ),
            subtitle: Text(
              value.toString(),
            ),
            contentPadding: EdgeInsets.all(0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  color: Theme.of(context).iconTheme.color.withOpacity(0.5),
                ),
                onPressed: onReadPressed,
              ),
              IconButton(
                icon: Icon(
                  characteristic.isNotifying ? Icons.sync_disabled : Icons.sync,
                  color: Theme.of(context).iconTheme.color.withOpacity(0.5),
                ),
                onPressed: onNotificationPressed,
              )
            ],
          ),
        );
      },
    );
  }
}

//其他版面設定，未用到
class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key key, @required this.state}) : super(key: key);
  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subtitle1,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subtitle1.color,
        ),
      ),
    );
  }
}

//設定下拉式選單相關設定
List<DropdownMenuItem> generateItemList() {
  List<DropdownMenuItem> items = new List();
  for (int i = 1, j = 1; i < 10; i++, j++) {
    DropdownMenuItem i = new DropdownMenuItem(
      child: new Text(j.toString() + '室'),
      value: '0' + j.toString(),
    );
    items.add(i);
  }
  for (int i = 10, j = 10; i < 100; i++, j++) {
    DropdownMenuItem i = new DropdownMenuItem(
      child: new Text(j.toString() + '室'),
      value: j.toString(),
    );
    items.add(i);
  }
  return items;
}

List<DropdownMenuItem> generateItemList1() {
  List<DropdownMenuItem> items1 = new List();
  for (int k = 1, m = 1; k < 10; k++, m++) {
    DropdownMenuItem k = new DropdownMenuItem(
      child: new Text(m.toString() + '床'),
      value: '0' + m.toString(),
    );
    items1.add(k);
  }
  for (int k = 10, m = 10; k < 100; k++, m++) {
    DropdownMenuItem k = new DropdownMenuItem(
      child: new Text(m.toString() + '床'),
      value: m.toString(),
    );
    items1.add(k);
  }
  return items1;
}
