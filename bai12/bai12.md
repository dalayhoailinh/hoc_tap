# Bài 12: ghép thành hệ đặt vé và hủy vé chạy thật

**Lõi một câu:** nút "Xác nhận đặt vé" chỉ gửi **ý định**; server tự tính tiền (bài 7, 8), đọc rồi ghi ba chỗ trong
**một transaction** (bài 2, 9), đặt tên đơn theo mã ý định để bấm hai lần vẫn một đơn (bài 3). Nút "Hủy đặt vé" là
một transaction nữa, trả kho đúng một lần dù còn trigger cũ (bài 10). Cuối cùng khoá cửa app (bài 11).

Không có lõi mới. Bài này ráp 7 lõi đã học thành đúng hình của `createBooking.ts`, `cancelBooking.ts` mà bạn sẽ gõ ở
gd3. Tên hàm, tên bước, mã lỗi lấy theo guide gd3.

Khác bài 6: phần đăng nhập bị cắt (bài 6 làm rồi). Token **chính là tên người dùng** (`Bearer an`). Bài 4 thử phá 1
đã cho thấy vì sao đồ thật không được làm vậy.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai12
mkdir server
flutter create --empty --platforms=windows app
cd app
flutter pub add http
```

| | Server | App |
|---|---|---|
| File | `server\main.dart`, `db.dart`, `booking.dart`, `booking_test.dart` | `app\lib\api.dart`, `app\lib\main.dart` |
| Chạy | Terminal 1: `cd D:\dev\hoc\bai12\server` → `dart run main.dart` | Terminal 2: `cd D:\dev\hoc\bai12\app` → `flutter run -d windows` |
| Sửa xong | `Ctrl+C` rồi chạy lại | Lưu file, bấm `R` ở terminal 2 |
| Lệnh phụ | Terminal 3, cũng trong `server\`: `dart run booking_test.dart`, `dart run tranh.dart`, `dart run kexau.dart` | |

- Kho là 3 file txt trong `server\`, mỗi dòng một doc dạng JSON: `events.txt` (sự kiện + các loại vé), `bookings.txt`
  (đơn), `buyers.txt` (mỗi người đã đặt mấy đơn). Mở bằng VS Code để nhìn dữ liệu đổi, như nhìn Emulator UI.
- **Làm lại từ đầu:** `Ctrl+C` server, ở terminal 3 gõ `Remove-Item *.txt`, chạy lại server. Lượt nào ghi "kho mới"
  thì làm bước này trước.
- Sự kiện mẫu server tự tạo: **Vé mời** giá 0, có 5 vé; **VIP** giá 500000, có 3 vé.

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** server: `db.dart` + `GET /event` | Trình duyệt mở `localhost:3000/event` → JSON có 2 loại vé; `events.txt` xuất hiện |
| 2 | **Vỏ** app: trang chọn vé, nút bấm hiện nguyên câu server trả (TẠM) | Thấy `Vé mời · 0đ`, `Còn 5`, `VIP · 500000đ`, `Còn 3`. Chọn VIP, bấm `+`, bấm Xác nhận → `404 {"error":"Không có đường này"}` |
| 3 | **Lõi** `planBooking` (bài 7, 8) + file thử | `dart run booking_test.dart` → `4/4 ca đúng` |
| 4 | `POST /createBooking` bản đầu: khoá 401 (bài 4), gọi `planBooking`, **chưa ghi** (TẠM) | 2 VIP → `200 {..."totalAmount":1000000,"isFree":false}` dù app gửi tổng khác; bấm `+` tới 4 → `400 {"error":"Vé \"VIP\" chỉ còn 3 chỗ.","code":"sold-out"}` |
| 5a | **Lõi** `runTransaction` bản nháp (bài 9); ghi **đơn** | `bookings.txt` có đơn `pending`, `totalAmount` 1000000. Đặt 2 VIP **hai lần** đều được: 4 vé VIP trong khi chỉ có 3 ← kho chưa ai trừ |
| 5b | **Lõi** `applySold`; ghi thêm **kho** và **hạn mức** | `7/7 ca đúng`. Kho mới: đặt 2 VIP → `Còn 1`; đặt 2 VIP nữa → `sold-out`. Đặt 1 vé mời bốn lần: lần thứ tư `booking-limit` (đã đủ 4 đơn) |
| 6 | **Lõi** idempotency (bài 3): app sinh mã ý định một lần mỗi trang, server đặt tên đơn `uid_mã` | Kho mới: bấm Xác nhận **hai lần liền** → lần hai `"duplicate":true`, `Còn` không giảm thêm, `bookings.txt` một dòng |
| 7 | App: trang **Vé của tôi**; đặt xong tự sang đó | Đặt 2 VIP → sang Vé của tôi, thấy `VIP × 2 · 1000000đ`, `pending`. Bấm `Tôi là: an` → danh sách của Bình trống |
| 8a | **Vỏ**: database "ở xa" + `tranh.dart` (hai người cùng lúc) | Kho mới: `dart run tranh.dart` → **cả An lẫn Bình `200`**; `events.txt` ghi VIP `"sold":2` mà `bookings.txt` có 2 đơn × 2 vé ← bán trùng |
| 8b | **Lõi** số phiên bản (bài 2 lượt 4–5) | Kho mới: một người `200`, người kia `400 sold-out`; terminal 1 có `bị chen, chạy lại` |
| 9a | **Lõi** `canCancel` (bài 8) + ca thử | `12/12 ca đúng` |
| 9b | **Lõi** `releaseBooking` + `POST /cancelBooking`; app: nút Hủy | Đặt 1 vé mời (`confirmed`) → bấm Hủy đặt vé → `cancelled`; về tab Đặt vé: `Còn 5` |
| 10a | **Vỏ**: trigger cũ (đồ có sẵn trong EH) | Kho mới: An đặt 2 vé mời, Bình đặt 1, An hủy → `events.txt`: `"ticketsSold":-1`, vé mời `"sold":0` ← trả hai lần, vé của Bình "biến mất" |
| 10b | **Lõi** dấu `inventoryReleasedAt` (bài 10) | Làm lại như 10a → `"ticketsSold":1`, `"sold":1`; terminal 1: `trigger: người hủy đã trả kho, bỏ qua`; `14/14 ca đúng` |
| 11a | **Vỏ**: cửa app + rules cũ + `kexau.dart` | `dart run kexau.dart` → `kexau: 200 {"ok":true}`; `bookings.txt` có đơn `confirmed`, 3 VIP, 0 đồng |
| 11b | **Lõi** khoá cửa app (bài 11) | Kho mới: `kexau: 403 {"error":"Rules không cho ghi.","code":"permission-denied"}`; app vẫn đặt và hủy được |

## Từng lượt

### Lượt 1: khung server và kho (vỏ)

`server\db.dart`:

```dart
import 'dart:convert';
import 'dart:io';

// 'bookings/an_x1' -> file bookings.txt, id an_x1. One JSON doc per line.
File _file(String path) => File('${path.split('/')[0]}.txt');

List<Map<String, dynamic>> readCollection(String name) {
  final file = File('$name.txt');
  if (!file.existsSync()) return [];
  return [
    for (final line in file.readAsLinesSync())
      if (line.isNotEmpty) jsonDecode(line),
  ];
}

Map<String, dynamic>? readDoc(String path) {
  final id = path.split('/')[1];
  for (final doc in readCollection(path.split('/')[0])) {
    if (doc['id'] == id) return doc;
  }
  return null;
}

void writeDoc(String path, Map<String, dynamic> doc) {
  final id = path.split('/')[1];
  final docs = readCollection(path.split('/')[0]);
  docs.removeWhere((old) => old['id'] == id);
  docs.add({'id': id, ...doc});
  _file(path).writeAsStringSync(docs.map((d) => '${jsonEncode(d)}\n').join());
}
```

`server\main.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'db.dart';

void send(HttpRequest req, int status, Object body) {
  print('${req.method} ${req.uri.path} -> $status');
  req.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}

Future<void> handle(HttpRequest req) async {
  final route = '${req.method} ${req.uri.path}';

  if (route == 'GET /event') {
    return send(req, 200, readDoc('events/e1')!);
  }
  send(req, 404, {'error': 'Không có đường này'});
}

void main() async {
  if (readDoc('events/e1') == null) {
    writeDoc('events/e1', {
      'title': 'Đêm nhạc',
      'startAt': '2030-12-24T19:00:00',
      'ticketsSold': 0,
      'ticketTypes': [
        {'id': 'moi', 'name': 'Vé mời', 'price': 0, 'quantity': 5, 'sold': 0},
        {'id': 'vip', 'name': 'VIP', 'price': 500000, 'quantity': 3, 'sold': 0},
      ],
    });
  }
  final server = await HttpServer.bind('localhost', 3000);
  print('Server chạy ở http://localhost:3000');
  server.listen(handle);
}
```

- Đường dẫn doc viết như Firestore: `'events/e1'` là doc `e1` trong collection `events`. `readDoc` trả `null` khi
  không có, như `snapshot.exists == false`.
- `ticketTypes` là **một mảng nằm trong doc sự kiện**, như `private/detail.ticketTypes` của EH. Lượt 5b sẽ thấy vì
  sao chuyện này đáng để ý.
- Khác bài 6 một dòng: `server.listen(handle)` thay cho `await for`. Request tới là xử lý ngay, **không xếp hàng**
  chờ request trước xong. Server thật đều vậy; lượt 8 sẽ thấy cái giá.

### Lượt 2: khung app (vỏ)

`app\lib\api.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

// TẠM: the token is the user's name.
var uid = 'an';

Uri _url(String path) => Uri.parse('http://localhost:3000$path');

Map<String, String> _headers() => {'authorization': 'Bearer $uid'};

Future<Map<String, dynamic>> getJson(String path) async {
  final res = await http.get(_url(path), headers: _headers());
  return jsonDecode(res.body);
}

// TẠM — lượt 7: trả Map hoặc ném lỗi
Future<String> call(String name, Map<String, dynamic> data) async {
  final res = await http.post(
    _url('/$name'),
    headers: _headers(),
    body: jsonEncode(data),
  );
  return '${res.statusCode} ${res.body}';
}
```

`app\lib\main.dart`, thay hết nội dung cũ:

```dart
import 'package:flutter/material.dart';

import 'api.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Chọn vé')),
        body: const SelectionPage(),
      ),
    ),
  );
}

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  List<dynamic> _ticketTypes = [];
  Map<String, dynamic>? _selected;
  var _quantity = 1;
  var _message = '';

  int get _total => (_selected?['price'] ?? 0) * _quantity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final event = await getJson('/event');
    if (mounted) setState(() => _ticketTypes = event['ticketTypes']);
  }

  Future<void> _submit() async {
    final message = await call('createBooking', {
      'ticketTypeId': _selected?['id'],
      'quantity': _quantity,
      'totalAmount': _total,
    });
    if (mounted) setState(() => _message = message);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final type in _ticketTypes)
            ListTile(
              title: Text('${type['name']} · ${type['price']}đ'),
              subtitle: Text('Còn ${type['quantity'] - type['sold']}'),
              selected: type['id'] == _selected?['id'],
              onTap: () => setState(() => _selected = type),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _quantity--),
                icon: const Icon(Icons.remove),
              ),
              Text('$_quantity'),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Text('Tổng: $_total đồng'),
          FilledButton(
            onPressed: _selected == null ? null : _submit,
            child: const Text('Xác nhận đặt vé'),
          ),
          Text(_message),
        ],
      ),
    );
  }
}
```

- `api.dart` là bản tí hon của gói `cloud_functions`: `call('createBooking', {...})` giống
  `httpsCallable('createBooking').call({...})`.
- App **tự tính** `_total` để hiện cho người dùng xem, và đang gửi kèm `totalAmount` lên server. Đây đúng là cách app
  EH hiện làm (bài 7 bắc cầu). Lượt 4 cho thấy server không đọc nó; lượt 6 xoá nó.
- Nút `-` bấm xuống 0 hay số âm được: cố ý. App chặn hay không thì server vẫn phải tự kiểm.

### Lượt 3: `planBooking` (lõi bài 7 + 8)

`server\booking.dart`, vỏ:

```dart
const maxTicketsPerBooking = 10;
const maxBookingsPerUser = 4;

Map<String, dynamic> reject(String code, String message) {
  return {'ok': false, 'code': code, 'message': message};
}

Map<String, dynamic> planBooking(
  Map<String, dynamic> input,
  List<dynamic> ticketTypes,
  int buyerBookingCount,
) {
  // lõi
}
```

Lõi, tự viết. `planBooking` là hàm thuần: không đọc file, không biết HTTP. Thứ tự kiểm, mỗi cái một mã:

| Kiểm | Mã | Câu cho người đọc |
|---|---|---|
| Người mua đã đủ `maxBookingsPerUser` đơn | `booking-limit` | `Mỗi người chỉ được đặt tối đa 4 đơn.` |
| Không có loại vé mang id `input['ticketTypeId']` | `ticket-type-not-found` | `Loại vé không tồn tại.` |
| Số còn (`quantity - sold`) ít hơn số muốn mua | `sold-out` | `Vé "VIP" chỉ còn 1 chỗ.` |

Qua hết thì trả `{'ok': true, 'ticketTypeId', 'ticketTypeName', 'price', 'quantity', 'totalAmount', 'isFree'}`, trong
đó `totalAmount` = giá **của server** × số lượng, `isFree` là tổng bằng 0.

Tìm một phần tử trong List theo id (dữ liệu khác bài):

```dart
final menu = [{'id': 'pho', 'gia': 40}, {'id': 'bun', 'gia': 45}];
Map<String, dynamic>? mon;
for (final m in menu) {
  if (m['id'] == 'bun') mon = m;
}
print(mon); // {id: bun, gia: 45}; không có thì vẫn là null
```

`server\booking_test.dart`: tự viết hàm `check` như bài 8 lượt 7 (đếm cả số ca đã chạy, in `$passed/$total ca đúng`),
`import 'booking.dart';` ở đầu. Dữ liệu thử: một loại vé `vip`, giá 500000, có 3, đã bán 2. Bốn ca:

| Ca | Gọi | Mong |
|---|---|---|
| tiền do server tính | mua 1 `vip`, input **có kèm** `totalAmount: 1` | `['totalAmount']` là 500000 |
| loại vé bịa | mua 1 `free` | `['code']` là `ticket-type-not-found` |
| mua quá số còn | mua 2 `vip` | `sold-out` |
| đủ 4 đơn rồi | mua 1 `vip`, người mua đã có 4 đơn | `booking-limit` |

**Thử phá ngay:** đổi `<` thành `<=` ở chỗ so số còn. Ca nào `SAI`? (Còn 1 vé, mua 1 vé.) Trả lại.

### Lượt 4: `createBooking` bản đầu

Vỏ, thêm vào `main.dart`. Đầu file thêm `import 'booking.dart';`. Dưới các dòng import:

```dart
class HttpsError {
  HttpsError(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
}
```

Đổi tên hàm `handle` cũ thành `route`, rồi thêm hàm `handle` mới bên dưới nó:

```dart
Future<void> handle(HttpRequest req) async {
  try {
    await route(req);
  } on HttpsError catch (e) {
    send(req, e.status, {'error': e.message, 'code': e.code});
  }
}
```

Trong `route`, dưới dòng `final route = ...`, đọc body như bài 6:

```dart
  final Map<String, dynamic> body = req.method == 'POST'
      ? jsonDecode(await utf8.decoder.bind(req).join())
      : {};
```

Trên hàm `route`, khung của callable. Phần kiểm hình dạng dữ liệu là vỏ:

```dart
Future<Map<String, dynamic>> createBooking(
  String uid,
  Map<String, dynamic> input,
) async {
  final quantity = input['quantity'];
  if (input['ticketTypeId'] is! String ||
      quantity is! int ||
      quantity < 1 ||
      quantity > maxTicketsPerBooking) {
    throw HttpsError(400, 'invalid-argument', 'Dữ liệu đặt vé không hợp lệ.');
  }
  // lõi
}
```

Lõi, tự viết:
- Trong `route`, dưới nhánh `GET /event`: **cái khoá** (bài 4 lượt 3, bài 6 lượt 5a). Đọc header `authorization`, bỏ
  chữ `Bearer `, ra `uid`. Không có thì `throw HttpsError(401, 'unauthenticated', 'Bạn cần đăng nhập.')`.
- Dưới khoá: `POST /createBooking` → `send(req, 200, await createBooking(uid, body))`.
- Trong `createBooking`: đọc doc sự kiện, gọi `planBooking` (số đơn của người mua tạm để `0`). Bị từ chối thì
  `throw HttpsError(400, mã, câu)`. Được thì trả luôn kết quả của `planBooking`, kèm dòng `// TẠM — lượt 5a: ghi đơn`.

Để ý: `throw` ở bất kỳ đâu bên dưới đều bay lên `handle`, thành một câu trả lời có **hai mặt**: `code` cho máy,
`error` cho người. App hiện nguyên văn.

**Thử phá ngay** (đóng vai kẻ sửa giá): trong `_submit` của app đổi `'totalAmount': _total` thành `'totalAmount': 1`,
bấm `R`, đặt 2 VIP. Server vẫn trả `1000000`. Để nguyên số 1 đó tới lượt 6.

### Lượt 5a: ghi đơn qua bản nháp (lõi bài 9)

Cuối `db.dart`, khung:

```dart
class Tx {
  // lõi
}

Future<Map<String, dynamic>> runTransaction(
  Future<Map<String, dynamic>> Function(Tx tx) body,
) async {
  // lõi
}
```

Dòng `Future<...> Function(Tx tx) body` đọc là: "tham số `body` là **một hàm** nhận một `Tx` và trả một Future".
Bạn đã *đưa* hàm cho `where`, `listen` nhiều lần; đây là lần đầu *nhận* một hàm.

Lõi, tự viết:
- `Tx` có ba thứ: Map `draft` (đường dẫn → doc), hàm `get(path)` trả doc đọc từ kho, hàm `set(path, doc)` ghi vào
  `draft`. Khai `get` là `async` và trả `Future<Map<String, dynamic>?>`: đọc database thật phải đi qua mạng.
- `runTransaction`: tạo `Tx`, `await body(tx)`, **rồi mới** đổ `draft` vào kho bằng `writeDoc`, trả kết quả của
  `body`.

```dart
final nhap = {'a/1': {'x': 1}, 'b/2': {'y': 2}};
nhap.forEach((path, doc) => print('$path = $doc'));
// a/1 = {x: 1}
// b/2 = {y: 2}
```

Vỏ, cuối `booking.dart`, hình dạng doc đơn:

```dart
Map<String, dynamic> buildBookingDoc(
  String uid,
  Map<String, dynamic> event,
  Map<String, dynamic> plan,
  DateTime now,
) {
  final bool isFree = plan['isFree'];
  return {
    'userId': uid,
    'eventTitle': event['title'],
    'eventStartAt': event['startAt'],
    'ticketTypeId': plan['ticketTypeId'],
    'ticketTypeName': plan['ticketTypeName'],
    'price': plan['price'],
    'quantity': plan['quantity'],
    'totalAmount': plan['totalAmount'],
    'status': isFree ? 'confirmed' : 'pending',
    'paymentStatus': isFree ? 'not_required' : 'awaiting',
    'createdAt': now.toIso8601String(),
  };
}
```

Đơn miễn phí xác nhận ngay; đơn có phí nằm ở `pending` chờ thanh toán (bài 17 làm tiếp). Đơn **chép** tên sự kiện và
giờ bắt đầu vào mình: trang vé và việc hủy khỏi phải mở lại doc sự kiện.

Lõi, sửa `createBooking`: mã đơn tạm là `'${uid}_${DateTime.now().millisecondsSinceEpoch}'` (ghi
`// TẠM — lượt 6`). Phần còn lại chạy trong `return runTransaction((tx) async { ... });`: đọc sự kiện bằng `tx.get`,
`planBooking`, từ chối thì `throw` như cũ, được thì `tx.set` doc đơn vào `'bookings/$bookingId'`, rồi trả
`{'bookingId': ..., 'duplicate': false, 'paymentRequired': ...}` (`paymentRequired` là "đơn không miễn phí").

### Lượt 5b: trừ kho, cộng hạn mức

Lõi, cuối `booking.dart`: hàm thuần `applySold(ticketTypes, ticketTypeId, quantity, direction)` trả về **một mảng
mới**: phần tử mang đúng id thì `sold` cộng thêm `direction * quantity` (không bao giờ xuống dưới 0), mọi field khác
và mọi phần tử khác giữ nguyên. `direction` là `1` khi bán, `-1` khi trả.

```dart
final lop = [{'ten': 'An', 'diem': 7}, {'ten': 'Chi', 'diem': 9}];
final moi = [
  for (final hs in lop)
    if (hs['ten'] == 'An') {...hs, 'diem': 8} else hs,
];
print(moi); // [{ten: An, diem: 8}, {ten: Chi, diem: 9}]
print(lop); // [{ten: An, diem: 7}, ...]  <- mảng cũ không đổi
```

`max(a, b)` cần `import 'dart:math';`. Thêm 3 ca vào `booking_test.dart` (dữ liệu cũ: `vip` đã bán 2): bán 1 thì
`sold` là 3; bán 1 thì `name` vẫn là `VIP`; trả 9 thì `sold` là 0.

Lõi, trong transaction của `createBooking`:
- Đọc thêm `buyers/$uid` (chưa có thì coi như 0 đơn), đưa số đó vào `planBooking` thay cho số `0` tạm.
- Sau `tx.set` đơn, thêm hai lệnh ghi nháp: doc sự kiện (chép doc cũ, thay `ticketTypes` bằng kết quả `applySold`,
  `ticketsSold` cộng số vé) và `buyers/$uid` với `bookingCount` cộng 1.

Mọi `tx.get` đứng **trên** mọi `tx.set` (bài 9 thử phá 2).

Vì `ticketTypes` là một mảng trong một doc, trừ kho một loại vé là **đọc cả mảng, sửa một phần tử, ghi lại cả mảng**.
Hai người mua hai loại vé khác nhau vẫn đụng cùng một doc.

### Lượt 6: bấm hai lần (lõi bài 3)

Trước khi sửa, nhìn cái hỏng: ở lượt 5b bấm Xác nhận hai lần liền là ra **hai đơn**.

Lõi, app:
- Thêm vào `_SelectionPageState` một mã ý định sinh **một lần cho mỗi lần mở trang** (số ngẫu nhiên hệ 16 như token
  bài 4, cần `import 'dart:math';`). Nghĩ xem nó phải là field của State hay biến trong `_submit`.
- Gửi kèm `'bookingIntentId'`. Xoá dòng `'totalAmount'`: app thôi gửi tiền.

Lõi, server:
- Vỏ kiểm thêm một điều kiện: `input['bookingIntentId'] is! String` cũng là `invalid-argument`.
- Mã đơn là `'${uid}_${input['bookingIntentId']}'`.
- Trong transaction, đọc thêm `bookings/$bookingId`. **Đã có** thì trả ngay `{'bookingId': ..., 'duplicate': true,
  'paymentRequired': đơn cũ đang 'pending'}`, không ghi gì.

**Thử phá:** xoá khối "đã có thì trả ngay". Kho mới, đặt 2 vé mời, bấm hai lần: `bookings.txt` vẫn **một** đơn (tên
trùng nên ghi đè), nhưng `events.txt` ghi vé mời `"sold":4` và `buyers.txt` ghi 2 đơn. Tên đơn theo ý định mới là
một nửa; nửa kia là "có rồi thì dừng". Trả lại.

### Lượt 7: Vé của tôi

Vỏ, server, dưới cái khoá:

```dart
  // Like the read rule: owners read their own bookings.
  if (route == 'GET /bookings') {
    final mine = readCollection('bookings').where((b) => b['userId'] == uid);
    return send(req, 200, {'bookings': mine.toList()});
  }
```

Vỏ, `api.dart`: thay hàm `call` TẠM bằng bản trả dữ liệu hoặc ném lỗi:

```dart
class FunctionsException {
  FunctionsException(this.code, this.message);
  final String code;
  final String message;
}

// Like a Firebase callable: the result, or the server's code + message.
Future<Map<String, dynamic>> call(
  String name,
  Map<String, dynamic> data,
) async {
  final res = await http.post(
    _url('/$name'),
    headers: _headers(),
    body: jsonEncode(data),
  );
  final Map<String, dynamic> body = jsonDecode(res.body);
  if (res.statusCode != 200) {
    throw FunctionsException(body['code'] ?? '', body['error']);
  }
  return body;
}
```

Vỏ, `main.dart`. Hàm `main` còn một dòng:

```dart
void main() => runApp(const MaterialApp(home: Shell()));
```

Thêm vỏ hai tab và trang danh sách:

```dart
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Chọn vé' : 'Vé của tôi'),
        actions: [
          TextButton(
            onPressed: () => setState(() => uid = uid == 'an' ? 'binh' : 'an'),
            child: Text('Tôi là: $uid'),
          ),
        ],
      ),
      // New key: Flutter drops the old page and its State.
      body: _tab == 0
          ? SelectionPage(
              key: ValueKey(uid),
              onBooked: () => setState(() => _tab = 1),
            )
          : MyBookingsPage(key: ValueKey(uid)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Đặt vé'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Vé của tôi'),
        ],
      ),
    );
  }
}

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await getJson('/bookings');
    if (mounted) setState(() => _bookings = data['bookings']);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final booking in _bookings)
          ListTile(
            title: Text(
              '${booking['ticketTypeName']} × ${booking['quantity']}'
              ' · ${booking['totalAmount']}đ',
            ),
            subtitle: Text(booking['status']),
          ),
      ],
    );
  }
}
```

`SelectionPage` nhận thêm một tham số (lớp widget, không phải lớp State):

```dart
  const SelectionPage({super.key, required this.onBooked});
  final VoidCallback onBooked;
```

Lõi, `_submit`: bọc lời gọi trong `try`. Được thì gọi `widget.onBooked()`. Bắt `on FunctionsException catch (e)`: hiện
`e.message` rồi `_load()` lại (số còn có thể đã đổi).

- **Màn hình đổi theo dữ liệu, không theo nút.** Đặt xong, app không tự thêm đơn vào danh sách; nó sang trang Vé của
  tôi, trang đó hỏi server. Một nguồn sự thật.
- Mỗi lần về tab Đặt vé là một `SelectionPage` **mới**, State mới, nên mã ý định mới: đúng nghĩa "một lần mở trang".
- Trang này phải tải lại mới thấy thay đổi (TẠM). App thật nghe stream; bài 16 làm chuyện đó.

### Lượt 8a: database ở xa, hai người cùng lúc (vỏ)

Trong `db.dart`, trên lớp `Tx`:

```dart
// A real database is far away: every read takes a moment.
const latency = Duration(milliseconds: 100);
```

và dòng đầu của `Tx.get`: `await Future.delayed(latency);`

`server\client.dart`:

```dart
import 'dart:convert';
import 'dart:io';

Future<String> call(String uid, String path, Map<String, dynamic> body) async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse('http://localhost:3000$path'));
  req.headers.set('authorization', 'Bearer $uid');
  req.add(utf8.encode(jsonEncode(body)));
  final res = await req.close();
  final text = await utf8.decoder.bind(res).join();
  client.close();
  return '$uid: ${res.statusCode} $text';
}
```

`server\tranh.dart`:

```dart
import 'client.dart';

// An and Binh buy 2 VIP each at the same moment. Only 3 exist.
void main() async {
  final results = await Future.wait([
    call('an', '/createBooking', {
      'bookingIntentId': 'tranh-an',
      'ticketTypeId': 'vip',
      'quantity': 2,
    }),
    call('binh', '/createBooking', {
      'bookingIntentId': 'tranh-binh',
      'ticketTypeId': 'vip',
      'quantity': 2,
    }),
  ]);
  results.forEach(print);
}
```

`Future.wait` bắn hai request **cùng lúc** rồi đợi cả hai. Kho mới, chạy `dart run tranh.dart`: cả hai `200`. Mở
`events.txt`: VIP `"sold":2`, trông rất bình thường. Mở `bookings.txt`: hai đơn, mỗi đơn 2 vé. Đây là bài 2 lượt 3:
An đọc "còn 3", Bình đọc "còn 3", An ghi "đã bán 2", Bình ghi đè "đã bán 2".

Không có dòng `latency` thì chuyện này không xảy ra trên máy bạn (đọc file quá nhanh, request sau tới thì request
trước đã xong). Database thật thì lúc nào cũng "ở xa".

### Lượt 8b: số phiên bản (lõi bài 2)

Lõi, `db.dart`: một biến `version` cho cả kho. `Tx` nhớ `version` lúc nó được tạo. `runTransaction` chạy `body` xong
thì so: `version` đã khác lúc đầu → in `bị chen, chạy lại` và **làm lại từ đầu** (`Tx` mới, chạy lại `body`); vẫn
như cũ → áp nháp, `version` tăng 1, trả kết quả.

```dart
var lan = 0;
while (true) {
  lan++;
  if (lan < 3) continue; // quay lại đầu vòng
  break; // (trong hàm thì return cũng thoát vòng)
}
print(lan); // 3
```

- Giữa dòng so `version` và dòng áp nháp **không được có `await`**. Dart chạy một việc một lúc; không `await` thì
  không ai chen vào giữa hai dòng đó được.
- Bình không bị từ chối vì "đến sau". Bình được **chạy lại**, đọc thấy còn 1 vé, và `planBooking` trả `sold-out`. Đổi
  `tranh.dart` cho mỗi người mua 1 vé (kho mới): cả hai `200`, vẫn có dòng `bị chen, chạy lại`.
- `body` có thể chạy nhiều lần: đừng làm trong đó việc không hoàn lại được.

### Lượt 9a: `canCancel` (lõi bài 8)

Cuối `booking.dart`: `String? canCancel(Map<String, dynamic>? booking, String uid, DateTime now)`, y luật và mã của
bài 8: `booking-not-found`, `not-owner`, `not-cancellable`, `event-started`. Giờ bắt đầu nằm trong đơn dạng chữ:
`DateTime.parse(booking['eventStartAt'])`.

Thêm 5 ca vào `booking_test.dart`: chủ đơn hủy trước giờ diễn (`null`), đơn không có, đơn của người khác, đơn
`pending`, đúng giờ diễn.

### Lượt 9b: `cancelBooking` và `releaseBooking`

Vỏ, `main.dart`, trên hàm `route` (đầu file thêm `import 'dart:math';`):

```dart
// Reads first, then writes: call before any other write in `tx`.
Future<void> releaseBooking(
  Tx tx,
  String bookingPath,
  Map<String, dynamic> booking,
  String toStatus,
) async {
  // lõi
}

Future<Map<String, dynamic>> cancelBooking(
  String uid,
  Map<String, dynamic> input,
) async {
  if (input['bookingId'] is! String) {
    throw HttpsError(400, 'invalid-argument', 'Dữ liệu hủy vé không hợp lệ.');
  }
  final bookingPath = 'bookings/${input['bookingId']}';
  // lõi
}
```

và trong `route`, trên dòng 404:

```dart
  if (route == 'POST /cancelBooking') {
    return send(req, 200, await cancelBooking(uid, body));
  }
```

Lõi:
- `cancelBooking`: một transaction. Đọc đơn, hỏi `canCancel`. Không được thì `throw HttpsError(400, mã, 'Bạn không
  thể hủy vé này.')`. Được thì `await releaseBooking(tx, bookingPath, booking, 'cancelled')` rồi trả `{'ok': true}`.
- `releaseBooking`: **đọc** sự kiện và `buyers` của chủ đơn, rồi **ghi** ba chỗ: đơn (chép đơn cũ, đổi `status`,
  thêm `cancelledAt`), sự kiện (`applySold` với `-1`, `ticketsSold` trừ số vé), `buyers` (`bookingCount` trừ 1,
  không xuống dưới 0; chưa có doc thì thôi).

Vỏ, app, `_MyBookingsPageState`: thêm `var _message = '';`, trong `ListTile` thêm:

```dart
            trailing: booking['status'] == 'confirmed'
                ? TextButton(
                    onPressed: () => _cancel(booking['id']),
                    child: const Text('Hủy đặt vé'),
                  )
                : null,
```

và `Text(_message),` làm phần tử cuối của `ListView`.

Lõi, app: `_cancel(bookingId)` gọi `cancelBooking`, lỗi thì giữ `e.message` vào `_message`, xong thì `_load()`.

**Thử phá ngay:** bỏ điều kiện `booking['status'] == 'confirmed'` để nút hiện ở mọi đơn. Bấm Hủy trên đơn VIP
`pending`: `Bạn không thể hủy vé này.` Ẩn nút chỉ để dễ dùng; luật nằm ở server. Trả lại.

### Lượt 10a: sống chung với trigger cũ (vỏ)

EH có sẵn một trigger trả kho mỗi khi đơn thành `cancelled` (app cũ hủy bằng cách tự sửa `status`). Nó vẫn phải
chạy vì còn đường khác dùng nó. Dựng lại nó ở đây.

`db.dart`: trên `runTransaction` thêm chỗ đăng ký trigger:

```dart
// Runs after a booking doc changes, with the doc before and after.
void Function(Map<String, dynamic> before, Map<String, dynamic> after)?
onBookingUpdated;
```

và trong `runTransaction`, thay hai dòng "áp nháp, tăng version" bằng:

```dart
    final before = {for (final path in tx.draft.keys) path: readDoc(path)};
    tx.draft.forEach(writeDoc);
    version++;
    for (final path in tx.draft.keys) {
      final old = before[path];
      if (path.startsWith('bookings/') && old != null) {
        onBookingUpdated?.call(old, tx.draft[path]!);
      }
    }
```

`main.dart`, trên hàm `route`:

```dart
// Old trigger: returns stock whenever a booking becomes cancelled.
void onBookingStatusChanged(
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) {
  if (before['status'] == after['status']) return;
  if (after['status'] == 'cancelled') {
    final event = readDoc('events/e1')!;
    final int ticketCount = after['quantity'];
    writeDoc('events/e1', {
      ...event,
      'ticketTypes': applySold(
        event['ticketTypes'],
        after['ticketTypeId'],
        ticketCount,
        -1,
      ),
      'ticketsSold': event['ticketsSold'] - ticketCount,
    });
    print('trigger: trả $ticketCount vé về kho');
  }
}
```

và trong `main`, trên dòng `HttpServer.bind`: `onBookingUpdated = onBookingStatusChanged;`

Kho mới. Trên app: An đặt 2 vé mời; đổi sang Bình, đặt 1 vé mời; đổi về An, hủy. Đúng ra kho còn 1 vé đã bán (của
Bình). `events.txt` ghi `"ticketsSold":-1` và vé mời `"sold":0`: `releaseBooking` trả một lần, trigger trả lần nữa.

Phải có **hai người** mới thấy: chỉ một mình An thì `sold` về 0, trả thừa bị chặn ở 0, trông như đúng.

### Lượt 10b: để dấu (lõi bài 10)

Lõi:
- `booking.dart`: hàm thuần `stockReturnedByWriter(before, after)` nhận dấu của bản trước và bản sau, trả `true` khi
  hai dấu **khác nhau**. Thêm 2 ca thử: `(null, 't1')` → `true`; `(null, null)` → `false`.
- `releaseBooking`: lần ghi đơn có thêm field `inventoryReleasedAt` (cùng giá trị với `cancelledAt`).
- `onBookingStatusChanged`: trước nhánh trả kho, hỏi `stockReturnedByWriter` với `inventoryReleasedAt` của `before`
  và `after`. `true` thì in `trigger: người hủy đã trả kho, bỏ qua`, không trả.

**Thử phá:** đổi điều kiện đó thành `if (false && stockReturnedByWriter(...))`, làm lại kịch bản hai người: lại
`-1`. Guide gd3 Chặng 3.3 bảo bạn làm đúng trò này với code thật.

### Lượt 11a: cửa app còn mở (vỏ)

Trong EH, app còn ghi **thẳng** vào Firestore bằng SDK, chỉ qua rules. Dựng lại cửa đó. `main.dart`, trên hàm
`route`:

```dart
// What the app may write through its own door.
bool rules(String uid, String path, Map<String, dynamic> doc) {
  if (path.startsWith('bookings/')) {
    return doc['userId'] == uid &&
        ['pending', 'confirmed'].contains(doc['status']);
  }
  return false;
}
```

trong `route`, trên dòng 404:

```dart
  // App door: like the client SDK writing straight to the database.
  if (route == 'POST /write') {
    final String path = body['path'];
    final Map<String, dynamic> doc = body['doc'];
    if (!rules(uid, path, doc)) {
      throw HttpsError(403, 'permission-denied', 'Rules không cho ghi.');
    }
    writeDoc(path, doc);
    return send(req, 200, {'ok': true});
  }
```

`server\kexau.dart`:

```dart
import 'client.dart';

// Writes a booking through the app door, never calling createBooking.
void main() async {
  print(
    await call('kexau', '/write', {
      'path': 'bookings/kexau_gia',
      'doc': {
        'userId': 'kexau',
        'eventTitle': 'Đêm nhạc',
        'eventStartAt': '2030-12-24T19:00:00',
        'ticketTypeId': 'vip',
        'ticketTypeName': 'VIP',
        'price': 0,
        'quantity': 3,
        'totalAmount': 0,
        'status': 'confirmed',
        'paymentStatus': 'not_required',
      },
    }),
  );
}
```

`dart run kexau.dart` → `200`. Kẻ xấu có 3 vé VIP `confirmed`, 0 đồng. `planBooking`, transaction, idempotency của
bạn đều đúng và đều **không được gọi tới**. Kho cũng không bị trừ: 3 vé VIP đó vẫn bán được cho người khác.

### Lượt 11b: khoá (lõi bài 11)

Lõi: `rules` trả `false` cho mọi lần ghi vào `bookings`. Kho mới, chạy lại `kexau.dart`: `403`. App vẫn đặt và hủy
bình thường, vì nó đã đi cửa server từ lượt 4.

Thứ tự này không đảo được: app phải gọi `createBooking`, `cancelBooking` **trước**, rồi mới khoá.

## Vướng

- App trắng, terminal 2 có `ClientException ... refused`: server chưa chạy.
- Số liệu không giống cột "Chạy thấy": kho còn dữ liệu của lượt trước. Làm lại từ đầu (mục Chuẩn bị).
- `tranh.dart` chạy lần hai ra `"duplicate":true`: đúng, vì mã ý định trong file đó cố định. Kho mới rồi chạy lại.
- `Unhandled exception: Invalid argument (string): Contains invalid characters` khi chạy `kexau.dart`: trong
  `client.dart` đang dùng `req.write(...)`. Chữ có dấu phải gửi bằng `req.add(utf8.encode(...))`.
- Sửa `booking.dart` xong mà server "không ăn": quên `Ctrl+C` chạy lại.

## Vỏ đã cắt (đồ thật có, bài này không)

- Một đơn chỉ một loại vé. Thật: `items` là mảng, `planBooking` có vòng lặp và kiểm trùng loại vé, trùng ghế.
- Không kiểm sự kiện đã mở bán chưa, đã kết thúc chưa (`event-not-available`, `event-ended`), nên `planBooking` ở đây
  không cần `nowMs`.
- Không đòi xác minh email (`email-not-verified`).
- Kiểm hình dạng dữ liệu bằng mấy dòng `is!`. Thật: zod, một schema khai một lần.
- Một số `version` cho cả kho: ai ghi gì cũng làm người khác chạy lại. Firestore theo dõi **từng doc đã đọc**.
- Trigger ở đây chạy đúng một lần, ngay sau khi ghi. Thật: chạy sau vài trăm mili-giây tới vài giây, và có thể hai
  lần (bài 10).
- Hạn mức ở đây là số cứng 4. Thật: `maxBookingsPerUser` nằm trong doc sự kiện.
- Giờ là giờ của máy chạy server, chữ ISO. Thật: `Timestamp`.

## Bắc cầu sang project

| Bài 12 | gd3 / EH |
|---|---|
| `api.call('createBooking', {...})` | `_functions.httpsCallable('createBooking').call({...})` (patch `gd03_flutter_sau_server.patch`, datasource) |
| `FunctionsException(code, message)` | `FirebaseFunctionsException`: `e.message`, mã nằm ở `e.details['code']` |
| Mã ý định là field của State | `BookingCreateBloc`: `final String _bookingIntentId = _newBookingIntentId();` (cùng patch) |
| Khoá 401 | `if (!auth) throw new HttpsError("unauthenticated", ...)`. Firebase đã kiểm token hộ (bài 4) |
| Mấy dòng `is!` | `createBookingSchema.safeParse(request.data)` (Chặng 1.1, `types.ts`) |
| `planBooking` + `reject` | Chặng 1.1, `planBooking.ts`: cùng tên, cùng mã, cùng thứ tự |
| `booking_test.dart` | `planBooking.test.ts`, `inventory.test.ts`, `cancelPolicy.test.ts`, `stockGuard.test.ts` (`npm test`) |
| `applySold` | Chặng 1.2, `inventory.ts` |
| `buildBookingDoc` | Chặng 1.3, `bookingDoc.ts` |
| `createBooking`: `tx.get` ×3 → kiểm đã có → `planBooking` → `tx.set` ×3 | Chặng 2.1, `createBooking.ts`: `tx.getAll(5 ref)` → `if (bookingSnap.exists)` → `planBooking` → `tx.set`, `tx.update`, `tx.update`, `tx.set` |
| `throw HttpsError(400, mã, câu)` | `throw new HttpsError("failed-precondition", result.message, { code: result.code })` |
| `Tx`, `runTransaction`, `version`, `bị chen, chạy lại` | **Không có dòng nào.** `db.runTransaction` của Firestore làm hết |
| `tranh.dart` | Chặng 2.2, test "tranh vé cuối" trong `booking.integration.test.ts` (`Promise.all`) |
| `GET /bookings` lọc theo `uid` | App đọc thẳng Firestore, `firestore.rules` khối `bookings` phần `allow read`; `booking_remote_datasource.dart` dòng 290–320 `watchMyBookings` (stream) |
| `canCancel` | Chặng 3.1, `cancelPolicy.ts` |
| `releaseBooking` | Chặng 3.2, `release.ts` |
| `cancelBooking` | Chặng 3.2, `cancelBooking.ts` |
| `onBookingStatusChanged` (vỏ lượt 10a) | `functions/bookings/onBookingStatusChanged.js` dòng 26–71, code JS cũ có thật |
| `onBookingUpdated = ...` | `onDocumentUpdated({ document: 'bookings/{bookingId}' }, ...)` (dòng 26–28) |
| `stockReturnedByWriter` + sửa trigger | Chặng 3.2, `stockGuard.ts` + 2 chỗ sửa trong file JS cũ |
| `POST /write` + `rules` cũ | SDK client + `firestore.rules` dòng 247–258. `booking_remote_datasource.dart` dòng 233 và 404 đang đi cửa này |
| `kexau.dart` | Chặng 4.1, `rules-tests/bookings.rules.test.ts` (6 đòn) |
| Lượt 11b | Chặng 4.2, chỗ ⑤: `allow create: if false;` |

Hàng đáng nhớ nhất vẫn là hàng "không có dòng nào": cả `db.dart` phần transaction của bạn nằm trong Firestore. Đọc
`createBooking.ts` chỉ thấy `tx.getAll`, `tx.set`; giờ bạn biết phía sau hai chữ đó có gì.

## Git

`git add bai12/bai12.md bai12/server/*.dart bai12/app`. Đừng add `bai12/server/*.txt` (dữ liệu).

## Xong khi

- [ ] Đi trọn vòng trên app: đặt 2 VIP → Vé của tôi `pending`; đặt 1 vé mời → `confirmed` → Hủy → `cancelled`, `Còn`
  về 5
- [ ] `booking_test.dart` ra `14/14 ca đúng`
- [ ] Đã thấy 4 cái hỏng: 5a (4 vé VIP), 8a (bán trùng), 10a (`-1`), 11a (đơn giả)
- [ ] Đã làm các thử phá ở lượt 3, 4, 6, 9b, 10b
- [ ] Nhìn bảng bắc cầu, chỉ ra được dòng code của mình ứng với từng hàng
- [ ] Trả lời được: "Walk me through what happens when a user taps Book" và "How do you stop two users buying the
  last ticket?"
