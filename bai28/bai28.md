# Bài 28: việc nặng làm đứng mọi thứ

**Lõi một câu:** Dart chạy một việc một lúc (bài 24), nên một phép tính nặng làm **đứng** mọi thứ khác: timer, mạng,
màn hình. `async` không giúp được gì, vì vẫn là luồng đó chạy. Muốn không đứng thì đẩy việc nặng sang một **isolate**:
một "công nhân" riêng, **bộ nhớ riêng**, chỉ nói chuyện với mình bằng cách gửi giá trị qua lại.

## Đề

`bai28.dart`: hàm `heavy` nằm ngoài `main` (hàm gửi sang isolate nên để ngoài cho sạch), còn lại trong `main`. Chỉ
dùng `dart:async` và `dart:isolate`, khoảng 28 dòng.

- "Đồng hồ" là một timer nhảy mỗi 100 mili-giây, mỗi lần nhảy thì `ticks` tăng 1. Nó đóng vai mọi thứ cần chạy đều:
  hoạt ảnh, đồng hồ đếm ngược ở trang thanh toán.
- `heavy()` bận đúng 1 giây rồi trả một con số.

Phải in ra đúng (số nhịp có thể lệch 1–2 tuỳ máy):

```
tính xong: 43
đồng hồ lúc đang tính: đều (10 nhịp)
visits ở main: 0
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Biến `ticks`, timer `clock` nhảy mỗi 100 ms. Đợi 1 giây bằng `await Future.delayed(...)`, tắt timer, in. Từ 8 nhịp trở lên in `đều`, ít hơn in `đứng` | `đồng hồ nhảy trong 1 giây: đều (10 nhịp)` |
| 2 | Hàm `heavy()`: một vòng `while` bận cho tới khi `Stopwatch` đủ 1000 ms, trả `42`. Thay dòng đợi bằng `final result = heavy();` | `tính xong: 42`, `đồng hồ lúc đang tính: đứng (0 nhịp)` ← **một giây không nhúc nhích** |
| 3 | Thử "làm cho nó async": hàm `heavyAsync()` kiểu `async` chỉ `return heavy();`, gọi bằng `await` | Vẫn `đứng (0 nhịp)` ← **`async` không phải là "chạy ở chỗ khác"** |
| 4 | Xoá `heavyAsync`. `final result = await Isolate.run(heavy);` | `đồng hồ lúc đang tính: đều (10 nhịp)` |
| 5 | Biến `visits` ngoài `main`. `heavy` tăng `visits` và trả `42 + visits`. Cuối `main` in `visits` | Đủ 3 dòng như đề: kết quả là `43`, mà `visits ở main` vẫn `0` |

Lượt 3 là chỗ hay nói sai khi phỏng vấn. `async`/`await` giúp khi mình **chờ** (chờ mạng, chờ đĩa): lúc chờ thì nhường
chỗ. Còn khi mình đang **tính**, không có lúc nào nhường cả.

Lượt 5: isolate tăng `visits` **của nó** lên 1 (nên kết quả là 43), còn `visits` của `main` không ai đụng. Hai bên
không chung biến nào. Thứ duy nhất đi qua là **giá trị trả về**.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: timer lặp

```dart
import 'dart:async';

var dem = 0;
final t = Timer.periodic(const Duration(milliseconds: 500), (_) => dem++);
await Future.delayed(const Duration(seconds: 2));
t.cancel(); // không cancel thì chương trình không bao giờ thoát
print(dem); // 4, có thể 3
```

`(_) => dem++`: timer đưa cho hàm một tham số mình không dùng, đặt tên là `_`.

### Lượt 2: bận trong một khoảng thời gian

```dart
final watch = Stopwatch()..start();
while (watch.elapsedMilliseconds < 300) {
  // busy
}
```

`Stopwatch()..start()`: tạo đồng hồ bấm giờ rồi bấm chạy luôn (`..` là cascade, bài 6).

### Lượt 4: `Isolate.run`

```dart
import 'dart:isolate';

int tinh() => 6 * 7;

final kq = await Isolate.run(tinh); // tên hàm, không có ()
```

`Isolate.run` tạo một isolate mới, chạy hàm ở đó, gửi kết quả về dưới dạng `Future`, rồi dọn isolate.

## Thử phá

1. File riêng:

   ```dart
   import 'dart:isolate';

   void main() async {
     final bookings = ['a1'];
     await Isolate.run(() => bookings.add('a2'));
     print(bookings);
   }
   ```

   In `[a1]`. Isolate nhận một **bản sao** của list, thêm vào bản sao, rồi bản sao bị vứt. Muốn lấy gì từ isolate về
   thì phải `return`.
2. Ở lượt 4, đổi `heavy` cho bận 5 giây (`< 5000`). Đồng hồ vẫn `đều`, khoảng 50 nhịp. Việc nặng dài bao nhiêu cũng
   không làm đứng luồng chính.

## Bắc cầu sang project

- **EH chưa dùng isolate ở đâu cả.** Tìm `Isolate.` hay `compute(` trong `app/lib` không ra dòng nào. Đúng: app chủ
  yếu **chờ** Firebase (việc của `async`), không tính gì nặng.
- **Chỗ sẽ cần nếu app lớn lên:** giải mã sơ đồ ghế "packed" của sự kiện vài nghìn ghế, hay parse một JSON vài MB.
  Dấu hiệu: bấm vào là hoạt ảnh **khựng** một nhịp (bài 37).
- **Trong Flutter** có sẵn hàm `compute(ham, thamSo)`: chính là `Isolate.run`, tên cũ hơn.
- **Cái giá:** tạo isolate mất vài mili-giây, và dữ liệu gửi qua lại phải **chép**. Việc nhỏ mà đẩy sang isolate thì
  chậm hơn tự làm. Chỉ dùng khi một việc chiếm quá một khung hình (16 ms).
- **Không phải mọi thứ đều gửi qua được:** số, chuỗi, list, map, object thường thì được; một kết nối đang mở, một
  `BuildContext` thì không.
- Bài 24 thử phá 1 là lượt 2 của bài này. Bài 37 là lượt 2 trên màn hình thật.

| | `async`/`await` | Isolate |
|---|---|---|
| Dùng khi | Chờ thứ bên ngoài: mạng, đĩa, timer | Tính nặng bằng CPU |
| Mấy luồng | Một | Mỗi isolate một luồng |
| Bộ nhớ | Chung | Riêng, gửi bản sao |
| Trong EH | Khắp nơi | Chưa có |

## Xong khi

- [ ] In đúng 3 dòng như đề (số nhịp lệch 1–2 là được)
- [ ] Đã thấy lượt 2 và lượt 3 đều `đứng (0 nhịp)`
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What are isolates, and when would you use one?"
