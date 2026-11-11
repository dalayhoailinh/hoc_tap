# Bài 41 (thí nghiệm Flutter): thử một màn hình mà không mở app

**Lõi một câu:** widget test dựng widget **trong bộ nhớ** (không cửa sổ, không thiết bị), rồi làm đúng ba việc người
dùng làm: **tìm** một thứ trên màn (`find`), **bấm** nó (`tap`), cho Flutter **vẽ khung hình kế** (`pump`), rồi kiểm
thứ đang hiện (`expect`). Quên `pump` là kiểm màn hình **cũ**.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai41
flutter create --empty --platforms=windows app
cd app
```

Bài này **không** `flutter run`. Lệnh duy nhất: `flutter test`.

Hai file: `lib/main.dart` (vỏ bên dưới, gõ một lần) và `test/quantity_test.dart` (bạn viết). Nếu có sẵn
`test/widget_test.dart` thì xoá.

## Đề

Màn chọn số vé: bắt đầu 1 vé, nút `+` cộng 1, **tối đa 10**, bên dưới hiện tổng tiền (500000 đồng một vé).

Xong khi `flutter test` in:

```
00:00 +0: mở trang thấy 1 vé
00:01 +1: bấm cộng thì thành 2 vé
00:01 +2: tối đa 10 vé
00:02 +3: All tests passed!
```

(Cột giờ bên trái mỗi máy một khác.)

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Vỏ `lib/main.dart`. Test đầu: dựng trang, mong thấy `Số vé: 1` và `Tổng: 500000 đồng` | `+1: All tests passed!` |
| 2a | Test hai: dựng trang, bấm nút `+`, mong thấy `Số vé: 2` | **Đỏ:** `Expected: exactly one matching candidate` / `Actual: _TextWidgetFinder:<Found 0 widgets with text "Số vé: 2": []>` |
| 2b | Thêm `await tester.pump();` sau lệnh bấm | `+2: All tests passed!` |
| 3 | Test ba: bấm `+` **15 lần**, mong `Số vé: 10` và `Tổng: 5000000 đồng` | `+3: All tests passed!` |

Lượt 2a: nút **đã** được bấm, `setState` **đã** chạy, `_quantity` **đã** là 2. Nhưng `setState` chỉ đánh dấu (bài 32
lượt 2), và trong test **không có ai tự vẽ khung hình kế**. Bạn phải bảo: `pump`.

## Từng lượt

### Vỏ: `lib/main.dart`

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: QuantityPage()));

class QuantityPage extends StatefulWidget {
  const QuantityPage({super.key});

  @override
  State<QuantityPage> createState() => _QuantityPageState();
}

class _QuantityPageState extends State<QuantityPage> {
  var _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Số vé: $_quantity'),
          IconButton(
            onPressed: _quantity >= 10
                ? null
                : () => setState(() => _quantity++),
            icon: const Icon(Icons.add),
          ),
          Text('Tổng: ${_quantity * 500000} đồng'),
        ],
      ),
    );
  }
}
```

### Lượt 1: khung một file test

Ví dụ dùng widget khác bài:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hiện lời chào', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Xin chào')));

    expect(find.text('Xin chào'), findsOneWidget);
    expect(find.text('Tạm biệt'), findsNothing);
  });
}
```

- `testWidgets('tên', (tester) async { ... })`: một ca. `tester` là "người dùng giả".
- `tester.pumpWidget(...)`: dựng widget và vẽ khung hình đầu. Bọc `MaterialApp` vì `Text`, `Scaffold` cần nó ở phía
  trên (bài 33).
- `find.text('…')`: **cách tìm**, chưa tìm ngay. `expect(cách tìm, findsOneWidget)`: "phải có đúng một".
- Để dùng `QuantityPage` trong test: `import 'package:app/main.dart';`

### Lượt 2: bấm

```dart
await tester.tap(find.byIcon(Icons.close));
await tester.pump();
```

`find.byIcon(...)` tìm theo biểu tượng. `tap` giả một cú chạm vào giữa widget tìm được.

### Lượt 3: lặp

```dart
for (var i = 0; i < 3; i++) {
  // mỗi vòng: tap rồi pump
}
```

Phải `pump` **trong** vòng lặp: mỗi cú bấm cần màn hình của cú trước đã vẽ xong (nút có còn bấm được không là do lần
vẽ đó quyết).

## Thử phá

1. Trong `lib/main.dart`, đổi `>= 10` thành `>= 100`. `flutter test`: ca nào đỏ, câu báo là gì? Bạn vừa lỡ tay bỏ
   một luật nghiệp vụ và test bắt được trong 2 giây, không cần mở app bấm 11 lần. Trả lại.
2. Trong test ba, bỏ dòng `pump` trong vòng lặp, chỉ `pump` một lần sau vòng. **Đỏ:** không tìm thấy `Số vé: 10`. Cả
   15 cú bấm đều rơi vào cái nút của **lần vẽ đầu** (lúc đó còn bật), nên số lên 16. Nút chỉ tắt khi màn hình được vẽ
   lại với `_quantity` là 10. Người dùng thật không bấm nhanh hơn một khung hình được, test thì có. Trả lại.

## Bắc cầu sang project

Ba tầng test, từ rẻ tới đắt. EH có đủ cả ba:

| Tầng | Thử cái gì | Cần dựng gì | Ví dụ trong EH | Bài của bạn |
|---|---|---|---|---|
| **Unit** | Một hàm thuần, một cubit | Không gì | `functions/src/auth/signUp.test.ts`; `app/test/core/routes/route_policy_test.dart`; `app/test/features/auth/presentation/login_cubit_test.dart` | Bài 8, 30 |
| **Widget** | Một màn hình: bố cục, bấm, chữ hiện ra | Cây widget trong bộ nhớ | `app/test/core/widgets/page_title_bar_test.dart`; `app/test/features/shell/web_page_frames_test.dart` | Bài này |
| **Integration** | Nhiều phần thật nối với nhau: function + database + rules | Emulator | `functions/integration/auth.integration.test.ts` (gọi callable qua HTTP thật); `rules-tests/` (rules trên Firestore emulator) | Bài 12: `tranh.dart`, `kexau.dart` |

- **Chạy:** `cd app` → `flutter test` (unit + widget của Flutter); `cd functions` → `npm test` (unit server) và
  `npm run test:emulator` (integration); `npm --prefix rules-tests run test:emulator` (rules).
- **Mở `page_title_bar_test.dart` dòng 73–98:** ngoài `find` và `expect`, nó còn đổi **cỡ màn hình** (rộng 1024, hẹp
  390) và đo vị trí (`tester.getRect(actions).right`), và dòng 78 `expect(tester.takeException(), isNull)`: "không có
  lỗi tràn nào" (bài 35). Widget test bắt được cả lỗi bố cục.
- **Vì sao không viết tất cả là integration cho chắc:** integration thật nhất nhưng chậm (emulator khởi động hàng
  chục giây), dễ hỏng vì lý do không liên quan, và khi đỏ thì khó biết đỏ ở đâu. Luật thường dùng: logic (tiền, hủy,
  quyền) thử ở tầng **unit** thật kỹ; mỗi màn quan trọng vài **widget** test; mỗi luồng chính một hai **integration**
  test để chắc các mảnh ráp vừa.
- **Mock Firebase trong widget test:** widget lấy dữ liệu từ bloc, bloc lấy từ repository; test đưa repository giả
  vào (bài 13, 30). Không có dòng Firebase nào chạy.
- **`pump` và họ hàng:** `pump()` vẽ một khung; `pump(Duration)` tua giờ giả rồi vẽ (bài 4: giờ giả tua được);
  `pumpAndSettle()` vẽ tới khi hết hoạt ảnh. Trong test không có đồng hồ thật, nên test có timer vẫn chạy trong vài
  mili-giây.

## Xong khi

- [ ] `flutter test` ra `+3: All tests passed!`
- [ ] Đã thấy lượt 2a đỏ vì thiếu `pump`
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Unit vs widget vs integration test, with examples from
  your project"
