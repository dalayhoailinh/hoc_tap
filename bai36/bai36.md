# Bài 36 (thí nghiệm Flutter): vẽ lại thừa

**Lõi một câu:** `setState` (hay một state mới của bloc) làm chạy lại `build` của **cả nhánh** bên dưới nó, kể cả
những widget không dùng tới thứ vừa đổi. Tìm ra bằng cách **đếm `build`**. Sửa bằng cách thu nhỏ vùng bị vẽ lại:
đánh `const` cho phần không đổi, tách phần hay đổi ra widget riêng, hoặc lọc bằng `buildWhen`.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai36
flutter create --empty --platforms=windows app
cd app
flutter pub add flutter_bloc
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R`.

## Đề

Trang thanh toán có hai phần: **đồng hồ đếm ngược** (đổi mỗi giây; trong bài bấm nút **Tích tắc** thay cho một giây
trôi qua) và **mã QR** (không đổi suốt 5 phút, và coi như vẽ rất **nặng**).

Mỗi `build` in một dòng. Xong khi bấm Tích tắc mà **không** thấy dòng `build: QrCode (nặng)`.

## Các lượt

| Lượt | Viết thêm | Chạy thấy khi bấm Tích tắc |
|---|---|---|
| 1 | **Vỏ** bên dưới: tất cả chung một State | `build: PaymentPage`, `build: QrCode (nặng)` ← **mỗi giây vẽ lại mã QR một lần** |
| 2 | Cho `QrCode` một constructor `const`, và gọi nó bằng `const QrCode()` | Chỉ còn `build: PaymentPage` |
| 3 | Mã QR cần tham số lúc chạy mới biết (`QrCode(text: qrText)`) nên hết `const` được. **Tách** đồng hồ + nút ra widget `Countdown` có State riêng; `PaymentPage` thành `StatelessWidget` | Chỉ còn `build: Countdown`. Cả `PaymentPage` lẫn `QrCode` đứng yên |
| 4a | Bản Bloc (**vỏ** bên dưới): một cubit giữ cả giây lẫn mã QR, hai `BlocBuilder` | `build: đồng hồ`, `build: QrCode (nặng)` ← lỗi lượt 1 quay lại dưới hình khác |
| 4b | Thêm `buildWhen` cho `BlocBuilder` của mã QR: chỉ vẽ khi **mã QR** đổi | Chỉ còn `build: đồng hồ` |

Lượt 1: `QrCode` không dùng `_seconds`, nhưng nó nằm trong `build` của `PaymentPage`, mà `PaymentPage` vừa `setState`.
Mỗi lần đó, dòng `QrCode()` tạo một object widget **mới**, Flutter không biết nó có khác cái cũ không, nên gọi
`build` của nó cho chắc.

## Từng lượt

### Lượt 1 (vỏ)

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: PaymentPage())));

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  var _seconds = 300;

  @override
  Widget build(BuildContext context) {
    debugPrint('build: PaymentPage');
    return Column(
      children: [
        Text('Còn $_seconds giây'),
        TextButton(
          onPressed: () => setState(() => _seconds--),
          child: const Text('Tích tắc'),
        ),
        QrCode(),
      ],
    );
  }
}

class QrCode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('build: QrCode (nặng)');
    return const Text('FAKE-PAYOS|7|300000');
  }
}
```

### Lượt 2: `const`

Widget `const` là **cùng một object** qua mọi lần `build` của cha (bài 22). Flutter thấy "y cái object cũ" thì bỏ
qua cả nhánh đó, không gọi `build` (bài 33 thử phá 1).

Muốn viết `const QrCode()` thì lớp phải có constructor `const`: `const QrCode({super.key});`

### Lượt 3: tách widget

`setState` chỉ vẽ lại **từ widget gọi nó trở xuống**. Đưa thứ hay đổi (`_seconds`, nút) vào một `StatefulWidget`
nhỏ; phần còn lại nằm ngoài tầm với của nó.

Sau khi tách, `PaymentPage` còn:

```dart
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, this.qrText = 'FAKE-PAYOS|7|300000'});
  final String qrText;

  @override
  Widget build(BuildContext context) {
    debugPrint('build: PaymentPage');
    return Column(children: [const Countdown(), QrCode(text: qrText)]);
  }
}
```

`Countdown` và `QrCode(text)` tự viết.

### Lượt 4a (vỏ Bloc)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// state: (seconds left, qr text)
class PaymentCubit extends Cubit<(int, String)> {
  PaymentCubit() : super((300, 'FAKE-PAYOS|7|300000'));

  void tick() => emit((state.$1 - 1, state.$2));
}

void main() {
  runApp(
    MaterialApp(
      home: BlocProvider(
        create: (_) => PaymentCubit(),
        child: const Scaffold(body: PaymentPage()),
      ),
    ),
  );
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<PaymentCubit, (int, String)>(
          builder: (context, state) {
            debugPrint('build: đồng hồ');
            return Text('Còn ${state.$1} giây');
          },
        ),
        TextButton(
          onPressed: () => context.read<PaymentCubit>().tick(),
          child: const Text('Tích tắc'),
        ),
        BlocBuilder<PaymentCubit, (int, String)>(
          builder: (context, state) {
            debugPrint('build: QrCode (nặng)');
            return Text(state.$2);
          },
        ),
      ],
    );
  }
}
```

`(int, String)` là một **bộ hai giá trị** đi cùng nhau (record): `state.$1` là cái đầu, `state.$2` là cái sau. Hai
record `==` nhau khi từng phần bằng nhau, nên dùng làm state được ngay (bài 23). App thật dùng lớp có tên field cho
dễ đọc.

Một state gồm nhiều thứ thì **mọi** `BlocBuilder` nghe nó đều vẽ lại khi **bất kỳ** thứ nào đổi.

### Lượt 4b: `buildWhen`

```dart
BlocBuilder<ThermoCubit, (int, String)>(
  buildWhen: (previous, current) => previous.$2 != current.$2,
  builder: ...
)
```

`buildWhen` nhận state cũ và mới, trả `true` thì mới vẽ.

## Thử phá

1. Ở lượt 2, bỏ chữ `const` trước `QrCode()` (giữ constructor `const`). Dòng nặng quay lại. Có constructor `const`
   chưa đủ; phải **gọi** bằng `const`. Vì vậy linter của Flutter nhắc `prefer_const_constructors` ở mọi nơi.
2. Ở lượt 4b, viết ngược điều kiện thành `previous.$2 == current.$2`. Mã QR **không vẽ lại cả khi nó đổi thật**.
   `buildWhen` viết sai là màn hình cũ mà không có lỗi nào (cùng họ với "quên field trong `props`" ở bài 23).

## Bắc cầu sang project

| Bài 36 | EH |
|---|---|
| Lượt 1 là có thật | `booking_payment_bloc.dart` dòng 189–209: mỗi giây `emit(state.copyWith(countdownSeconds: remaining))`. State đó chứa cả `qrCode` (`booking_payment_state.dart` dòng 12–20). Mọi `BlocBuilder<BookingPaymentBloc, …>` vẽ lại mỗi giây |
| `buildWhen` / `listenWhen` | `booking_detail_page_web.dart` dòng 62–63 (`listenWhen`); `booking_selection_page_mobile.dart` dòng 41 |
| Tách widget | Các lớp con `_PaymentCard` (dòng 60), `_CountdownChip` (dòng 184) trong `booking_payment_page_web.dart`; mỗi lớp một `BlocBuilder` nhỏ thay cho một cái bọc cả trang |
| `const` | Khắp app; `flutter analyze` của CI nhắc chỗ thiếu |
| Chọn một mẩu của state | `context.select((Bloc b) => b.state.x)` hoặc `BlocSelector`: như `buildWhen` nhưng viết gọn hơn |

**Tìm chỗ vẽ thừa trong app thật** (câu "how do you find it"):
1. Đặt `debugPrint('build: Tên')` như bài này vào widget nghi ngờ. Rẻ nhất, đủ dùng 9 trên 10 lần.
2. DevTools → tab **Flutter Inspector** → bật **Track widget builds**: đếm số lần `build` của từng widget ngay trên
   cây, khỏi sửa code.
3. DevTools → tab **Performance** → nhìn cột **Build** của từng khung hình (bài 37).

**Khi nào không cần sửa:** `build` rẻ (vài `Text`, vài `Padding`) thì vẽ lại 60 lần mỗi giây cũng không sao. Chỉ sửa
khi nhánh bị vẽ lại **nặng** (danh sách dài, ảnh, sơ đồ ghế) hoặc khi đo thấy khung hình chậm. Sơ đồ ghế của EH là
chỗ đáng soi nhất: một state của `BookingCreateBloc` đổi (chọn một ghế) có vẽ lại cả nghìn ô không.

## Xong khi

- [ ] Thấy lượt 1 và 4a (dòng nặng in mỗi lần bấm)
- [ ] Ba cách sửa (2, 3, 4b) đều làm dòng nặng biến mất
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "A widget rebuilds too often: how do you find and fix it?"
