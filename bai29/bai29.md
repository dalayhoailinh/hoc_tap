# Bài 29: Cubit tự viết, rồi Bloc

**Lõi một câu:** Cubit là một cái hộp giữ **state hiện tại** và có một **stream** báo mỗi lần state đổi; đổi state chỉ
bằng một cửa là `emit`, và `emit` bỏ qua state trùng. Bloc là Cubit mà bên ngoài không gọi hàm của nó nữa: họ **gửi
event** vào một cửa duy nhất (`add`), Bloc tự quyết event nào thì emit gì.

## Đề

`bai29.dart`: ba lớp nằm ngoài `main`, `main` chỉ gọi. Chỉ dùng `dart:async`, khoảng 50 dòng.

Bài toán: ô chọn **số lượng vé** ở trang chọn vé. Bắt đầu là 1, không xuống dưới 1.

Phải in ra đúng:

```
màn hình vẽ: 2
màn hình vẽ: 1
event: increment
màn hình vẽ: 2
event: decrement
màn hình vẽ: 1
event: decrement
event: increment
màn hình vẽ: 2
```

(Hai dòng đầu là Cubit: tăng, giảm, giảm. Phần còn lại là Bloc: ba event từ nút bấm, rồi một event từ server.)

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Không lớp nào: biến `quantity`, hàm `draw()` in `màn hình vẽ: ...`, hàm `increment()`. Tăng rồi `draw()`; tăng lần nữa và **cố ý quên** `draw()` | `màn hình vẽ: 2`, `(quên gọi draw)` ← **số đã là 3, màn hình vẫn 2** |
| 2 | Lớp `Cubit<S>`: field `state`, một `StreamController` broadcast, getter `stream`, hàm `emit(next)` gán state rồi `add` vào stream. Lớp `QuantityCubit extends Cubit<int>` có `increment()`. Màn hình `listen` một lần; tăng hai lần | `màn hình vẽ: 2`, `màn hình vẽ: 3` (không ai gọi `draw` nữa) |
| 3a | `decrement()` (không xuống dưới 1). Tăng, giảm, giảm | `2`, `1`, `1` ← **giảm ở 1 vẫn là 1 mà màn hình vẽ lại** |
| 3b | `emit`: state mới `==` state cũ thì thôi | `màn hình vẽ: 2`, `màn hình vẽ: 1` |
| 4 | Lớp `QuantityBloc extends Cubit<int>`: **không có** `increment`/`decrement`; chỉ có `add(event)`, in `event: ...` rồi mới quyết emit gì. Gửi `increment`, `decrement`, `decrement` | Thêm 5 dòng: ba dòng `event:`, hai dòng `màn hình vẽ` |
| 5 | Nguồn event không phải nút bấm: một `StreamController<String>` tên `server`; **nối** nó vào bloc bằng `server.stream.listen(bloc.add)`; `server.add('increment')` | Đủ 9 dòng như đề |

Lượt 1 là lý do mọi thư viện quản lý state tồn tại: dữ liệu đổi mà không ai báo màn hình. Lượt 3a là lý do `emit` so
`==` (bài 23).

Nhìn lượt 4: event `decrement` thứ hai **có** dòng `event:` nhưng **không có** dòng `màn hình vẽ`. Bloc nhận mọi
event, và ghi lại được hết, kể cả event không làm đổi gì.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: lớp có kiểu thay được (`<S>`)

```dart
class Hop<T> {
  Hop(this.ruot);
  T ruot;
}

class HopChu extends Hop<String> {
  HopChu() : super('rỗng'); // gọi constructor của lớp cha
}

void main() {
  print(HopChu().ruot); // rỗng
}
```

- `<T>`: "kiểu gì đó, người dùng lớp này sẽ nói sau". `Hop<String>` là hộp đựng chữ.
- `: super(...)` đưa giá trị ban đầu cho lớp cha.

Stream của Cubit (bài 5, bài 6 lượt 6a), thêm một chữ:

```dart
final _changes = StreamController<S>.broadcast(sync: true);
Stream<S> get stream => _changes.stream;
```

`sync: true` là "người nghe nhận **ngay** trong lúc `add`", để các dòng in ra đúng thứ tự bạn gọi. Không có nó thì
người nghe nhận sau khi `main` chạy xong (bài 24). Thư viện thật không dùng `sync: true`.

### Lượt 4: Bloc tí hon

`add` nhận một chuỗi; trong đó hai dòng `if (event == '...') emit(...)`. Dòng `print('event: $event')` đứng **đầu**
hàm, trước mọi `if`.

### Lượt 5: nối stream vào bloc

`server.stream.listen(bloc.add)`: mỗi tin của `server` được đưa thẳng cho `bloc.add`. Đưa **tên hàm**, không có `()`
(bài 16). `server` cũng tạo với `sync: true`.

## Thử phá

1. Bỏ `sync: true` ở cả hai nơi. Thứ tự output thành gì? Mọi dòng `event:` in trước, mọi dòng `màn hình vẽ` in sau.
   Đó là thứ tự **thật** trong app: emit xong, màn hình vẽ ở nhịp sau. Trả lại.
2. Trong `QuantityBloc.add`, sửa thẳng `state = state + 1;` thay cho `emit(state + 1)`. Màn hình có vẽ không? State
   đổi mà không qua `emit` thì không ai biết: quay về lượt 1. Vì vậy trong thư viện thật `state` **chỉ đọc được**.
   Trả lại.

## Bắc cầu sang project

| Bài 29 | `flutter_bloc` / EH |
|---|---|
| `Cubit<S>`: `state`, `stream`, `emit` | Lớp `Cubit` của thư viện. Bạn chỉ viết lớp con |
| `QuantityCubit` | `app/lib/features/auth/presentation/view_models/login/login_cubit.dart` dòng 10–13: `class LoginCubit extends Cubit<LoginState>`, `super(const LoginState.idle())` |
| `increment()` gọi `emit` | Dòng 15–18: `submit(...)` gọi `emit(const LoginState.submitting())` |
| Lượt 3b | Thư viện làm sẵn. `auth_bloc.dart` dòng 62: "Same state twice emits nothing" |
| `QuantityBloc.add(event)` | `app/lib/features/auth/presentation/view_models/auth_bloc.dart` dòng 15: `class AuthBloc extends Bloc<AuthEvent, AuthState>` |
| Hai dòng `if (event == ...)` | Dòng 23–26: `on<AuthStarted>(_onStarted); on<LogoutRequested>(...); on<_AuthUserChanged>(_onUserChanged);` |
| Event là chuỗi | Event là **lớp** (`auth_event.dart`): mang được dữ liệu, gõ sai tên là compiler bắt |
| Lượt 5: `server.stream.listen(bloc.add)` | Dòng 31–34: `_repository.watchCurrentUser().listen((user) => add(_AuthUserChanged(user)), ...)` |
| `print('event: ...')` | `BlocObserver.onEvent`, `onTransition`: một chỗ ghi lại mọi event của mọi Bloc |
| Màn hình `listen` | `BlocBuilder`, `BlocListener` (bài 31) |

**Khi nào Cubit, khi nào Bloc** (EH có 12 Cubit, 1 Bloc):

- **Cubit** khi người gọi là **màn hình của chính nó** và mỗi nút là một việc: form đăng nhập, đăng ký, quên mật
  khẩu. Ít code hơn, đọc thẳng.
- **Bloc** khi event đến từ **nhiều nguồn mà mình không điều khiển**, hoặc cần ghi lại/điều tiết từng event.
  `AuthBloc` là Bloc vì nguồn chính của nó là **stream user của Firebase** (đăng nhập ở tab khác, bị khoá tài khoản,
  token hết hạn), không phải nút bấm. `BookingPaymentBloc` cũng vậy: event đến từ timer đếm ngược và từ doc đơn.
- Câu trả lời ngắn: "Cubit by default; Bloc when state changes are driven by streams or I need a log of every event."

**Vì sao không `setState`:** `setState` nằm **trong widget**, nên logic dính vào màn hình: không dùng lại được ở
trang khác, và muốn thử phải dựng widget. Cubit là một lớp Dart thường: bài 30 thử nó không cần Flutter.
**So với Provider/Riverpod:** cùng mục đích (tách state khỏi widget, báo khi đổi). Bloc ép mọi thay đổi đi qua
`emit`/event nên dễ lần vết; Riverpod ít chữ hơn và kiểm lúc biên dịch tốt hơn. EH chọn Bloc và giữ tới khi ship.

## Xong khi

- [ ] In đúng 9 dòng như đề
- [ ] Đã thấy lượt 1 (màn hình cũ) và lượt 3a (vẽ thừa)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm hai câu trả lời: "Bloc vs Cubit: when do you use each?" và "Why BLoC
  over setState, Provider or Riverpod?"
