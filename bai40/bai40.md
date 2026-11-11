# Bài 40 (thí nghiệm Flutter): nói chuyện với phía native

**Lõi một câu:** Dart không tự đọc được clipboard, pin, camera: đó là việc của code **native** (Kotlin, Swift, C++).
Hai bên nói chuyện qua **platform channel**: một kênh **có tên**, Dart gửi vào đó "**tên hàm + tham số**", phía native
đang nghe kênh đó làm việc rồi **gửi trả** kết quả. Lời gọi luôn là `Future`, vì bên kia là một thế giới khác. Mọi
plugin (kể cả Firebase) là cái vỏ Dart bọc quanh vài lời gọi như vậy.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai40
flutter create --empty --platforms=windows app
cd app
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R`. Bài này phải **chạy app thật**: trong `flutter test` không có phía native
để trả lời.

Bài không viết code native. Nó dùng một kênh Flutter **có sẵn** (`flutter/platform`, kênh của clipboard) để bạn thấy
bên dưới một API quen thuộc là gì.

## Đề

Ba nút. Xong khi bấm lần lượt, terminal in:

```
Clipboard.hasStrings(): true
kênh flutter/platform trả: {value: true}
MissingPluginException: No implementation found for method getLevel on channel eh/battery
```

(`true` khi clipboard của máy đang có chữ; chưa copy gì thì `false`. Bài chỉ **hỏi**, không ghi gì vào clipboard.)

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Vỏ bên dưới. Nút **Hỏi bằng API**: gọi `Clipboard.hasStrings()` của Flutter, in kết quả | `Clipboard.hasStrings(): true` |
| 2 | Nút **Hỏi thẳng kênh**: tự mở kênh `flutter/platform`, tự gửi tên hàm `Clipboard.hasStrings` | `kênh flutter/platform trả: {value: true}` ← cùng câu trả lời, ở dạng thô |
| 3 | Nút **Kênh lạ**: mở kênh `eh/battery` (không ai nghe), gọi `getLevel`, bắt `MissingPluginException` | `MissingPluginException: No implementation found for method getLevel on channel eh/battery` |

Lượt 1 và 2 là **cùng một việc**. `Clipboard.hasStrings()` là vài dòng Dart: mở kênh, gửi đúng chuỗi
`'Clipboard.hasStrings'`, nhận về `{value: true}`, lấy `value` ra. Phần làm thật (hỏi Windows "clipboard có chữ
không") là C++ nằm trong engine của Flutter.

Lượt 3 là chuyện xảy ra khi Dart gọi mà phía native **không có ai đăng ký nghe** kênh đó.

## Từng lượt

### Lượt 1 (vỏ)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: ChannelPage())));
}

class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key});

  Future<void> _viaApi() async {
    final has = await Clipboard.hasStrings();
    debugPrint('Clipboard.hasStrings(): $has');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(onPressed: _viaApi, child: const Text('Hỏi bằng API')),
      ],
    );
  }
}
```

### Lượt 2: tự mở kênh

Ví dụ với một kênh và hàm khác:

```dart
const channel = MethodChannel('vi_du/loa', JSONMethodCodec());
final reply = await channel.invokeMethod('keu', 'xin chào');
```

- `MethodChannel('tên kênh', codec)`: tên kênh là một chuỗi hai bên **thoả thuận trước**; gõ sai một ký tự là bên kia
  không nghe thấy.
- `JSONMethodCodec()`: cách **đóng gói** tin nhắn thành byte. Kênh `flutter/platform` dùng JSON; kênh của plugin
  thường dùng codec mặc định (bỏ tham số thứ hai).
- `invokeMethod('tên hàm', tham số)`: gửi đi, trả về một `Future`.

Bài mình: kênh `flutter/platform`, hàm `Clipboard.hasStrings`, tham số `'text/plain'`.

### Lượt 3: bắt lỗi theo loại

```dart
try {
  ...
} on FormatException catch (e) {
  print('sai định dạng: ${e.message}');
}
```

`on <Loại> catch (e)` chỉ bắt đúng loại lỗi đó (bài 12 lượt 7 đã dùng `on FunctionsException`). Kênh `eh/battery`
không cần codec JSON: `const MethodChannel('eh/battery')`.

## Thử phá

1. Ở lượt 2, gõ sai tên hàm: `'Clipboard.hasString'` (thiếu chữ s). Kênh thì có người nghe, nhưng hàm thì không ai
   biết: cũng ném `MissingPluginException(No implementation found for method Clipboard.hasString on channel
   flutter/platform)`. Tên kênh và tên hàm chỉ là **chuỗi**: compiler không kiểm được, sai là tới lúc chạy mới biết. Đây là
   lý do người ta bọc kênh trong một API có kiểu (lượt 1), và plugin lớn dùng công cụ sinh code (Pigeon) để hai bên
   khỏi gõ tay các chuỗi này.
2. Ở lượt 3, bỏ `try/catch`. Bấm nút: app không chết, nhưng terminal in một khối lỗi đỏ "Unhandled Exception"
   (bài 25 lượt 2).

## Bắc cầu sang project

| Bài 40 | EH |
|---|---|
| API Dart bọc quanh kênh | Mọi plugin trong `app/pubspec.yaml`: `firebase_auth`, `cloud_firestore`, `firebase_database`, `cloud_functions`, `shared_preferences`, `connectivity_plus`… |
| `invokeMethod` trả `Future` | Lý do mọi lời gọi Firebase đều `await`: `signInWithEmailAndPassword(...)`, `ref.onDisconnect().remove()` |
| `MissingPluginException` | Lỗi `FirebasePlugin not found` bạn từng gặp ở repo mẫu: phần Dart của plugin gọi, phần native **không khớp bản** nên không đăng ký. Sửa bằng ghim version, không phải bằng sửa code |
| Phía native phải được nạp lúc **build** | Thêm một plugin mới mà chỉ bấm `r` hay `R` là dính đúng `MissingPluginException`: phải dừng hẳn rồi `flutter run` lại (bài 39, hàng cuối bảng) |
| Stream từ native | `EventChannel`: native **đẩy** nhiều tin sang Dart. `firebaseAuth.userChanges()`, `ref.onValue`, `snapshots()` đi đường này (bài 5, 16) |
| Trên web | Không có kênh nào: plugin gọi thẳng thư viện JavaScript. Một plugin "chạy được trên Android" không có nghĩa chạy được trên web |

- **Lõi:** tên kênh + tên hàm + tham số → gửi → `Future` trả lời.
- **Vỏ / framework làm hộ:** đóng gói thành byte (codec), chuyển giữa hai luồng, và toàn bộ phía native.
- **Khi nào tự viết kênh:** khi cần một thứ của máy mà chưa plugin nào có (một SDK thanh toán nội địa, một cảm biến
  lạ). Lúc đó bạn viết phía Dart như lượt 2–3, và phía Kotlin/Swift đăng ký nghe đúng tên kênh đó. EH không có chỗ
  nào phải làm vậy.
- **Trong test** (bài 41) không có phía native, nên code gọi kênh phải nằm sau một cổng có bản giả (bài 13): đó là
  thêm một lý do cho tầng repository.

## Xong khi

- [ ] Terminal in đủ 3 dòng như đề
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do platform channels work?"
