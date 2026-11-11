# Bài 30: thử một cubit

**Lõi một câu:** thử một cubit là: đưa cho nó một **repository giả** trả đúng thứ mình muốn, gọi một hàm của nó, **gom
mọi state nó phát ra** vào một danh sách, rồi so danh sách đó với danh sách mong đợi. Không màn hình, không Firebase,
không mạng.

Bài này ghép ba thứ đã có: `Cubit` của bài 29, cổng có bản giả của bài 13, hàm `check` của bài 8.

## Đề

`bai30.dart`: các lớp nằm ngoài `main`, hàm thử nằm trong `main`. Chỉ dùng `dart:async`, khoảng 70 dòng (trong đó lớp
`Cubit` chép nguyên từ bài 29).

`LoginCubit` có state là một chuỗi:
- ban đầu `idle`;
- gọi `submit(email, password)`: phát `submitting`, hỏi repository, rồi phát `idle` nếu vào được, hoặc
  `failed: <câu báo>` nếu không.

Phải in ra đúng:

```
OK   đăng nhập đúng thì đang gửi rồi về rỗi
OK   đăng nhập sai thì giữ câu báo của lỗi
2/2 ca đúng
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Chép lớp `Cubit` (bài 29). Hợp đồng `AuthRepository` có `login(email, password)` trả `Future<String?>` (`null` là vào được, còn lại là câu báo). `LoginCubit` nhận repository qua constructor, có `submit`. Bản giả `FakeRepository(result)` trả luôn `result`. Trong `main`: tạo cubit với bản giả trả `null`, `listen` in `state: ...`, gọi `submit` | `state: submitting`, `state: idle` |
| 2a | Hàm `blocTest(name, build, act, expect)`: `build()` ra cubit, gom state vào List, gọi `act(cubit)`, so với `expect`, in `OK`/`SAI`, đếm. Ca đầu: bản giả trả `null`, mong `['submitting', 'idle']` | `SAI … ra [submitting], mong [submitting, idle]` ← **thiếu một state** |
| 2b | `await` lời gọi `act(cubit)` | `SAI … ra [submitting, idle], mong [submitting, idle]` ← **hai danh sách y hệt mà vẫn SAI** |
| 2c | So hai danh sách bằng nội dung, không bằng `==` | `OK   đăng nhập đúng thì đang gửi rồi về rỗi`, `1/1 ca đúng` |
| 3 | Ca hai: bản giả trả `'Sai mật khẩu'`, mong `['submitting', 'failed: Sai mật khẩu']` | Đủ 3 dòng như đề |

Hai cái hỏng đều nằm ở **bộ thử**, không phải ở cubit:
- 2a: so sớm quá. `submit` chưa xong (bài 24, 25) mà đã đem danh sách ra so.
- 2b: `==` trên hai `List` hỏi "cùng một object không" (bài 23), không hỏi "cùng nội dung không".

Bộ thử viết sai thì cubit đúng cũng bị báo SAI, và tệ hơn: có ngày cubit sai lại được báo OK.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: nhận cổng qua constructor

```dart
class DatBan {
  DatBan(this._bep);
  final Bep _bep;
}
```

`LoginCubit` vừa nhận repository vừa đưa state ban đầu cho lớp cha:
`LoginCubit(this._repository) : super('idle');`

Bản giả là một lớp `implements AuthRepository` (bài 13), giữ sẵn câu trả lời:

```dart
class BepGia implements Bep {
  BepGia(this.mon);
  final String mon;

  @override
  Future<String> nau() async => mon;
}
```

### Lượt 2a: hàm nhận hàm

Bốn tham số của `blocTest`:

```dart
  Future<void> blocTest(
    String name,
    LoginCubit Function() build,
    Future<void> Function(LoginCubit cubit) act,
    List<String> expect,
  ) async {
```

- `build` là hàm **tạo** cubit (mỗi ca một cubit mới, không dính state của ca trước).
- `act` là hàm **làm một việc** với cubit.
- Gọi: `blocTest('tên ca', () => LoginCubit(...), (cubit) => cubit.submit('a@b.c', 'x'), [...])`.

Gom state: `final states = <String>[]; cubit.stream.listen(states.add);`

### Lượt 2c: so nội dung hai List

```dart
print(['a', 'b'] == ['a', 'b']); // false
print(['a', 'b'].join(', ') == ['a', 'b'].join(', ')); // true
```

## Thử phá

1. Trong `submit`, xoá dòng `emit('submitting')`. Cả hai ca `SAI`. Ca đầu ra danh sách **rỗng**: state ban đầu là
   `idle`, cuối cùng `emit('idle')` trùng nên bị bỏ (bài 29 lượt 3b). Người dùng bấm Đăng nhập và **không thấy gì xảy
   ra**. Test bắt được một lỗi mà nhìn code rất khó thấy. Trả lại.
2. Trong `submit`, đổi dòng cuối thành `emit('idle');` (nuốt lỗi). Ca nào `SAI`? Người dùng gõ sai mật khẩu mà app im
   lặng. Trả lại.

## Bắc cầu sang project

Mở `app/test/features/auth/presentation/login_cubit_test.dart` đặt cạnh file của bạn:

| Bài 30 | Code thật |
|---|---|
| `FakeRepository implements AuthRepository` | Dòng 11: `class _MockAuthRepository extends Mock implements AuthRepository {}` |
| `FakeRepository(null)` / `FakeRepository('Sai mật khẩu')` | Dòng 18–25, `stubLogin(result)`: `when(() => repository.loginWithEmail(...)).thenAnswer((_) async => result)` |
| `blocTest(name, build, act, expect)` | Dòng 27–33: `blocTest<LoginCubit, LoginState>('…', setUp: …, build: …, act: …, expect: …)`. Cùng tên, cùng bốn phần |
| `build: () => LoginCubit(FakeRepository(...))` | Dòng 30: `build: () => LoginCubit(repository)` |
| `act: (cubit) => cubit.submit(...)` | Dòng 31 |
| `['submitting', 'idle']` | Dòng 32: `const [LoginState.submitting(), LoginState.idle()]` |
| Ca hai | Dòng 35–44: `LoginState.failed('Sai mật khẩu')` |
| `await act`, so nội dung, in OK/SAI, đếm | **Không có dòng nào.** Gói `bloc_test` làm hết |
| State là chuỗi | State là lớp `freezed` có `==` theo nội dung (bài 23), nên so thẳng được |

- **Lõi:** bản giả → gọi → danh sách state.
- **Vỏ:** `mocktail` (viết hộ ruột bản giả: `when(...).thenAnswer(...)`), `bloc_test`, `setUp` chạy trước mỗi ca
  (bài 26 lượt 4: `late repository`).
- **`mocktail` làm thêm một việc bản giả tự viết không có:** `verify(() => repository.loginWithEmail(...)).called(1)`:
  hỏi lại "hàm này đã được gọi mấy lần, với tham số gì".
- **Vì sao test này chạy trong vài mili-giây và chạy được trên CI không có Firebase:** `LoginCubit` chỉ biết hợp đồng
  `AuthRepository` (`login_cubit.dart` dòng 11–13). Nó không import `firebase_auth`. Đó là lý do có tầng repository.
- Chạy thật: `cd app` rồi `flutter test test/features/auth/presentation/login_cubit_test.dart`. Bốn ca.
- **Vì sao Bloc dễ thử hơn `setState`:** mọi thứ bạn vừa làm không cần một widget nào. Logic trong `setState` thì
  phải dựng màn hình, bấm nút, tìm chữ (bài 41).

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thấy 2a (thiếu state) và 2b (giống hệt mà SAI)
- [ ] Đã thử phá cả 2 cách
- [ ] Mở `login_cubit_test.dart`, chỉ ra được `build`, `act`, `expect` của ca đầu
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do you test a Cubit? Show one test from your project."
