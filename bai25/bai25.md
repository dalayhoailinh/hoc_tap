# Bài 25: lỗi đến muộn

**Lõi một câu:** lỗi trong hàm `async` không bay ra ở dòng **gọi** hàm; nó nằm trong cái `Future` và chỉ lộ ra ở chỗ
bạn **`await`** Future đó. `try/catch` chỉ bắt được khi có `await` bên trong. Không đợi thì phải gắn `catchError`; với
stream thì gắn `onError`. Không ai nhận thì chương trình chết.

## Đề

`bai25.dart`: mọi thứ trong `main`, hai hàm nhỏ trong `main`, chỉ dùng `dart:async`, khoảng 35 dòng.

Hàm `pay()` đóng vai lời gọi thanh toán: đợi một nhịp rồi **luôn** ném lỗi `'mất mạng'`.

Phải in ra đúng:

```
có await: bắt được mất mạng
stream: giá 500000
stream: bắt được hỏng giữa chừng
catchError: bắt được mất mạng
guard: Err(mất mạng)
hết main
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Hàm `pay()` kiểu `async`: `await Future.delayed(Duration.zero);` rồi `throw 'mất mạng';`. Gọi `await pay()` trong `try/catch`. Cuối `main` in `hết main` | `có await: bắt được mất mạng`, `hết main` |
| 2 | Thêm một khối `try/catch` y hệt nhưng **bỏ chữ `await`**; ngay dưới lời gọi in `không await: không thấy lỗi gì`. Trước dòng `hết main` thêm `await Future.delayed(const Duration(milliseconds: 10));` | `không await: không thấy lỗi gì`, rồi `Unhandled exception: mất mạng`; **`hết main` không bao giờ in** |
| 3 | Thay khối của lượt 2 bằng: gọi `pay()` không đợi, gắn `.catchError(...)` in `catchError: bắt được ...` | `có await…`, `catchError: bắt được mất mạng`, `hết main` |
| 4a | `StreamController<int>` tên `prices`. `listen` in `stream: giá ...`. `add(500000)` rồi `addError('hỏng giữa chừng')` | `stream: giá 500000`, rồi `Unhandled exception: hỏng giữa chừng` |
| 4b | Thêm `onError:` vào `listen` | 4 dòng đầu của đề + `hết main` |
| 5 | Hàm `guard(run)`: chạy `run`, được thì trả chuỗi `Ok(<giá trị>)`, lỗi thì trả `Err(<lỗi>)`. **Không bao giờ ném.** In `guard: ${await guard(pay)}` | Đủ 6 dòng như đề |

Lượt 2 là cái hỏng: khối `try` chạy xong **trước khi** lỗi tồn tại. Lúc `pay()` ném, không còn ai đứng đó để bắt.
Dòng "không thấy lỗi gì" in ra rất tự tin, rồi chương trình chết ở một chỗ không liên quan.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 3: `catchError`

```dart
Future<int> chia() async => throw 'chia cho 0';

chia().catchError((e) {
  print('lỗi: $e');
  return -1; // Future<int> thì phải trả một int thay thế
});
```

`catchError` là "gắn sẵn người nhận lỗi vào cái phiếu hẹn". Dùng khi cố ý không đợi.

### Lượt 4b: `onError` của stream

```dart
temps.stream.listen(
  (t) => print('nhận $t'),
  onError: (e) => print('hỏng: $e'),
);
```

Stream khác Future ở chỗ: lỗi là **một tin trong dòng**, sau lỗi stream vẫn sống và phát tiếp được.

### Lượt 5: nhận một hàm làm tham số

Kiểu của tham số: `Future<int> Function() run` ("một hàm không nhận gì, trả `Future<int>`"), như `body` ở bài 12 lượt
5a. Gọi nó: `await run()`. Truyền vào: `guard(pay)`, **tên hàm, không có `()`**.

`try/catch` nằm **bên trong** `guard`, và có `await` bên trong `try`.

## Thử phá

1. Trong `guard`, bỏ chữ `await` trước `run()` (trả thẳng `'Ok(${run()})'`). In ra gì, rồi chuyện gì xảy ra? Cái
   lưới an toàn thủng đúng bằng một chữ `await`. Trả lại.
2. Nhìn lại thứ tự output của đề: dòng `catchError` in **sau** hai dòng `stream`, dù viết trước. Vì sao? (Bài 24:
   `pay()` còn phải đợi một event mới ném; tin của stream chỉ là microtask.)

## Bắc cầu sang project

| Bài 25 | EH |
|---|---|
| `guard(run)` | `app/lib/core/result/guard.dart` dòng 7–37: `Future<Result<T>> guard<T>(Future<T> Function() run)`. Cùng tên, cùng hình |
| `try { return 'Ok(${await run()})' }` | Dòng 8–9: `try { return Ok(await run()); }` |
| `catch → 'Err(...)'` | Dòng 10–36: mỗi loại exception đổi thành một loại `Failure`; cuối cùng `catch (e, stackTrace)` hứng mọi thứ còn lại thành `UnknownFailure` |
| `Ok` / `Err` là giá trị, không phải lỗi bay | `app/lib/core/result/result.dart`: `sealed class Result<T>`, `Ok<T>`, `Err<T>` |
| Người gọi `guard` không cần `try/catch` | `login_cubit.dart` dòng 27–34: `switch (result) { case Ok(): ... case Err(:final failure): ... }` |
| `onError` của stream | `auth_bloc.dart` dòng 31–34: `.listen((user) => add(...), onError: addError)` |
| Cố ý không đợi | `booking_payment_bloc.dart` dòng 89: `unawaited(...)` |

- **Vì sao EH đổi lỗi thành giá trị (`Result`):** `try/catch` là thứ **dễ quên**; quên thì không ai nhắc, tới lúc
  chạy mới chết (lượt 2). `Result` thì khác: muốn lấy giá trị ra phải `switch`, mà `switch` trên `sealed class` thiếu
  nhánh `Err` là **compiler báo lỗi**. Lỗi bị quên chuyển từ "lúc chạy" về "lúc biên dịch".
- **Chỗ duy nhất có `try/catch`** là `guard` và tầng datasource. Từ repository trở lên chỉ còn `Result`.
- **Lỗi có hai mặt** (bài 12): `Failure` mang `message` cho người đọc và `errorCode` cho máy.
- Lượt 2 trong Flutter không làm chết app; nó in một đống đỏ vào console và màn hình **đứng yên ở trạng thái đang
  tải**. Thấy spinner quay mãi thì nghi một `Future` bị quên `await`.

## Xong khi

- [ ] In đúng 6 dòng như đề
- [ ] Đã thấy lượt 2 (`hết main` không in) và lượt 4a
- [ ] Đã thử phá 1
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do you handle errors in async code?"
