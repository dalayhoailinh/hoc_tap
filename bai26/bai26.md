# Bài 26: có thể không có

**Lõi một câu:** kiểu có dấu `?` nghĩa là "**có thể không có gì**", và Dart **bắt** bạn xử lý ca đó ngay lúc biên dịch
(`??`, `?.`, hoặc kiểm `!= null`). `!` và `late` là hai cách nói "tin tôi đi, có đấy": compiler thôi kiểm, và nếu bạn
sai thì app **sập lúc chạy**. `required` là chiều ngược lại: bắt **người gọi** phải đưa.

Bạn đã dùng `?`, `!`, `??`, `?.` lẻ tẻ từ bài 3. Bài này xếp chúng cạnh nhau.

## Đề

`bai26.dart`: mọi thứ trong `main`, hai hàm nhỏ trong `main`, không package, khoảng 33 dòng.

Sổ tên: `{'an': 'An'}`. Không có `binh`.

Phải in ra đúng:

```
tên: khách
độ dài: null
sau khi kiểm: 2
!: Null check operator used on a null value
late: LateInitializationError: Local 'token' has not been initialized.
late sau khi gán: abc
đặt vé cho an@eh.test, sđt: chưa có
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1a | Sổ `names`. `String name = names['binh'];`, in | Không chạy được: `Error: A value of type 'String?' can't be assigned to a variable of type 'String'.` |
| 1b | Đổi kiểu thành `String?` | `tên: null` |
| 2a | In thêm `name.length` | Không chạy được: `Error: Property 'length' cannot be accessed on 'String?' because it is potentially null.` |
| 2b | Ba cách xử lý: in tên với `?? 'khách'`; in độ dài với `?.`; gán lại `name = names['an'];` rồi `if (name != null)` mới in `name.length` | 3 dòng đầu của đề |
| 3a | In `names['binh']!.length` | 3 dòng đầu, rồi **sập**: `Null check operator used on a null value` |
| 3b | Bọc `try/catch`, in lỗi theo mẫu | 4 dòng đầu của đề |
| 4 | `late String token;` và một hàm `setUp()` gán `token = 'abc'`. Đọc `token` **trước** khi gọi `setUp()` (trong `try/catch`), rồi gọi `setUp()` và đọc lại | Thêm hai dòng `late: ...` |
| 5 | Hàm `book({required String email, String? phone})` trả câu theo mẫu. Gọi chỉ với `email` | Đủ 7 dòng như đề |

Lượt 1a và 2a là Dart **cứu** bạn: hai lỗi đó ở ngôn ngữ khác chỉ lộ ra khi người dùng thật gặp. Lượt 3a và lượt 4
là bạn **tắt** cái lưới đó đi.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2b: sau khi kiểm thì Dart tự hiểu

```dart
int? tuoi = int.tryParse('abc'); // null
print(tuoi ?? 0); // 0
print(tuoi?.isEven); // null: không gọi, không lỗi
tuoi = int.tryParse('20');
if (tuoi != null) print(tuoi + 1); // 21: trong if, tuoi là int
```

Sau `if (x != null)`, trong khối đó Dart coi `x` là kiểu **không có `?`**. Gọi là "thăng kiểu" (type promotion). Bạn
đã dùng nó ở bài 7 lượt 5 mà chưa gọi tên.

### Lượt 4: `late`

```dart
late String ten;
void napTen() {
  ten = 'Chi';
}
napTen();
print(ten); // Chi
```

`late` là "biến này **không null**, nhưng tôi sẽ gán **sau**, trước khi ai đọc". Đọc trước khi gán thì sập. (Nếu gán
ngay trong `main` thay vì trong một hàm khác, Dart đủ thông minh để thấy "chắc chắn chưa gán" và báo lỗi biên dịch
luôn. Gán trong hàm khác thì nó chịu, không đoán được lúc nào hàm đó chạy.)

### Lượt 5: tham số có tên

```dart
String chao({required String ten, int? tuoi}) => 'chào $ten ${tuoi ?? ''}';
print(chao(ten: 'Chi'));
```

Tham số trong `{}` gọi bằng tên. Mặc định chúng **không bắt buộc**, nên kiểu phải có `?` (hoặc có giá trị mặc định).
Thêm `required` thì bắt buộc và không cần `?`.

## Thử phá

1. Gọi `book(phone: '0901')`, bỏ `email`. Chạy được không? `required` thiếu là lỗi **biên dịch**:
   `Error: Required named parameter 'email' must be provided.` Trả lại.
2. Đổi `!` ở lượt 3 thành dùng với `names['an']`. Hết sập. `!` không sai; nó chỉ **dời trách nhiệm** từ compiler
   sang bạn. Mỗi dấu `!` là một lời hứa bạn phải tự giữ.

## Bắc cầu sang project

| Bài 26 | EH |
|---|---|
| `?` + kiểm rồi mới dùng | `seat_lock_remote_datasource.dart` dòng 98–104: `final user = _auth.currentUser; if (user == null) { throw ... } return user.uid;` |
| `??` | Cùng file dòng 118–119: `(map['status'] ?? '') as String` |
| `?.` | `login_cubit.dart` không cần; `app_router.dart` dòng 30–33: `auth.user?.id` |
| `!` | `booking_remote_datasource.dart` dòng 116–117: `eventSnap.data()!`. Hứa được vì dòng 103 đã kiểm `!eventSnap.exists` và thoát |
| `late` gán ở hàm khác | `app/test/features/auth/presentation/login_cubit_test.dart` dòng 14–16: `late _MockAuthRepository repository;` rồi `setUp(() => repository = _MockAuthRepository());`. Đúng y lượt 4 |
| `required` | Gần như mọi constructor: `booking_payment_bloc.dart` dòng 31–36, `required FirebaseFirestore firestore, ...` |

- **Lõi:** `String` và `String?` là **hai kiểu khác nhau**. Compiler không cho đi từ `String?` sang `String` nếu bạn
  chưa xử lý ca null.
- **Thứ tự nên dùng**, từ an toàn tới liều: kiểm `!= null` (hoặc `??`, `?.`) → `late` → `!`. Thấy `!` trong code
  review thì hỏi "dòng nào bảo đảm cái này không null?". Trả lời được (như dòng 103 ở trên) thì giữ.
- **`late` trong Flutter** hay gặp ở `State`: `late final AnimationController _controller;` gán trong `initState`.
  Framework bảo đảm `initState` chạy trước `build`, nên lời hứa giữ được.
- **TypeScript ở server cũng có ý này** với tên khác: `string | undefined`, `?.`, `??`, và dấu `!` y hệt. Trong guide
  gd3: `detailSnap.get("ticketTypes")`, `data.maxBookingsPerUser ?? data.maxTicketsPerUser ?? DEFAULT...`.

## Xong khi

- [ ] In đúng 7 dòng như đề
- [ ] Đã thấy 2 lỗi biên dịch (1a, 2a) và 2 lần hỏng lúc chạy (3a, lượt 4)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Explain null safety: ?, !, late, required."
