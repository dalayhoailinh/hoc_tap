# Bài 21: ghép thành sơ đồ ghế hai người cùng nhìn

**Lõi một câu:** mỗi người giữ **một kết nối mở** tới server. Bấm một ghế là ghi một cái khoá có hạn (bài 18) và mọi
người đang nối thấy ngay (bài 16). Kết nối đứt thì server làm theo lời dặn, nhả ghế (bài 19). Bấm "Đặt vé" thì
server tra **sổ ghế của nó** rồi mới bán (bài 20).

Không có lõi mới. Server Dart của bạn đóng hai vai: Realtime Database (khoá, lời dặn, đẩy thay đổi) và
`createBooking` phần ghế (sổ ghế). App có **hai người trong một cửa sổ**, An bên trái, Bình bên phải, mỗi người một
kết nối riêng, như hai cái điện thoại đặt cạnh nhau.

Khác bài 6, 12, 17: không HTTP hỏi-đáp, không file txt. Kết nối là **WebSocket**: mở một lần, hai bên gửi tin cho
nhau bất cứ lúc nào. Kho nằm trong RAM, tắt server là mất (khoá ghế vốn là thứ tạm).

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai21
mkdir server
flutter create --empty --platforms=windows app
```

Không cần package nào: `WebSocket` có sẵn trong `dart:io`.

| | Server | App |
|---|---|---|
| File | `server\main.dart`, lượt 7 thêm `server\kexau.dart` | `app\lib\main.dart` |
| Chạy | Terminal 1: `cd D:\dev\hoc\bai21\server` → `dart run main.dart` | Terminal 2: `cd D:\dev\hoc\bai21\app` → `flutter run -d windows` |
| Sửa xong | `Ctrl+C` rồi chạy lại, rồi bấm `R` ở terminal 2 (app phải nối lại) | Lưu file, bấm `R` |

Tin nhắn hai chiều đều là JSON:

| Chiều | Tin | Nghĩa |
|---|---|---|
| App → server | `{"op":"lock","seat":"A1"}` | Tôi chọn ghế A1 |
| App → server | `{"op":"unlock","seat":"A1"}` | Tôi bỏ ghế A1 |
| App → server | `{"op":"book","seats":["A1","A2"]}` | Tôi đặt những ghế này |
| Server → mọi người | `{"seats":{...},"sold":{...}}` | Toàn bộ trạng thái ghế lúc này |
| Server → một người | `{"error":"...","code":"..."}` hoặc `{"booked":"an_1"}` | Trả lời riêng cho người vừa gửi |

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** server: nhận kết nối, gửi ngay trạng thái hiện tại | Terminal 1: `Server chạy ở ws://localhost:3000` |
| 2 | **Vỏ** app: hai người, mỗi người một lưới 8 ghế | Hai cột `an: đã nối`, `binh: đã nối`; terminal 1: `an nối`, `binh nối`. An bấm A1 → terminal 1: `an gửi: {op: lock, seat: A1}`. Bấm `Rớt mạng` bên Bình → `binh: mất kết nối`, terminal 1: `binh rớt mạng` |
| 3 | **Lõi**: `lock` ghi khoá rồi **phát cho mọi người** (bài 16); app đặt nhãn ghế theo khoá | An bấm A1 → bên An `A1 (tôi)`, bên Bình `A1 (an)` cùng lúc. Bình bấm A1 → bên An thành `A1 (binh)` ← **cướp ghế** |
| 4 | **Lõi**: ghế người khác đang giữ thì từ chối, báo riêng người bấm; bấm lại ghế mình là bỏ (bài 18 lượt 2) | Bình bấm A1 → dưới cột Bình: `Ghế A1 đã có người chọn.`; An bấm A1 lần nữa → cả hai bên về `A1` |
| 5a | Nhìn cái hỏng: An giữ A1, A2 rồi bấm `Rớt mạng` | Bên Bình vẫn `A1 (an)`, `A2 (an)` mãi ← **ghế kẹt** |
| 5b | **Lõi** lời dặn (bài 19): giữ ghế thì dặn luôn; kết nối đứt thì server xoá và phát | Làm lại 5a → bên Bình về `A1`, `A2` ngay; terminal 1: `an rớt mạng -> xoá [A1, A2]` |
| 6 | **Lõi** hạn giữ 20 giây (bài 18 lượt 3) + job dọn mỗi giây | An bấm A1 rồi **không làm gì**. Khoảng 20 giây sau cả hai bên về `A1`; terminal 1: `hết hạn -> xoá [A1]` |
| 7a | Nút Đặt vé + `book` **chưa kiểm gì**; **vỏ** `kexau.dart` | An giữ A1, bấm Đặt vé → cả hai bên `A1 (đã bán)`, dưới cột An: `an_1`. `dart run kexau.dart` → `kexau nhận: {"booked":"kexau_2"}`; terminal 1: `an đặt [A1] -> an_1` rồi `kexau đặt [A1] -> kexau_2` ← **một ghế hai đơn** |
| 7b | **Lõi** sổ ghế (bài 20): ghế đã có trong sổ thì `seat-taken` | `kexau nhận: {"error":"Ghế A1 đã có người đặt.","code":"seat-taken"}`. Bình bấm A1 → `Ghế A1 đã có người đặt.` An bấm `Rớt mạng` → A1 vẫn `(đã bán)` |

## Từng lượt

### Lượt 1: khung server (vỏ)

`server\main.dart`:

```dart
import 'dart:convert';
import 'dart:io';

// seat code -> lock
final seats = <String, Map<String, dynamic>>{};
// open connection -> who it is
final clients = <WebSocket, String>{};

String snapshot() => jsonEncode({'seats': seats});

// TẠM — lượt 3: xử lý 'lock'
void handle(WebSocket socket, String uid, Map<String, dynamic> message) {
  print('$uid gửi: $message');
}

void main() async {
  final server = await HttpServer.bind('localhost', 3000);
  print('Server chạy ở ws://localhost:3000');
  await for (final req in server) {
    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = 404;
      req.response.close();
      continue;
    }
    final uid = req.uri.queryParameters['uid'] ?? 'khach';
    final socket = await WebSocketTransformer.upgrade(req);
    clients[socket] = uid;
    print('$uid nối');
    // Like onValue: the newcomer gets the current state at once.
    socket.add(snapshot());
    socket.listen(
      (text) => handle(socket, uid, jsonDecode(text)),
      onDone: () {
        clients.remove(socket);
        print('$uid rớt mạng');
      },
    );
  }
}
```

- Một WebSocket bắt đầu là một request HTTP thường xin "nâng cấp"; `WebSocketTransformer.upgrade` đổi nó thành
  `socket`. Từ đó `socket.add(chữ)` là gửi, `socket.listen(...)` là nhận.
- Server **biết ai đang nối**: Map `clients`. Server HTTP của bài 12 trả lời xong là quên luôn người hỏi.
- `onDone` chạy khi kết nối đóng. Đây là chỗ server "nhận ra có người rớt mạng"; lượt 5b dùng nó.
- Ai là ai lấy từ `?uid=` trên địa chỉ (TẠM, như token-là-tên ở bài 12).
- Người mới nối nhận ngay `snapshot()`: bài 16 lượt 5.

### Lượt 2: khung app (vỏ)

`app\lib\main.dart`, thay hết nội dung cũ:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

const seatCodes = ['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'B3', 'B4'];

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Chọn ghế')),
        body: const Row(
          children: [
            Expanded(child: SeatPanel(uid: 'an')),
            VerticalDivider(),
            Expanded(child: SeatPanel(uid: 'binh')),
          ],
        ),
      ),
    ),
  );
}

// One user with their own connection: like one phone.
class SeatPanel extends StatefulWidget {
  const SeatPanel({super.key, required this.uid});
  final String uid;

  @override
  State<SeatPanel> createState() => _SeatPanelState();
}

class _SeatPanelState extends State<SeatPanel> {
  WebSocket? _socket;
  Map<String, dynamic> _seats = {};
  var _message = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  Future<void> _connect() async {
    final socket = await WebSocket.connect(
      'ws://localhost:3000/?uid=${widget.uid}',
    );
    socket.listen(_onMessage, onDone: _onDone);
    if (mounted) setState(() => _socket = socket);
  }

  void _onMessage(dynamic text) {
    final Map<String, dynamic> message = jsonDecode(text);
    if (!mounted) return;
    setState(() {
      _seats = message['seats'] ?? _seats;
      _message = message['error'] ?? _message;
    });
  }

  void _onDone() {
    if (mounted) setState(() => _socket = null);
  }

  void _send(Map<String, dynamic> message) {
    _socket?.add(jsonEncode(message));
  }

  // TẠM — lượt 3: nhãn theo khoá
  String _label(String code) => code;

  // TẠM — lượt 4: bấm ghế của mình thì nhả
  void _tapSeat(String code) {
    _send({'op': 'lock', 'seat': code});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('${widget.uid}: ${_socket == null ? 'mất kết nối' : 'đã nối'}'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in seatCodes)
                OutlinedButton(
                  onPressed: () => _tapSeat(code),
                  child: Text(_label(code)),
                ),
            ],
          ),
          TextButton(
            onPressed: _socket == null ? _connect : () => _socket?.close(),
            child: Text(_socket == null ? 'Nối lại' : 'Rớt mạng'),
          ),
          Text(_message),
        ],
      ),
    );
  }
}
```

- `SeatPanel` dùng hai lần với hai `uid`: hai State, hai kết nối, không chung biến nào. Thứ duy nhất nối hai người
  là server.
- Màn hình **không tự đổi khi bấm**. Bấm chỉ gửi tin; màn hình đổi khi server gửi trạng thái về (`_onMessage`). Một
  nguồn sự thật.
- Nút `Rớt mạng` đóng kết nối từ phía app, để bạn đóng vai "hết pin" mà không phải tắt app.

### Lượt 3: chọn ghế, mọi người cùng thấy

Vỏ, server, dưới `snapshot()`:

```dart
// Everyone listening gets the new state.
void broadcast() {
  for (final socket in clients.keys) {
    socket.add(snapshot());
  }
}
```

Lõi server, trong `handle`: tin có `op` là `lock` thì ghi khoá `{'status': 'selecting', 'userId': uid}` cho ghế
`message['seat']`, rồi `broadcast()`.

Lõi app, `_label(code)`: không có khoá → mã ghế; khoá của mình → `A1 (tôi)`; khoá người khác → `A1 (<tên người đó>)`.
"Mình" là `widget.uid`.

Bấm một nút bên trái, **bên phải đổi theo** mà không ai bấm gì bên đó. Đó là `broadcast`: `update` gọi `show` cho mọi
màn đang mở (bài 16 lượt 4).

### Lượt 4: không cướp được ghế

Vỏ, server:

```dart
void sendError(WebSocket socket, String code, String message) {
  socket.add(jsonEncode({'error': message, 'code': code}));
}
```

Lõi server, `handle`:
- `lock` mà ghế đang có khoá của **người khác**: `return sendError(socket, 'seat-locked-by-other', 'Ghế $code đã có
  người chọn.');`. Chỉ người bấm nhận câu này, không `broadcast`.
- `unlock` mà khoá đúng là của người gửi: xoá khoá, `broadcast()`.

Lõi app, `_tapSeat`: ghế đang là của mình thì gửi `unlock`, còn lại gửi `lock`.

App **không** tự chặn "ghế người khác thì không bấm được". Nó cứ gửi, server từ chối. Thêm chặn ở app cho đỡ một
lượt gửi thì được, nhưng luật phải nằm ở server.

### Lượt 5a: nhìn cái hỏng

Không viết gì. An giữ A1, A2, rồi bấm `Rớt mạng` bên An. Terminal 1 in `an rớt mạng`: server **biết**, nhưng chưa ai
dặn nó phải làm gì.

### Lượt 5b: lời dặn (lõi bài 19)

Lõi server:
- Sổ `onDisconnect`: Map từ **kết nối** (`WebSocket`) tới danh sách ghế phải xoá.
- `lock` thành công: ghi thêm ghế đó vào lời dặn của `socket`. `unlock`: gỡ ghế đó khỏi lời dặn.
- Trong `onDone`: lấy lời dặn của `socket` ra (lấy xong là hết), xoá các ghế đó khỏi `seats`, in
  `<uid> rớt mạng -> xoá <danh sách>`, `broadcast()`.

Lời dặn gắn với **kết nối**, không gắn với người: An nối bằng hai máy thì máy nào rớt chỉ nhả ghế của máy đó.

Để ý bên An sau khi rớt: vẫn hiện `A1 (tôi)`. Màn hình mất kết nối thì chỉ còn **bản sao cũ**. Bấm `Nối lại`: nhận
`snapshot()` mới, ghế đã trống.

### Lượt 6: hạn giữ (lõi bài 18)

Vỏ, server (đầu file thêm `import 'dart:async';`):

```dart
const seatHold = Duration(seconds: 20);
```

và trong `main`, dưới dòng `print('Server chạy ...')`:

```dart
  Timer.periodic(const Duration(seconds: 1), (_) => cleanupExpiredSeatLocks());
```

Lõi server:
- Khoá có thêm `expiresAt` = bây giờ + `seatHold`, lưu dạng số mili-giây
  (`DateTime.now().add(seatHold).millisecondsSinceEpoch`).
- Khoá người khác chỉ chặn khi **còn hạn** (bài 18 lượt 3).
- `cleanupExpiredSeatLocks()`: tìm các ghế có khoá quá hạn; không có thì thôi; có thì xoá, in
  `hết hạn -> xoá <danh sách>`, `broadcast()`.

Xoá khỏi một Map **trong lúc đang lặp qua chính nó** là lỗi. Gom mã ghế cần xoá ra một List trước:

```dart
final diem = {'An': 3, 'Chi': 8};
final truot = [
  for (final ten in diem.keys)
    if (diem[ten]! < 5) ten,
];
truot.forEach(diem.remove);
print(diem); // {Chi: 8}
```

**Thử phá:** tắt job (xoá dòng `Timer.periodic`). An giữ A1, đợi quá 20 giây: màn hình hai bên **vẫn** `A1 (an)`,
nhưng Bình bấm A1 thì **được**. Luật đúng nằm ở dòng kiểm hạn; job chỉ dọn cho màn hình khỏi nói dối. Trả lại.

### Lượt 7a: đặt vé, chưa kiểm gì

Vỏ, app. Trong `_SeatPanelState` thêm field `Map<String, dynamic> _sold = {};`; trong `_onMessage` thêm
`_sold = message['sold'] ?? _sold;` và sửa dòng `_message` thành
`_message = message['error'] ?? message['booked'] ?? _message;`. Đầu `_label` thêm:

```dart
    if (_sold[code] != null) return '$code (đã bán)';
```

Thêm hàm và nút (nút đặt trên nút `Rớt mạng`):

```dart
  void _book() {
    final mine = [
      for (final code in seatCodes)
        if (_seats[code]?['userId'] == widget.uid) code,
    ];
    _send({'op': 'book', 'seats': mine});
  }
```

```dart
          FilledButton(onPressed: _book, child: const Text('Đặt vé')),
```

Vỏ, server: sổ ghế, và `snapshot` gửi cả hai:

```dart
// seat code -> booking that owns it. Only the server writes here.
final seatLedger = <String, String>{};

String snapshot() => jsonEncode({'seats': seats, 'sold': seatLedger});
```

Khung hàm `book`, và dòng gọi nó ở **đầu** `handle` (tin `book` không có `seat`):

```dart
void book(WebSocket socket, String uid, List<dynamic> codes) {
  if (codes.isEmpty) {
    return sendError(socket, 'invalid-argument', 'Chưa chọn ghế nào.');
  }
  // lõi
}
```

```dart
  if (message['op'] == 'book') {
    return book(socket, uid, message['seats']);
  }
```

Lõi server, `book` bản đầu: mã đơn là `'${uid}_${seatLedger.length + 1}'`. Với mỗi ghế: ghi vào sổ, xoá khoá đang
chọn, gỡ khỏi lời dặn của `socket` (bài 19 lượt 5: ghế đã thành đơn thì rớt mạng không được nhả). In
`<uid> đặt <ghế> -> <mã đơn>`, gửi riêng người đặt `{'booked': mã đơn}`, rồi `broadcast()`.

Vỏ, `server\kexau.dart`:

```dart
import 'dart:convert';
import 'dart:io';

// Never opens the app: tells the server to book A1 directly.
void main() async {
  final socket = await WebSocket.connect('ws://localhost:3000/?uid=kexau');
  socket.listen((text) {
    final Map<String, dynamic> message = jsonDecode(text);
    if (message['seats'] == null) print('kexau nhận: $text');
  });
  socket.add(
    jsonEncode({
      'op': 'book',
      'seats': ['A1'],
    }),
  );
  await Future.delayed(const Duration(seconds: 1));
  await socket.close();
}
```

An giữ A1, bấm Đặt vé. Rồi `dart run kexau.dart`: kẻ xấu cũng "đặt được" A1, sổ ghế giờ ghi A1 thuộc đơn của nó. An
đã có mã đơn `an_1` trong tay mà mất ghế.

### Lượt 7b: sổ ghế (lõi bài 20)

Lõi server:
- `book`: **trước khi ghi bất cứ gì**, ghế nào trong danh sách đã có trong `seatLedger` thì
  `return sendError(socket, 'seat-taken', 'Ghế $code đã có người đặt.');`.
- `lock`: ghế đã có trong sổ thì cũng trả đúng lỗi đó (ghế đã bán thì khỏi giữ).

Kiểm **hết** rồi mới ghi, không vừa kiểm vừa ghi: đơn hai ghế mà ghế thứ hai đã bán thì ghế thứ nhất không được lỡ
ghi vào sổ (bài 9).

Thử thêm một ca: khởi động lại server, An **mới chỉ giữ** A1 (chưa đặt), chạy `kexau.dart`. Kẻ xấu đặt **được**, hai
bên thành `A1 (đã bán)`; An bấm Đặt vé thì nhận `Chưa chọn ghế nào.` Đúng thiết kế: khoá đang chọn chỉ là phép lịch
sự giữa những người dùng app; ai đặt trước thì được. Server không coi khoá là quyền.

## Vướng

- Cả hai cột `mất kết nối` ngay khi mở: server chưa chạy. Chạy server rồi bấm `Nối lại`.
- Sửa server xong, app vẫn hiện trạng thái cũ: kho nằm trong RAM, server mới là kho trắng; bấm `R` ở terminal 2.
- `Concurrent modification during iteration`: đang xoá khỏi `seats` trong lúc lặp qua nó (gợi ý lượt 6).
- `kexau.dart` không in gì: server chưa có nhánh `book`, nên không ai trả lời nó.

## Vỏ đã cắt (đồ thật có, bài này không)

- Sổ ghế ở đây là "ghế → mã đơn" và không bao giờ nhả. Thật: ghế có chủ khi đơn chủ **còn sống** (bài 20 lượt 4), và
  kiểm + ghi nằm trong transaction của `createBooking` cùng với tiền và kho vé (bài 12).
- Sang trang thanh toán thì hạn giữ dài ra (5 phút) và lời dặn bị hủy **trước khi** có đơn. Ở đây gộp vào lúc đặt.
- Ai là ai lấy từ `?uid=`. Thật: kết nối mang token (bài 4), rules kiểm `auth.uid`.
- Thật: **app** ghi khoá thẳng vào Realtime Database, rules chỉ kiểm hình dạng và chủ khoá; phần "người khác đang
  giữ, còn hạn thì thôi" nằm trong transaction phía app. Ở đây server kiểm hết.
- Server gửi lại **toàn bộ** trạng thái mỗi lần đổi. Sự kiện 5.000 ghế thì phải gửi phần thay đổi.
- Rút dây mạng thật (không phải bấm nút) thì `onDone` không chạy ngay: kết nối không được đóng đàng hoàng, server
  phải tự dò bằng tin "còn sống không" định kỳ. Vì vậy hạn giữ ở lượt 6 vẫn cần.

## Bắc cầu sang project

| Bài 21 | EH |
|---|---|
| Kết nối WebSocket mở sẵn | SDK `firebase_database` tự mở và giữ; code EH không có dòng nào |
| `seats` | `eventState/{eventId}/seats/{seatCode}` (`seat_lock_remote_datasource.dart` dòng 92–96) |
| `snapshot()` gửi ngay + `broadcast()` | `_seatsRef(eventId).onValue` (dòng 107–137); **không có dòng nào** phía server |
| `_onMessage` → `setState` | `booking_create_bloc.dart` dòng 148: `watchSeatStates(...)` đổ vào state của bloc |
| `_label` | Trang chọn ghế tô màu theo `SeatLockState` (`status`, `userId`, `isExpired`) |
| `lock` + kiểm chủ + kiểm hạn | `lockSeat`, dòng 140–195 (bài 18) |
| `seat-locked-by-other` | Dòng 180–185: `ServerException(errorCode: 'seat-locked-by-other')`, cùng mã |
| Bấm → gửi → chờ server | `booking_create_bloc.dart` dòng 425–445: bloc tô ghế **trước** (lạc quan) rồi mới `lockSeat`, thua thì hoàn lại |
| `unlock` | `unlockSeat`, dòng 197–227 |
| `onDisconnect[socket]` + `onDone` | Dòng 188: `ref.onDisconnect().remove()`; phần server **không có dòng nào** |
| `seatHold`, `expiresAt` | Dòng 12 (1 phút), dòng 147 |
| `cleanupExpiredSeatLocks` | `functions/bookings/cleanupExpiredSeatLocks.js`, cùng tên, chạy mỗi phút |
| `book` gỡ lời dặn | `extendSeatLock` dòng 248: `onDisconnect().cancel()`; bloc gọi ở dòng 536–545 trước khi tạo đơn |
| `seatLedger`, `seat-taken` | gd4 Bước 4, `seatLedger.ts` (bài 20) |
| `kexau.dart` | Đòn "Hai người một ghế" đầu `gd04_phan_server.md` |

Bài này có nhiều hàng "không có dòng nào" nhất: gần như cả `main.dart` phía server của bạn là thứ Realtime Database
làm sẵn. Code EH chỉ có phần app; giờ bạn biết đầu bên kia làm gì.

## Git

`git add bai21/bai21.md bai21/server/*.dart bai21/app`.

## Xong khi

- [ ] Đi trọn vòng: An giữ 2 ghế → Bình thấy và bị từ chối → An rớt mạng, ghế nhả → An nối lại, giữ, đặt → Bình thấy
  đã bán → `kexau.dart` bị `seat-taken`
- [ ] Đã thấy 4 cái hỏng: lượt 3 (cướp ghế), 5a (ghế kẹt), 7a (một ghế hai đơn), và thử phá lượt 6 (màn hình nói dối)
- [ ] Nhìn bảng bắc cầu, chỉ ra được dòng code của mình ứng với từng hàng
- [ ] Trả lời được trọn hai câu: "How do you stop two users booking the same seat?" và "A user holds seats, then
  loses connection or leaves: how are the seats released?"
