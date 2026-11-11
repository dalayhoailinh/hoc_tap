# Bài 27: gắn thêm hàm mà không kế thừa

**Lõi một câu:** Dart chỉ cho `extends` **một** lớp. Muốn nhiều lớp cùng có chung vài hàm thì gói các hàm đó vào một
`mixin` rồi "trộn" vào bằng `with`. Còn muốn gắn thêm hàm cho một kiểu **không phải của mình** (`int`, `String`,
`BuildContext`) thì viết `extension`.

## Đề

`bai27.dart`: bài này toàn là khai báo lớp nên nằm ngoài `main`; `main` chỉ còn 3 dòng gọi. Không package, khoảng 30
dòng.

- Hai lớp `BookingService` và `PaymentService`, đều kế thừa `Service` (có sẵn field `startedAt`), đều cần hàm
  `log(message)` in `[<tên lớp>] <message>`.
- Số tiền in theo kiểu Việt: `1000000` thành `1.000.000đ`.

Phải in ra đúng:

```
[BookingService] đặt 2 vé
[PaymentService] thu 1.000.000đ
500đ
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Hai lớp, **mỗi lớp tự viết** hàm `log` y hệt nhau. `BookingService.book(quantity)` log `đặt … vé`; `PaymentService.pay(amount)` log `thu …`. Gọi cả hai | `[BookingService] đặt 2 vé`, `[PaymentService] thu 1000000` (chạy được, nhưng một hàm chép hai nơi) |
| 2 | Đưa `log` vào lớp `Logger`. Thêm lớp `Service` có `final startedAt = DateTime.now();`. Hai lớp kia `extends Service, Logger` | Không chạy được: `Error: Each class definition can have at most one extends clause.` |
| 3 | `Logger` đổi từ `class` thành `mixin`; hai lớp viết `extends Service with Logger` | Hai dòng như lượt 1 |
| 4 | Trong `pay`: in `amount.vnd` thay cho `amount` | Không chạy được: `Error: The getter 'vnd' isn't defined for the type 'int'.` |
| 5 | `extension Money on int` có getter `vnd`. Trong `main` in thêm `500.vnd` | Đủ 3 dòng như đề |

Lượt 2 và lượt 4 là hai bức tường: một lớp chỉ có **một** cha; và `int` là lớp của Dart, bạn **không mở ra sửa
được**.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: tên lớp của chính mình

Trong một hàm của lớp, `runtimeType` là tên lớp của object đang chạy: `print('[$runtimeType] xin chào');`.

### Lượt 3: mixin

```dart
mixin BietBoi {
  void boi() => print('$runtimeType đang bơi');
}

class DongVat {}

class Vit extends DongVat with BietBoi {}

class Ca extends DongVat with BietBoi {}

void main() {
  Vit().boi(); // Vit đang bơi
}
```

- `mixin` viết giống một lớp nhưng **không tạo object từ nó được**; nó chỉ để trộn.
- `with A, B, C`: trộn được nhiều cái.
- Hàm trong mixin chạy như thể được viết ngay trong lớp trộn nó: `runtimeType` là `Vit`, không phải `BietBoi`.

### Lượt 5: extension

```dart
extension ChuHoa on String {
  String get het => toUpperCase() + '!';
}

void main() {
  print('xin chào'.het); // XIN CHÀO!
}
```

Trong extension, `this` là giá trị đứng trước dấu chấm.

Chèn dấu chấm mỗi ba chữ số, đi từ phải sang (`substring(a, b)` lấy từ vị trí `a` tới trước `b`):

```dart
var text = '1234567';
for (var i = text.length - 3; i > 0; i -= 3) {
  text = '${text.substring(0, i)}.${text.substring(i)}';
}
print(text); // 1.234.567
```

## Thử phá

1. Trong `main`: `dynamic x = 500; print(x.vnd);`. Chạy: `NoSuchMethodError: Class 'int' has no instance getter
   'vnd'.` Extension **không thật sự thêm gì vào `int`**. Nó là một hàm rời, Dart chọn lúc **biên dịch** dựa trên kiểu
   ghi trong code. `dynamic` giấu kiểu đi nên Dart không tìm ra. (Mixin thì khác: hàm của nó **nằm thật** trong lớp.)
2. Thử `Logger().log('x')` trong `main`. Lỗi gì? Mixin không tạo object được. Xoá đi.

## Bắc cầu sang project

**Extension**: mở `app/lib/core/utils/extensions.dart`:

| Dòng | Extension | Cho phép viết |
|---|---|---|
| 5 | `extension StringExtensions on String` | `'hello'.capitalize`, `email.isValidEmail` |
| 49–55 | `extension BuildContextExtensions on BuildContext` | `context.colorScheme`, `context.customColors`, `context.showSnackBar(...)` thay cho `Theme.of(context).colorScheme` |
| 134–141 | `extension NumExtension on num` | `50000.toCurrencyVND` → `50.000₫`. Chính là `vnd` của bạn, viết bằng regex |

- `context.read<LoginCubit>()` của `flutter_bloc` và `context.go('/home')` của `go_router` cũng là extension trên
  `BuildContext`: thư viện gắn thêm hàm vào một lớp của Flutter.
- Luật của EH "dùng màu từ theme, không ghi cứng" dựa vào dòng 51–52: `context.colorScheme`, `context.customColors`.

**Mixin**: EH không tự viết mixin nào, chỉ dùng của Flutter:

| Ở đâu | Mixin | Để làm gì |
|---|---|---|
| `app/lib/features/ai/presentation/widgets/chat_bubble.dart` dòng 112–114 | `State<...> with SingleTickerProviderStateMixin` | `State` đã `extends State` rồi, không extends thêm được; trộn mixin này để nó cấp "nhịp" cho `AnimationController` |
| `app/lib/features/events/presentation/widgets/featured_events_carousel.dart` dòng 288–291 | `with AutomaticKeepAliveClientMixin` | Giữ trang trong carousel sống khi lướt qua |

Và trong test: `class _MockAuthRepository extends Mock implements AuthRepository {}`
(`login_cubit_test.dart` dòng 11). Ba chữ đứng cạnh nhau thì nghĩa là:

| Chữ | Lấy gì | Mấy cái |
|---|---|---|
| `extends` | Lấy **code** của lớp cha | Một |
| `with` | Lấy **code** của mixin | Nhiều |
| `implements` | Chỉ lấy **hợp đồng** (tên hàm), phải tự viết ruột (bài 13) | Nhiều |

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thấy 2 lỗi biên dịch (lượt 2, lượt 4)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What are mixins and extension methods?"
