# Bài 31 (thí nghiệm Flutter): vẽ, và làm một lần

**Lõi một câu:** `BlocBuilder` trả lời "state này thì **màn hình trông ra sao**"; hàm của nó có thể chạy rất nhiều
lần, nên trong đó chỉ được **vẽ**. `BlocListener` trả lời "state **vừa đổi** thì **làm gì một lần**" (hiện thông báo,
chuyển trang); nó chỉ chạy khi state đổi. `BlocConsumer` là cả hai gói chung.

Đây là bài thí nghiệm: làm trong một app Flutter trống, chỉ sửa `lib/main.dart`. "Chạy thấy" là các dòng in ở
terminal và thứ hiện trên màn hình.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai31
flutter create --empty --platforms=windows app
cd app
flutter pub add flutter_bloc
flutter run -d windows
```

Sửa xong thì lưu, bấm `R` ở terminal.

## Đề

Một trang thanh toán tí hon. `PaymentCubit` có state là chuỗi: ban đầu `đang chờ`, gọi `moneyArrived()` thì thành
`đã trả`. Trang có:
- một dòng chữ `Trạng thái: <state>`;
- nút **Tiền về** (gọi `moneyArrived()`);
- nút **Vẽ lại trang** (`setState` của trang, đóng vai mọi lý do khiến trang bị vẽ lại: xoay máy, bàn phím bật lên,
  widget cha đổi…);
- khi tiền về, hiện **đúng một** SnackBar "Đã nhận tiền".

Xong khi bấm Tiền về rồi bấm Vẽ lại trang hai lần, terminal in đúng:

```
builder chạy: đang chờ
báo: Đã nhận tiền (lần 1)
builder chạy: đã trả
builder chạy: đã trả
builder chạy: đã trả
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** bên dưới: cubit, trang, `BlocBuilder` có một dòng `debugPrint` | Mở app: `builder chạy: đang chờ`. Bấm Tiền về: `builder chạy: đã trả`, chữ đổi. Bấm Vẽ lại trang: lại `builder chạy: đã trả`, dù state không đổi |
| 2 | Hàm `_notify()` (vỏ bên dưới). Trong `builder`: state là `đã trả` thì gọi `_notify()` | Bấm Tiền về: màn hình **đỏ**; terminal: `báo: Đã nhận tiền (lần 1)` rồi lỗi `The showSnackBar() method cannot be called during build.` |
| 3 | "Né" lỗi: bọc lời gọi trong `WidgetsBinding.instance.addPostFrameCallback((_) => _notify());` | Bấm Tiền về: có SnackBar. Bấm Vẽ lại trang hai lần: `báo: … (lần 2)`, `báo: … (lần 3)` ← **không có tiền nào về thêm mà báo ba lần** |
| 4 | Bỏ phần báo khỏi `builder`. Bọc `BlocBuilder` trong một `BlocListener`, gọi `_notify()` ở `listener` | Bấm Tiền về: `báo: … (lần 1)` rồi `builder chạy: đã trả`. Bấm Vẽ lại trang hai lần: chỉ hai dòng `builder chạy`, **không báo thêm** |
| 5 | Gộp hai cái lồng nhau thành một `BlocConsumer`, thêm `listenWhen` | Y như lượt 4 (đổi hình, không đổi hành vi) |

Lượt 2 là Flutter chặn bạn. Lượt 3 mới nguy hiểm: hết lỗi đỏ, bấm thử một lần thấy đúng, và sai chỉ lộ khi trang bị
vẽ lại vì một lý do không liên quan.

## Từng lượt

### Lượt 1 (vỏ)

`lib/main.dart`, thay hết:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentCubit extends Cubit<String> {
  PaymentCubit() : super('đang chờ');

  void moneyArrived() => emit('đã trả');
}

void main() {
  runApp(
    MaterialApp(
      home: BlocProvider(
        create: (_) => PaymentCubit(),
        child: const PaymentPage(),
      ),
    ),
  );
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  var _redraws = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Column(
        children: [
          BlocBuilder<PaymentCubit, String>(
            builder: (context, state) {
              debugPrint('builder chạy: $state');
              return Text('Trạng thái: $state');
            },
          ),
          FilledButton(
            onPressed: () => context.read<PaymentCubit>().moneyArrived(),
            child: const Text('Tiền về'),
          ),
          TextButton(
            onPressed: () => setState(() => _redraws++),
            child: Text('Vẽ lại trang ($_redraws)'),
          ),
        ],
      ),
    );
  }
}
```

- `PaymentCubit` là `Cubit` thật của thư viện; bài 29 bạn đã tự viết cái lõi của nó.
- `BlocProvider(create: ...)` đặt cubit lên **phía trên** trang; mọi widget bên dưới lấy được nó bằng
  `context.read<PaymentCubit>()` (bài 33 nói kỹ chuyện "phía trên").
- `BlocBuilder<PaymentCubit, String>`: nghe cubit (`listen` của bài 29), mỗi state mới thì gọi `builder` và vẽ lại
  **đúng phần của nó**.

### Lượt 2

Vỏ, thêm vào `_PaymentPageState`:

```dart
  var _notices = 0;

  void _notify() {
    _notices++;
    debugPrint('báo: Đã nhận tiền (lần $_notices)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã nhận tiền (lần $_notices)')),
    );
  }
```

Tự viết: trong `builder`, trước dòng `return`, state là `đã trả` thì gọi `_notify()`.

Flutter từ chối: hiện SnackBar là **đổi** màn hình, mà đang ở giữa lúc vẽ thì không được đổi.

### Lượt 3

`addPostFrameCallback` nghĩa là "vẽ xong khung hình này rồi hãy chạy". Lỗi đỏ biến mất. Nhưng `builder` chạy mỗi lần
trang vẽ lại, nên việc "làm một lần" thành việc "làm mỗi lần vẽ".

Thứ nguy hiểm ở vị trí này trong app thật không phải SnackBar mà là **chuyển trang**: `context.go(...)` trong
`builder` là chuyển đi chuyển lại.

### Lượt 4

```dart
BlocListener<ThermoCubit, int>(
  listener: (context, temp) {
    if (temp > 38) print('gọi bác sĩ');
  },
  child: BlocBuilder<ThermoCubit, int>(
    builder: (context, temp) => Text('$temp độ'),
  ),
)
```

`BlocListener` không vẽ gì; nó chỉ bọc quanh `child`. `listener` chạy **một lần cho mỗi lần state đổi**, và chạy
ngoài lúc vẽ, nên hiện SnackBar hay chuyển trang ở đó đều được.

Để ý thứ tự dòng in: `báo` đứng **trước** `builder chạy: đã trả`. Listener được báo ngay khi state đổi; builder chờ
tới khung hình kế.

### Lượt 5

```dart
BlocConsumer<ThermoCubit, int>(
  listenWhen: (previous, current) => current > 38,
  listener: (context, temp) => print('gọi bác sĩ'),
  builder: (context, temp) => Text('$temp độ'),
)
```

`listenWhen` lọc trước: chỉ những lần đổi thoả điều kiện mới tới `listener`. (`buildWhen` làm y vậy cho `builder`;
bài 36 dùng nó.)

## Thử phá

1. Ở lượt 5, đổi `listenWhen` thành `(previous, current) => true`, và trong cubit thêm một state nữa:
   `void expire() => emit('hết hạn');` kèm một nút gọi nó. Bấm nút đó: báo "Đã nhận tiền" dù đơn hết hạn. Listener
   chạy cho **mọi** lần đổi; lọc là việc của bạn.
2. Bấm Tiền về **hai lần**. Báo mấy lần? Một: lần hai `emit('đã trả')` trùng state cũ nên không ai được báo
   (bài 29 lượt 3b).

## Bắc cầu sang project

| Bài 31 | EH |
|---|---|
| `BlocProvider(create: …)` | `app/lib/features/booking/presentation/pages/payment/web/booking_payment_page_web.dart` dòng 23–25 |
| `BlocListener` + chuyển trang | Cùng file dòng 26–41: state `confirmed` thì `context.goNamed(RouterNames.bookingSuccess, …)`; `expired` thì `showSnackBar` rồi `context.pop()`. Đây là "trang tự sang vé" của bài 16, 17 |
| `BlocBuilder` | Cùng file dòng 67: vẽ mã QR, đồng hồ |
| `BlocConsumer` + `listenWhen` | `app/lib/features/booking/presentation/pages/detail/web/booking_detail_page_web.dart` dòng 61–68: chỉ báo lỗi khi `failure` **và** đã từng có dữ liệu |
| `if (!context.mounted) return;` | `booking_payment_page_web.dart` dòng 28 (bài 24: sau một nhịp chờ, trang có thể đã đóng) |
| Trang auth chỉ dùng `BlocBuilder` | `login_page.dart` dòng 79: form không cần chuyển trang, vì việc điều hướng sau đăng nhập do router nghe `AuthBloc` lo (bài 6 lượt 6b) |

Cách chọn nhanh:

| Muốn | Dùng |
|---|---|
| Đổi thứ hiện trên màn hình theo state | `BlocBuilder` |
| SnackBar, dialog, chuyển trang, gọi một hàm | `BlocListener` |
| Cả hai, cùng một bloc | `BlocConsumer` |

## Xong khi

- [ ] Terminal in đúng 5 dòng như đề sau ba lần bấm
- [ ] Đã thấy lượt 2 (màn hình đỏ) và lượt 3 (báo ba lần)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "BlocBuilder vs BlocListener vs BlocConsumer"
