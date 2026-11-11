# Bài 23: hai object "giống nhau" có bằng nhau không

**Lõi một câu:** với lớp tự viết, `==` mặc định hỏi "có phải **cùng một object** không" (y như `identical`). Muốn nó
hỏi "có **cùng nội dung** không" thì tự viết lại `==`, và phải viết lại `hashCode` cho khớp, vì `Set` và `Map` tìm
bằng `hashCode` trước rồi mới dùng `==`.

## Đề

`bai23.dart`: một lớp `Seat` nằm ngoài `main` (Dart bắt vậy), còn lại trong `main`, không package, khoảng 20 dòng.

Lớp `Seat` có một field `code`. Tạo hai ghế **riêng rẽ** cùng mã `A1`.

Phải in ra đúng:

```
cùng nội dung, ==: true
đã chọn A1 chưa: true
Set có: 1
cùng nội dung, identical: false
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Lớp `Seat`. `a = Seat('A1')`, `b = Seat('A1')`, `c = a`. In `a == b` và `a == c` | `a và b cùng nội dung, ==: false` và `a và c cùng một object, ==: true` |
| 2 | Bỏ `c`. In ba dòng: `a == b`; danh sách `[a]` có chứa `b` không; Set `{a, b}` có mấy phần tử | `false`, `false`, `Set có: 2` ← **người dùng chọn A1 rồi mà app bảo chưa; giỏ có hai ghế A1** |
| 3 | Trong `Seat`: viết lại `==` so theo `code` | `true`, `true`, nhưng `Set có: 2` ← **`==` nói bằng nhau mà Set vẫn giữ cả hai** |
| 4 | Trong `Seat`: viết lại `hashCode` lấy từ `code` | `Set có: 1` |
| 5 | In thêm `identical(a, b)` | Đủ 4 dòng như đề |

Lượt 3 là cái bẫy của bài: sửa `==` mà quên `hashCode` thì `List.contains` đúng, `Set` và `Map` sai. Lỗi kiểu này
qua được mọi lần thử bằng mắt cho tới khi ai đó bỏ object vào một `Set`.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: một lớp nhỏ

```dart
class Diem {
  const Diem(this.x);
  final int x;
}
```

`const Diem(this.x);` là constructor: nhận một giá trị, gán vào field `x`. (Chữ `const` ở đây cho phép tạo bằng
`const Diem(1)`, bài 22.)

### Lượt 3: viết lại `==`

```dart
class Diem {
  const Diem(this.x);
  final int x;

  @override
  bool operator ==(Object other) => other is Diem && other.x == x;
}
```

- `operator ==` là hàm chạy khi ai đó viết `a == b`: `this` là `a`, `other` là `b`.
- `other` có kiểu `Object` vì người ta so được với bất cứ thứ gì. `other is Diem &&` kiểm kiểu trước; sau đó Dart
  cho dùng `other.x`.

### Lượt 4: `hashCode`

`hashCode` là **một con số tóm tắt** của object. `Set` dùng nó như số ngăn tủ: tìm đúng ngăn trước, rồi mới `==` với
những thứ trong ngăn. Hai object "bằng nhau" mà khác số ngăn thì Set không bao giờ đem chúng ra so.

Luật: **bằng nhau thì `hashCode` phải bằng nhau.** Cách dễ nhất: lấy `hashCode` của chính những field đã dùng trong
`==`. Chuỗi, số đều có sẵn `.hashCode`.

```dart
  @override
  int get hashCode => x.hashCode;
```

## Thử phá

1. Cho `hashCode` trả cứng `1`. `Set có` mấy? Vẫn đúng: mọi thứ vào chung một ngăn rồi so bằng `==`. Chỉ **chậm**
   (một ngăn chứa tất cả thì Set hết nhanh). Luật không cấm khác nhau mà trùng số ngăn.
2. Cho `hashCode` trả `DateTime.now().microsecondsSinceEpoch`. `Set có` mấy? Số ngăn đổi theo thời gian: bỏ vào
   rồi không tìm lại được. `hashCode` phải **không đổi** chừng nào nội dung không đổi. Trả lại.
3. Tạo hai ghế bằng `const` (`const a = Seat('A1');`). Dòng `identical` ra gì? (Bài 22: hai `const` giống nhau là một
   object.) Trả lại.

## Bắc cầu sang project

Trong EH **không ai tự viết `==`**. Có hai công cụ viết hộ:

| Công cụ | Ở đâu | Bạn viết gì |
|---|---|---|
| `equatable` | `app/lib/features/booking/presentation/view_models/payment/booking_payment_state.dart` dòng 12 `extends Equatable`, dòng 55–61 `props` | Chỉ liệt kê field trong `props`; thư viện sinh `==` và `hashCode` từ danh sách đó |
| `freezed` | `app/lib/features/auth/presentation/view_models/login/login_state.dart` dòng 5 `@freezed` | Không gì cả; code sinh ra (`login_state.freezed.dart`) có sẵn `==`, `hashCode`, `copyWith` |

- **Vì sao state của Bloc bắt buộc phải so được theo nội dung:** `emit(state)` **bỏ qua** nếu state mới `==` state
  hiện tại (khỏi vẽ lại thừa). Mở `app/lib/features/auth/presentation/view_models/auth_bloc.dart` dòng 62–64: chú
  thích "Same state twice emits nothing", và code phải phát một state khác chen giữa để câu báo hiện lại lần hai.
  Không có `==` theo nội dung thì ngược lại: state nào cũng là "mới", màn hình vẽ lại liên tục.
- **Quên một field trong `props`** là đúng lượt 3 theo kiểu khác: hai state khác nhau ở field đó bị coi là bằng nhau,
  `emit` bỏ qua, màn hình **không đổi** dù dữ liệu đã đổi. Gặp "bấm mà không thấy gì" thì soi `props` đầu tiên.
- **Test cũng dựa vào nó:** `app/test/features/auth/presentation/login_cubit_test.dart` dòng 32,
  `expect: () => const [LoginState.submitting(), LoginState.idle()]`, so từng state bằng `==`.
- `String`, `int`, `DateTime` đã có sẵn `==` theo nội dung. `List`, `Map`, `Set` thì **không**: `[1] == [1]` là
  `false`.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 2 và lượt 3 (`==` đúng mà Set sai)
- [ ] Đã thử phá cả 3 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "== vs identical(): how do you override equality?"
