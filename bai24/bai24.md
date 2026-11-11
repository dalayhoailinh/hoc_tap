# Bài 24: ai chạy trước

**Lõi một câu:** Dart chỉ làm **một việc một lúc**. Nó chạy việc đang làm tới hết, rồi lấy hết hàng **microtask**
(việc gấp), rồi mới lấy **một event** (việc thường: timer, mạng, bấm nút), và lặp lại. `await` nghĩa là "tôi dừng ở
đây, **nhường chỗ**, phần còn lại của tôi xếp hàng chạy sau".

## Đề

`bai24.dart`: mọi thứ trong `main`, một hàm nhỏ trong `main`, chỉ dùng `dart:async`, khoảng 15 dòng.

Bài này làm kiểu khác: **trước mỗi lần chạy, viết ra giấy thứ tự các dòng bạn đoán**, rồi mới chạy và so.

Phải in ra đúng:

```
1 main: bắt đầu
fetch: trước await
microtask
event
fetch: sau await
giá: 500000
2 main: hết
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Ba dòng: in `1 main: bắt đầu`; `Future(() => print('event'));`; in `2 main: hết` | `1 main: bắt đầu`, `2 main: hết`, `event` ← dòng viết ở giữa lại in cuối |
| 2 | Dưới dòng `Future`: `scheduleMicrotask(() => print('microtask'));` | `1…`, `2…`, `microtask`, `event` ← viết **sau** `event` mà chạy **trước** |
| 3 | Hàm `fetchPrice()` kiểu `async`: in `fetch: trước await`, `await Future.delayed(Duration.zero);`, in `fetch: sau await`, trả `500000`. Gọi nó (chưa lấy kết quả) trên dòng `2 main: hết` | `1…`, `fetch: trước await`, `2 main: hết`, `microtask`, `event`, `fetch: sau await` |
| 4 | Lấy kết quả: `final price = fetchPrice();` rồi in `giá: $price` | `giá: Instance of 'Future<int>'` ← **cầm cái phiếu hẹn, chưa cầm giá** |
| 5 | `main` thành `async`, thêm `await` trước `fetchPrice()` | Đủ 7 dòng như đề |

Lượt 4 là cái hỏng: hàm `async` trả về **ngay lập tức** một `Future` (phiếu hẹn). Không có `await` thì code phía dưới
chạy tiếp với cái phiếu, không phải với giá trị.

Nhìn lượt 5: `2 main: hết` giờ in **cuối cùng**. `await` biến phần còn lại của `main` thành "việc chạy sau", nên
microtask và event chen lên trước.

## Gợi ý từng lượt

### Ba hàng chờ

| Hàng | Ai xếp vào | Khi nào chạy |
|---|---|---|
| Việc đang chạy | Code thường, từ trên xuống | Ngay, chạy tới hết (hoặc tới một `await`) |
| Microtask | `scheduleMicrotask(...)`, phần sau `await` của một Future **đã xong sẵn** | Ngay khi việc đang chạy dừng, **lấy hết** rồi mới đi tiếp |
| Event | `Future(...)`, `Future.delayed(...)`, `Timer`, dữ liệu mạng về, người dùng bấm | Mỗi lần **một** cái, khi hàng microtask đã trống |

`import 'dart:async';` (đầu file) để có `scheduleMicrotask`.

### Lượt 3: hàm `async`

```dart
Future<String> docTen() async {
  print('a');
  await Future.delayed(Duration.zero);
  print('b');
  return 'Chi';
}
```

- Gọi `docTen()`: nó chạy **ngay** tới `await` đầu tiên (in `a`), rồi trả quyền cho người gọi.
- `Future.delayed(Duration.zero)`: "một event, càng sớm càng tốt". Nó xếp hàng **sau** các event đã có.
- `return 'Chi'` trong hàm `async` tự gói thành `Future<String>`.

### Lượt 5

Muốn dùng `await` trong hàm nào thì hàm đó phải có chữ `async`: `void main() async { ... }`.

## Thử phá

1. File riêng, 8 dòng: `Future(() => print('event'));` rồi một vòng lặp bận suốt 2 giây, rồi in "xong":

   ```dart
   final watch = Stopwatch()..start();
   var x = 0;
   while (watch.elapsedMilliseconds < 2000) {
     x++;
   }
   print('vòng lặp xong');
   ```

   `event` chỉ in **sau** 2 giây. Một việc đang chạy thì không ai chen được, kể cả timer, kể cả cú bấm của người
   dùng. Trong Flutter, đó là màn hình **đứng hình** (bài 37). `async` không cứu được chuyện này; bài 28 mới cứu.
2. Trong `fetchPrice`, đổi `await Future.delayed(Duration.zero);` thành `await null;`. Dòng `event` nhảy đi đâu?
   `await` một thứ **đã có sẵn** thì phần sau chỉ là microtask, nên cả `fetch`, `giá`, `2 main: hết` chạy xong trước
   `event`. Trả lại.

## Bắc cầu sang project

| Bài 24 | EH |
|---|---|
| Hàm `async` + `await` | Gần như mọi hàm trong datasource, vd `seat_lock_remote_datasource.dart` dòng 140–195 `lockSeat` |
| Event từ timer | `verify_email_cubit.dart` dòng 22–24: `Timer.periodic(_pollInterval, (_) => _poll())`; `booking_payment_bloc.dart` dòng 211–216: đồng hồ đếm ngược |
| Event từ mạng | `booking_payment_bloc.dart` dòng 218–232: mỗi lần doc đổi là một event vào hàm `listen` |
| Lượt 4: quên `await` | Có chủ đích: `booking_payment_bloc.dart` dòng 89 `unawaited(_localDataSource.clearPendingBookingId());`. Viết `unawaited(...)` là nói rõ "tôi cố ý không đợi" |
| "Sau `await`, thế giới có thể đã đổi" | `login_cubit.dart` dòng 26 `if (isClosed) return;` và mọi dòng `if (mounted)` trong widget (bài 6 lượt 2) |

- **Dòng `if (mounted)` / `if (isClosed)` chính là bài này:** trong lúc hàm của bạn nhường chỗ ở `await`, các event
  khác chạy. Một trong số đó có thể là "người dùng đóng trang". Khi hàm chạy tiếp, trang đã không còn.
- **Vì sao `server.listen(handle)` ở bài 12 gây bán trùng:** mỗi request là một event; `handle` của request 1 dừng ở
  `await tx.get(...)`, event loop lấy request 2 ra chạy. Hai hàm **đan xen** nhau ở các điểm `await`. Giữa hai
  `await` thì không ai chen được: đó là lý do bài 12 lượt 8b dặn "giữa dòng so `version` và dòng áp nháp không được
  có `await`".
- **Framework làm hộ:** bạn không bao giờ viết vòng lặp "lấy event ra chạy". Nó nằm trong máy ảo Dart; Flutter gắn
  thêm vào đó việc vẽ khung hình.

## Xong khi

- [ ] In đúng 7 dòng như đề
- [ ] Đoán đúng thứ tự ở ít nhất lượt 5 trước khi chạy
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do async/await and the event loop work?"
