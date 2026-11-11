# Bài 17: ghép thành luồng thanh toán chạy thật

**Lõi một câu:** nút "Thanh toán" chỉ gửi **mã đơn**; server lấy tiền từ đơn, gọi cổng (bản giả, bài 13) lấy mã QR.
Tiền về qua **webhook có chữ ký** (bài 14); server quyết theo trạng thái đơn rồi mới tới số tiền, trong một
transaction (bài 15). Trang thanh toán **nghe đơn** nên tự sang "Đặt vé thành công!" (bài 16).

Không có lõi mới. Bài này ráp bài 13–16 lên trên code bài 12, theo đúng thứ tự gd4 Bước 1–3. `pay.dart` của bạn đóng
vai PayOS, như `npm run dev:pay` trong guide.

## Chuẩn bị (một lần)

Làm tiếp trên code của chính bạn:

```powershell
cd D:\dev\hoc
Copy-Item bai12 bai17 -Recurse
cd bai17\server
Remove-Item *.txt
Set-Content env.txt "PAYOS_CHECKSUM_KEY=khoa-gia-o-may"
```

- `env.txt` là chỗ để **khoá bí mật**, nằm ngoài code. Khoá ở đây là khoá giả của máy bạn. Dù vậy tập thói quen:
  file này **không** `git add`.
- Chạy và làm lại từ đầu như bài 12. Khác một chỗ: xoá kho thì gõ `Remove-Item events.txt, bookings.txt, buyers.txt`,
  đừng `Remove-Item *.txt` nữa (mất `env.txt`).
- Lệnh phụ ở terminal 3, trong `server\`: `dart run payment_test.dart`, `dart run pay.dart <mã đơn> [số tiền] [khoá]`.
- Hiện trạng trước khi sửa: đặt 2 VIP thì đơn nằm ở `pending`, không có cách nào trả tiền.

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** app: đơn có phí thì mở trang Thanh toán | Đặt 2 VIP → trang "Thanh toán": `Mã đơn: an_…`, `Đang tạo mã...`, `Đang chờ thanh toán`, `Không có đường này` |
| 2 | **Lõi** cổng có bản giả (bài 13) + file thử | `dart run payment_test.dart` → `2/2 ca đúng` |
| 3 | **Lõi** `canPay` (khuôn bài 8) | `7/7 ca đúng` |
| 4 | `POST /createPayosOrder`: chỉ nhận mã đơn, tiền lấy **từ đơn** | Trang hiện `FAKE-PAYOS\|943360617\|1000000` (số giữa mỗi lần một khác); `bookings.txt`: đơn có `payosOrderCode`, `paymentQr` |
| 5a | **Vỏ** app: nút Thanh toán ở Vé của tôi (mở lại trang) | Quay lại, bấm Thanh toán → mã QR **khác** lần trước (`…617` thành `…646`) ← người mua đã quét mã cũ thì sao? |
| 5b | Đơn đã có mã thì trả lại mã cũ | Mở lại bao nhiêu lần cũng một mã |
| 6 | **Lõi** chữ ký (bài 14) | `12/12 ca đúng` |
| 7 | `POST /payosWebhook` + `confirmPaidBooking` bản TẠM; **vỏ** `pay.dart` | `dart run pay.dart <mã đơn>` → `payos: 200 {"success":true,"outcome":"confirmed"}`; ký bằng khoá đoán → `payos: 400 {"error":"Invalid signature"}`. Trang thanh toán **vẫn đứng yên**; quay lại Vé của tôi mới thấy `confirmed` |
| 8 | **Lõi** nghe đơn (bài 16): server giữ kết nối mở, app nghe | Để trang thanh toán đang mở, chạy `pay.dart` → trang **tự đổi** thành `Đặt vé thành công!`, `Đã trả: 1000000đ` |
| 9a | Ba đòn lên bản TẠM | `pay.dart` lần hai → lại `confirmed`; đơn mới, `pay.dart <mã> 1000` → `confirmed` ← trả 1.000đ được vé 500.000đ |
| 9b | **Lõi** `decidePayment` (bài 15) trong transaction | `18/18 ca đúng`. Trả 1000 → `amount-mismatch`, trang vẫn chờ; trả đủ → `confirmed`; lần nữa → `already-confirmed` |

## Từng lượt

### Lượt 1: có chỗ để tới (vỏ)

`app\lib\main.dart`, thêm vào cuối file:

```dart
Future<void> openPayment(BuildContext context, String bookingId) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => PaymentPage(bookingId: bookingId),
    ),
  );
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _qrCode;
  var _message = '';

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  Future<void> _createOrder() async {
    try {
      final result = await call('createPayosOrder', {
        'bookingId': widget.bookingId,
      });
      if (mounted) setState(() => _qrCode = result['qrCode']);
    } on FunctionsException catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mã đơn: ${widget.bookingId}'),
            Text(_qrCode ?? 'Đang tạo mã...'),
            const Text('Đang chờ thanh toán'),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
```

Trong `_submit` của trang chọn vé, giữ kết quả của `createBooking` và mở trang thanh toán khi đơn có phí:

```dart
      final result = await call('createBooking', {
        'bookingIntentId': _bookingIntentId,
        'ticketTypeId': _selected?['id'],
        'quantity': _quantity,
      });
      if (!mounted) return;
      if (result['paymentRequired'] == true) {
        await openPayment(context, result['bookingId']);
      }
      widget.onBooked();
```

- `Navigator.push` đặt một trang mới **đè lên** trang hiện tại; nút mũi tên trên thanh tiêu đề gỡ nó ra. `await` ở đây
  đợi tới lúc trang thanh toán bị đóng.
- Trang chỉ nhận **mã đơn**. Mọi thứ khác nó tự hỏi server theo mã đó. EH đang truyền nguyên object đơn qua `extra`
  của router, F5 là mất; gd4 đổi sang đường dẫn `/booking/:bookingId/payment`.
- App **không gửi số tiền**. Trang này còn không biết đơn bao nhiêu tiền.
- Mã QR trong bài hiện dưới dạng chữ. App thật vẽ chuỗi đó thành hình QR.

### Lượt 2: cổng có bản giả (lõi bài 13)

`server\gateway.dart`, tự viết như bài 13, khác hai chỗ:
- `createLink(orderCode, amount)` trả `Future<String>` (gọi mạng thì phải đợi), nên bản giả là hàm `async`.
- `PayosGateway.createLink` chỉ có một dòng `throw UnsupportedError('Bài này không gọi PayOS thật.');`.

Chỗ chọn cổng:

```dart
// TẠM: this server only ever runs on your machine.
const isEmulator = true;

PaymentGateway paymentGateway() {
  return isEmulator ? FakeGateway() : PayosGateway();
}
```

`server\payment_test.dart`: chép hàm `check` từ `booking_test.dart`; `main` là `async` vì phải `await` cổng. Hai ca:
bản giả với mã 7, tiền 300000 trả `FAKE-PAYOS|7|300000`; `paymentGateway() is FakeGateway` là `true`.

### Lượt 3: `canPay`

`server\payment.dart`: hàm thuần `String? canPay(booking, uid, now)`, cùng khuôn `canCancel`:

| Kiểm | Mã |
|---|---|
| Không có đơn | `booking-not-found` |
| Không phải chủ đơn | `not-owner` |
| `status` khác `pending` **hoặc** `paymentStatus` khác `awaiting` | `not-pending` |
| Đã qua 5 phút kể từ `createdAt` của đơn | `payment-expired` |

Vỏ, cùng file (cách sinh mã đơn PayOS của code cũ trong EH, số tối đa 9 chữ số, đổi mỗi 0,1 giây):

```dart
// PayOS: positive integer, at most 9 digits.
int newOrderCode(int nowMs) {
  return (nowMs ~/ 100) % 999999999 + 1;
}
```

Thêm 5 ca thử. Đơn mẫu: của `an`, `pending`, `awaiting`, `createdAt` là `'2030-01-01T10:00:00'`. Hai mốc giờ: 10:04
(còn hạn) và 10:05 (đúng phút thứ 5 là **hết hạn**).

### Lượt 4: `createPayosOrder`

Vỏ, `main.dart` (thêm import `gateway.dart`, `payment.dart`), trên hàm `route`:

```dart
Future<Map<String, dynamic>> createPayosOrder(
  String uid,
  Map<String, dynamic> input,
) async {
  if (input['bookingId'] is! String) {
    throw HttpsError(
      400,
      'invalid-argument',
      'Dữ liệu thanh toán không hợp lệ.',
    );
  }
  final bookingPath = 'bookings/${input['bookingId']}';
  // lõi
}
```

và trong `route`, dưới cái khoá:

```dart
  if (route == 'POST /createPayosOrder') {
    return send(req, 200, await createPayosOrder(uid, body));
  }
```

Lõi, theo đúng thứ tự:
1. Đọc đơn (`readDoc`), hỏi `canPay`. Không được thì `throw HttpsError(400, mã, câu)`; câu là
   `Đơn đã hết thời gian thanh toán.` khi mã là `payment-expired`, còn lại `Đơn này không thanh toán được.`
2. Sinh `orderCode`, gọi `paymentGateway().createLink(orderCode, <tiền của đơn>)`.
3. Một transaction: đọc lại đơn, ghi thêm hai field `payosOrderCode` (dạng chữ) và `paymentQr`, trả `{'qrCode': ...}`.

Bước 2 nằm **ngoài** transaction: transaction có thể chạy lại (bài 12 lượt 8b), gọi cổng trong đó là tạo hai link.

**Thử phá ngay:** trong `_createOrder` của app gửi kèm `'amount': 1000`. QR vẫn mang `1000000`. Xoá đi.

### Lượt 5a: mở lại trang thanh toán (vỏ)

`_MyBookingsPageState`: thay cả khối `trailing: ...` bằng `trailing: _action(booking),` và thêm hai hàm:

```dart
  Future<void> _pay(String bookingId) async {
    await openPayment(context, bookingId);
    await _load();
  }

  Widget? _action(Map<String, dynamic> booking) {
    if (booking['status'] == 'confirmed') {
      return TextButton(
        onPressed: () => _cancel(booking['id']),
        child: const Text('Hủy đặt vé'),
      );
    }
    if (booking['status'] == 'pending') {
      return TextButton(
        onPressed: () => _pay(booking['id']),
        child: const Text('Thanh toán'),
      );
    }
    return null;
  }
```

Đặt 2 VIP, nhớ số ở giữa mã QR, bấm mũi tên quay lại, bấm Thanh toán: số đã đổi. Người mua có thể đã quét hoặc lưu
ảnh mã cũ: giờ có **hai** mã cùng chờ tiền cho một đơn, và đơn chỉ còn nhớ mã mới.

### Lượt 5b: trả lại mã cũ

Lõi, `createPayosOrder`: đơn đã có `paymentQr` thì trả luôn mã đó. Kiểm ở **hai** chỗ: ngay sau `canPay` (khỏi gọi
cổng thừa), và trong transaction trước khi ghi (hai lời gọi cùng lúc: lời gọi sau nhận mã của lời gọi trước).

### Lượt 6: chữ ký (lõi bài 14)

`server\signature.dart`, tự viết như bài 14, tên theo guide:
- `toyHash(text)`.
- `payosSignature(data, checksumKey)`: xếp tên field, nối `tên=giá trị` bằng `&`, thêm `|` và khoá, băm, trả **chữ**
  (`.toRadixString(16)`).
- `isSignedByPayos(body, checksumKey)`: `body` có hai phần `data` và `signature`. Khoá rỗng → `false`. `data` không
  phải Map hoặc `signature` không phải chữ → `false`. Còn lại: tự ký `data` rồi so.

Kiểm kiểu trước khi dùng (dữ liệu khác bài):

```dart
final Object? x = 'abc';
if (x is! String) return;
print(x.length); // sau dòng `is!`, Dart biết x là String
```

Thêm 5 ca thử, khoá `khoa-thu`, tin `{'orderCode': 7, 'amount': 300000, 'code': '00'}`: tin ký đúng khoá (`true`); sửa
`amount` sau khi ký; sai khoá; khoá rỗng; thiếu `signature` (bốn ca sau đều `false`).

### Lượt 7: webhook, và `pay.dart` đóng vai PayOS

Vỏ, `server\env.dart`:

```dart
import 'dart:io';

// Reads PAYOS_CHECKSUM_KEY=... from env.txt. Never in code, never in git.
String checksumKey() {
  const prefix = 'PAYOS_CHECKSUM_KEY=';
  final file = File('env.txt');
  if (!file.existsSync()) return '';
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith(prefix)) return line.substring(prefix.length).trim();
  }
  return '';
}
```

Vỏ, `server\pay.dart`:

```dart
import 'client.dart';
import 'db.dart';
import 'env.dart';
import 'signature.dart';

// Plays PayOS saying "money arrived", through the real webhook.
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Dùng: dart run pay.dart <mã đơn> [số tiền] [khoá]');
    return;
  }
  final booking = readDoc('bookings/${args[0]}');
  if (booking == null || booking['payosOrderCode'] == null) {
    print('Đơn chưa có mã PayOS: mở trang thanh toán của đơn trước.');
    return;
  }
  final data = {
    'orderCode': int.parse(booking['payosOrderCode']),
    'amount': args.length > 1 ? int.parse(args[1]) : booking['totalAmount'],
    'code': '00',
  };
  final key = args.length > 2 ? args[2] : checksumKey();
  final body = {'data': data, 'signature': payosSignature(data, key)};
  print(await call('payos', '/payosWebhook', body));
}
```

`pay.dart` không sửa đơn. Nó chỉ **gửi một tin có chữ ký** tới đúng webhook mà PayOS thật sẽ gọi. Không có lối tắt
riêng cho lúc dev.

Vỏ, `main.dart` (thêm import `env.dart`, `signature.dart`), trong `route`, **trên** cái khoá:

```dart
  // PayOS is not a signed-in user: this route sits above the lock.
  if (route == 'POST /payosWebhook') {
    // lõi: chữ ký sai thì 400
    final Map<String, dynamic> data = body['data'];
    // "00": paid. Other codes are notices.
    if (data['code'] != '00') {
      return send(req, 200, {'success': true});
    }
    final outcome = await confirmPaidBooking(
      '${data['orderCode']}',
      data['amount'],
    );
    // PayOS resends until it gets a 2xx: every handled call answers 200.
    return send(req, 200, {'success': true, 'outcome': outcome});
  }
```

Lõi:
- Dòng đầu của nhánh webhook: `isSignedByPayos(body, checksumKey())` sai thì in `webhook: chữ ký sai` và
  `send(req, 400, {'error': 'Invalid signature'})`.
- `confirmPaidBooking(orderCode, paidAmount)` **bản TẠM** (ghi `// TẠM — lượt 9b`): tìm trong `bookings` đơn có
  `payosOrderCode` bằng `orderCode`; không có thì trả `'not-found'`; có thì `writeDoc` đơn với `status` và
  `paymentStatus` thành `confirmed`, thêm `confirmedAt` và `qrData` (`'VE|<mã đơn>'`, vé chỉ phát khi tiền đã về),
  trả `'confirmed'`. Cố ý chưa nhìn số tiền, chưa nhìn trạng thái.

Thử lần lượt (mã đơn chép từ trang thanh toán):

```powershell
dart run pay.dart an_xxxxxxxx 1000000 doan-mo
dart run pay.dart an_xxxxxxxx
```

Lệnh đầu là kẻ lạ ký bằng khoá đoán: `400`. Lệnh sau: `confirmed`. Nhưng trang thanh toán đang mở **không nhúc
nhích**.

**Thử phá:** đổi tên `env.txt` thành `env.off`, chạy lại lệnh đầu với khoá rỗng (`... 1000000 ""`): vẫn `400`. Server
quên cấu hình khoá thì **đóng cửa**, không mở toang (bài 14 thử phá 2). Đổi tên lại.

### Lượt 8: trang nghe đơn (lõi bài 16)

Vỏ, `db.dart`, trên hàm `writeDoc`:

```dart
// Who is listening to a doc: path -> open responses.
final watchers = <String, List<HttpResponse>>{};

// One line of JSON: the doc as it is right now.
void sendDoc(HttpResponse res, String path) {
  res.write('${jsonEncode(readDoc(path))}\n');
}
```

Vỏ, `main.dart`, dưới cái khoá:

```dart
  // Like snapshots(): the response stays open, one line per version.
  if (req.method == 'GET' && req.uri.path.startsWith('/watch/')) {
    final path = req.uri.path.substring('/watch/'.length);
    if (readDoc(path)?['userId'] != uid) {
      throw HttpsError(403, 'permission-denied', 'Không phải đơn của bạn.');
    }
    print('GET ${req.uri.path} -> đang nghe');
    final res = req.response;
    res.headers.contentType = ContentType.json;
    res.bufferOutput = false;
    // lõi
    res.done.whenComplete(() {
      watchers[path]!.remove(res);
      print('thôi nghe $path');
    });
    return;
  }
```

Mọi đường khác trả lời xong là **đóng** (`..close()` trong `send`). Đường này **không đóng**: server giữ `res` lại để
ghi tiếp mỗi khi doc đổi.

Lõi server (bài 16 lượt 4 và 5):
- Ở chỗ `// lõi`: thêm `res` vào danh sách người nghe của `path`, **và** gửi ngay bản hiện tại (`sendDoc`).
- Cuối `writeDoc`: gửi bản mới cho mọi `res` đang nghe đường dẫn đó.

```dart
final nhom = <String, List<String>>{};
nhom.putIfAbsent('a', () => []).add('Chi'); // chưa có danh sách 'a' thì tạo rồi mới thêm
for (final ten in nhom['b'] ?? <String>[]) {
  print(ten); // 'b' chưa có: lặp qua danh sách rỗng, không lỗi
}
```

Vỏ, `app\lib\api.dart`, cuối file:

```dart
// Like snapshots(): the doc now, then again every time it changes.
Stream<Map<String, dynamic>> watchDoc(String path) async* {
  final client = http.Client();
  try {
    final req = http.Request('GET', _url('/watch/$path'));
    req.headers.addAll(_headers());
    final res = await client.send(req);
    final lines = res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      yield jsonDecode(line);
    }
  } finally {
    client.close();
  }
}
```

`async*` là hàm trả về một **Stream**; mỗi `yield` là một lần `add` của bài 5.

Lõi app, `_PaymentPageState` (đầu file thêm `import 'dart:async';`):
- Hai field: `Map<String, dynamic>? _booking;` và `StreamSubscription<Map<String, dynamic>>? _subscription;`
- Trong `initState`: `listen` vào `watchDoc('bookings/${widget.bookingId}')`, mỗi bản tới thì `setState` giữ vào
  `_booking`. Giữ kết quả của `listen` vào `_subscription`.
- `dispose()`: `_subscription?.cancel();` rồi `super.dispose();` (bài 16 thử phá 1).
- Trong `build`: `_booking?['status'] == 'confirmed'` thì hiện `Đặt vé thành công!` và `Đã trả: <tổng tiền>đ`; không
  thì hiện bốn dòng cũ. Trong một danh sách widget viết được `if (dk) ...[A, B] else ...[C, D]`.

Mở trang thanh toán, terminal 1 có `GET /watch/bookings/an_… -> đang nghe`. Chạy `pay.dart`: trang tự đổi. Không ai
bấm gì, không ai "báo" app: webhook ghi doc, `writeDoc` đẩy bản mới xuống kết nối đang mở.

Đóng trang thanh toán rồi chạy `pay.dart` lần nữa: terminal 1 in `thôi nghe bookings/an_…`. Server chỉ biết người
nghe đã đi khi nó **thử ghi** cho người đó.

### Lượt 9a: ba đòn lên bản TẠM

Không viết gì. Thử:
1. `dart run pay.dart <mã đơn>` lên đơn đã trả ở lượt 8: lại `confirmed`. Mở `bookings.txt`: `confirmedAt` đã đổi.
2. Đặt đơn VIP mới, mở trang thanh toán, `dart run pay.dart <mã đơn mới> 1000`: `confirmed`, trang sang "thành công".

### Lượt 9b: `decidePayment` trong transaction (lõi bài 15)

Lõi:
- `payment.dart`: hàm thuần `decidePayment(booking, paidAmount)` trả một trong bốn mã, **trạng thái trước, tiền
  sau**: `already-confirmed` (cả `status` lẫn `paymentStatus` là `confirmed`), `not-pending` (không còn
  `pending`/`awaiting`), `amount-mismatch`, `confirm`.
- 6 ca thử: đang chờ đủ tiền; PayOS gọi lại; gọi lại với số tiền khác (vẫn `already-confirmed`); trả thiếu 299000;
  trả thừa 300001; đơn `cancelled`/`expired`.
- `confirmPaidBooking`: bỏ dòng TẠM, cho cả việc tìm, đọc, quyết, ghi vào **một** `runTransaction`. `runTransaction`
  trả Map, nên trong đó trả `{'outcome': ...}` rồi lấy ra sau. Quyết định khác `confirm` thì trả luôn mã đó,
  **không ghi gì**.
- Sau transaction: kết quả là `amount-mismatch` hoặc `not-pending` thì in một dòng `LỖI: tiền về không khớp đơn đang
  chờ (<mã PayOS>, <số tiền>)`. Đó là tiền thật của khách, phải có người hoàn lại. Webhook vẫn trả `200`: PayOS gửi
  lại cũng không đổi được gì.

Thử lại hai đòn của 9a, và thêm một đòn: hai cửa sổ terminal cùng chạy `dart run pay.dart <mã đơn mới>` gần như cùng
lúc. Một bên `confirmed`, bên kia `already-confirmed`.

## Vướng

- Mọi `pay.dart` đều `400`: thiếu `env.txt` trong `server\`, hoặc server chạy từ thư mục khác.
- `Đơn chưa có mã PayOS`: đơn đó chưa mở trang thanh toán lần nào.
- Trang thanh toán báo `Đơn này không thanh toán được.`: đơn không còn `pending` (đã trả, hoặc là vé mời).
- Trang không tự đổi ở lượt 8: quên dòng báo trong `writeDoc`, hoặc `confirmPaidBooking` ghi bằng đường khác
  `writeDoc`.

## Vỏ đã cắt (đồ thật có, bài này không)

- Hết 5 phút thì đơn tự hủy và trả vé về kho (job `expireBookings`), trang có đồng hồ đếm ngược. Ở đây quá 5 phút
  chỉ là không tạo được mã mới.
- Hủy đơn **đã trả tiền** ở đây vẫn bấm được và không ai hoàn tiền. EH có luồng xin hoàn tiền, admin duyệt.
- Đơn rời `pending` thì phải hủy link PayOS (cổng có thêm `cancelLink`), để ảnh QR đã lưu hết dùng được.
- Tin của PayOS có 16 field, mã QR là chuỗi theo chuẩn ngân hàng, vé là một chuỗi JSON.
- Nghe doc ở đây là một dòng JSON trên một kết nối HTTP giữ mở. Firestore dùng kênh riêng, tự nối lại khi rớt mạng,
  chỉ gửi phần thay đổi.
- Trang Vé của tôi vẫn tải lại bằng tay; EH nghe cả danh sách.

## Bắc cầu sang project

| Bài 17 | gd4 / EH |
|---|---|
| `openPayment(context, bookingId)` | Đường dẫn `/booking/:bookingId/payment` (patch `gd04_flutter_sau_server.patch`) |
| App chỉ gửi `bookingId` | Hiện tại `booking_payment_bloc.dart` dòng 120–124 gửi cả `amount`, `description`; patch gd4 bỏ |
| `gateway.dart` | Chặng 1.1, `gateway.ts` |
| `canPay`, `newOrderCode` | Chặng 1.2, `payPolicy.ts` (`PAYMENT_HOLD_MS`) |
| `createPayosOrder`: `canPay` → trả mã cũ → cổng (ngoài transaction) → transaction ghi nếu chưa có | Chặng 1.3, `createPayosOrder.ts`, cùng thứ tự. Bản cũ: `functions/payos/createPayosOrder.js` |
| Thử phá gửi `amount: 1000` | Chặng 1.4, test "tiền lấy từ đơn" |
| `signature.dart` | Chặng 2.1, `signature.ts` |
| `env.txt`, `checksumKey()` | `functions/.env.local` (giá trị giả), `emulatorChecksumKey()` trong `dev/fakePayos.ts` |
| `pay.dart` | Chặng 2.4, `dev/pay.ts`: `npm run dev:pay -- <mã đơn> [số tiền]` |
| Nhánh `POST /payosWebhook` | Chặng 2.2, `payosWebhook.ts` (`onRequest`, không phải `onCall`: PayOS không phải app của mình) |
| `confirmPaidBooking` bản TẠM | Chặng 2.2, cũng có dòng `TẠM — Bước 3` |
| Lượt 9a | Chặng 3.1: ba test viết trước, **đỏ** trên bản TẠM |
| `decidePayment` | Chặng 3.2, `decidePayment.ts` |
| `confirmPaidBooking` trong transaction + dòng `LỖI` | Chặng 3.3: `tx.get(byOrderCode)`, `logger.error("PayOS money not matched to a pending booking.")` |
| `watchers`, `sendDoc`, dòng báo trong `writeDoc` | **Không có dòng nào.** Firestore tự đẩy doc mới xuống mọi `snapshots()` đang mở |
| `watchDoc(...).listen` + `cancel` trong `dispose` | `booking_payment_bloc.dart` dòng 218–232 và 47–58 |
| Trang tự sang "thành công" | `booking_payment_page_web.dart` dòng 26: `BlocListener<BookingPaymentBloc, BookingPaymentState>` |

Hai hàng "làm hộ" của bài này: Firebase kiểm token cho callable nhưng **không** kiểm gì cho webhook (bạn tự kiểm chữ
ký), và Firestore tự đẩy doc mới (bạn chỉ `listen`).

## Git

`git add bai17/bai17.md bai17/server/*.dart bai17/app`. **Không** add `bai17/server/env.txt` và các file `.txt` dữ liệu.

## Xong khi

- [ ] Đi trọn vòng: đặt 2 VIP → trang thanh toán có mã QR → `pay.dart` → trang tự sang "Đặt vé thành công!" → quay lại,
  Vé của tôi `confirmed`
- [ ] `payment_test.dart` ra `18/18 ca đúng`
- [ ] Đã thấy 3 cái hỏng: 5a (hai mã cho một đơn), 7 (trang đứng yên), 9a (trả 1.000đ được vé)
- [ ] Đã làm thử phá ở lượt 4 và lượt 7
- [ ] Nhìn bảng bắc cầu, chỉ ra được dòng code của mình ứng với từng hàng
- [ ] Trả lời được: "Walk me through your payment flow, from the Pay button to the ticket" và "What can go wrong
  between the payment provider and your server?"
