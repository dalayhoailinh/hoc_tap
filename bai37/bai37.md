# Bài 37 (thí nghiệm Flutter): một khung hình dài cả giây

**Lõi một câu:** Flutter phải vẽ xong mỗi khung hình trong khoảng **16 mili-giây** (60 khung một giây). Code Dart của
bạn và việc vẽ chạy **chung một luồng** (bài 24), nên một việc nặng trong hàm bấm nút làm **không khung hình nào
được vẽ** cho tới khi nó xong: màn hình đứng, đó là **jank**. Tìm bằng cách **đo thời gian từng khung hình**; sửa
bằng cách đưa việc nặng ra isolate (bài 28).

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai37
flutter create --empty --platforms=windows app
cd app
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R`.

## Đề

Trang có một vòng xoay `CircularProgressIndicator` (nó xoay được là nhờ mỗi khung hình vẽ lại một chút: vòng xoay
đứng nghĩa là không có khung hình nào) và hai nút cùng làm một việc nặng 1 giây: **Tính tại chỗ**, **Tính ở
isolate**.

Xong khi bấm lần lượt hai nút, terminal in:

```
tính trên luồng UI...
xong: 42
khung hình chậm: 1015 ms
tính ở isolate...
xong: 42
```

(Con số `1015` mỗi lần một khác, quanh 1000. Sau lần bấm thứ hai **không có** dòng `khung hình chậm`.)

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Vỏ bên dưới: vòng xoay + hàm `heavy()` + nút **Tính tại chỗ** gọi thẳng `heavy()` | Bấm: vòng xoay **đứng khựng 1 giây** rồi mới xoay tiếp. Terminal: `tính trên luồng UI...`, `xong: 42` |
| 2 | Trong `main`, sau `runApp`: `addTimingsCallback` in những khung hình dài hơn 100 ms | Bấm lại: thêm dòng `khung hình chậm: 1015 ms` |
| 3 | Nút **Tính ở isolate**: `await Isolate.run(heavy)` | Bấm: vòng xoay **vẫn xoay đều**; `tính ở isolate...`, 1 giây sau `xong: 42`; không có dòng chậm |

Lượt 1 là thứ người dùng thấy ("app bị đơ"). Lượt 2 là thứ bạn đo được. Một khung hình đáng lẽ 16 ms mà tốn 1015 ms
nghĩa là khoảng **60 khung hình bị bỏ**.

## Từng lượt

### Lượt 1 (vỏ)

```dart
import 'package:flutter/material.dart';

int heavy() {
  final watch = Stopwatch()..start();
  while (watch.elapsedMilliseconds < 1000) {
    // busy
  }
  return 42;
}

void main() {
  runApp(const MaterialApp(home: Scaffold(body: SeatMapPage())));
}

class SeatMapPage extends StatelessWidget {
  const SeatMapPage({super.key});

  void _onUiThread() {
    debugPrint('tính trên luồng UI...');
    final result = heavy();
    debugPrint('xong: $result');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        TextButton(onPressed: _onUiThread, child: const Text('Tính tại chỗ')),
      ],
    );
  }
}
```

`heavy()` là hàm của bài 28. Trong app thật nó là: giải mã sơ đồ ghế vài nghìn ô, parse một JSON lớn, lọc và sắp một
danh sách dài.

### Lượt 2: đo từng khung hình

Thêm `import 'package:flutter/scheduler.dart';` và, trong `main` sau `runApp`:

```dart
  // One entry per frame drawn: how long it took from "time to draw" to "on screen".
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final frame in timings) {
      final ms = frame.totalSpan.inMilliseconds;
      // tự viết: dài hơn 100 thì in 'khung hình chậm: ... ms'
    }
  });
```

Flutter gọi hàm này sau mỗi mẻ khung hình, kèm số đo của từng khung. `totalSpan` là từ lúc "tới giờ vẽ" tới lúc
hình lên màn.

### Lượt 3

Thêm `import 'dart:isolate';`, một hàm `async` và một nút, y bài 28 lượt 4.

## Thử phá

1. Thử "sửa" bằng `async`: đổi `_onUiThread` thành `Future<void> ... async` và gọi
   `await Future(() => heavy());`. Vòng xoay có hết đứng không? Không (bài 28 lượt 3): vẫn là luồng đó tính.
2. Giảm việc nặng xuống 50 ms (`< 50`) và hạ ngưỡng in xuống 16. Bấm Tính tại chỗ: mắt gần như không thấy khựng,
   nhưng vẫn có dòng `khung hình chậm: 5x ms`. Jank nhỏ không nhìn ra bằng mắt ở một lần bấm; nó lộ ra khi **cuộn**
   hay khi có hoạt ảnh, thành cảm giác "giật giật". Vì vậy phải đo.

## Bắc cầu sang project

**Tìm jank bằng DevTools** (câu phỏng vấn hỏi đúng cái này):

1. Chạy bản **profile**, không phải debug: `flutter run --profile -d windows` (với điện thoại thì cắm máy thật). Bản
   debug chậm hơn bản thật nhiều lần, đo nó là đo sai.
2. Mở DevTools (đường link in ra ở terminal, hoặc trong VS Code: *Dart: Open DevTools*), tab **Performance**.
3. Dùng app. Biểu đồ **Frames** vẽ mỗi khung hình một cột; cột vượt vạch 16 ms tô **đỏ**. Đó chính là dòng
   `khung hình chậm` của bạn, vẽ thành hình.
4. Bấm vào một cột đỏ. Nó chia hai phần:
   - **UI** (build + layout, chạy code Dart của bạn) dài → code của mình chậm: việc nặng trong hàm bấm, `build` quá
     to hoặc chạy thừa (bài 36).
   - **Raster** (đổ hình lên GPU) dài → hình quá nặng: ảnh to, nhiều lớp trong suốt, bóng đổ, cắt hình (`ClipPath`).
5. Với phần UI: bảng **Timeline events** bên dưới chỉ ra hàm nào chiếm thời gian.

| Bài 37 | Công cụ thật |
|---|---|
| `addTimingsCallback` + `print` | Biểu đồ Frames của DevTools; hoặc bật `showPerformanceOverlay: true` trong `MaterialApp` để có hai dải biểu đồ ngay trên app |
| "Dài hơn 100 ms thì in" | Vạch 16 ms |
| `heavy()` trên luồng UI | Cột **UI** đỏ |
| `Isolate.run(heavy)` | Cột về xanh; việc nặng hiện ở một luồng khác |

- **EH chưa đo lần nào** (không có dòng nào về hiệu năng trong `PROGRESS.md`). Chỗ đáng đo đầu tiên: trang chọn ghế
  với sơ đồ lớn (bài 36 cuối bài), và trang chủ khi cuộn danh sách có ảnh.
- **Nguyên nhân jank hay gặp, theo thứ tự nên nghi:** (1) việc nặng đồng bộ trong hàm bấm hoặc trong `build`;
  (2) `build` chạy thừa trên một nhánh to; (3) danh sách dài không dùng `ListView.builder` (dựng hết mọi dòng thay vì
  chỉ dòng đang thấy); (4) ảnh to hơn chỗ hiển thị nhiều lần.
- `async` không phải thuốc: chờ mạng thì không gây jank (lúc chờ, luồng rảnh); **tính** mới gây.

## Xong khi

- [ ] Thấy vòng xoay đứng ở lượt 1 và xoay đều ở lượt 3
- [ ] Có dòng `khung hình chậm` sau nút thứ nhất, không có sau nút thứ hai
- [ ] Đã thử phá cả 2 cách
- [ ] Mở DevTools một lần ở bản profile, tìm được cột đỏ ứng với cú bấm Tính tại chỗ
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do you find jank with DevTools?"
