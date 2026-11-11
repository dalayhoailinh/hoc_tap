# Bài 22: `final` và `const`

**Lõi một câu:** `final` là "biến này **gán một lần**", giá trị có thể tới lúc chạy mới biết, và ruột của nó vẫn sửa
được. `const` là "giá trị này **biết từ lúc biên dịch** và đóng băng luôn cả ruột"; hai `const` giống nhau là **cùng
một object** trong bộ nhớ.

## Đề

`bai22.dart`: mọi thứ trong `main`, không tách hàm, không package, khoảng 20 dòng.

Phải in ra đúng:

```
final sửa ruột: [A1, A2, A3]
const sửa ruột: Unsupported operation: Cannot add to an unmodifiable list
final nhận giá trị lúc chạy: true
hai list thường là một: false
hai list const là một: true
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1a | `var seats = 3;` rồi gán lại `seats = 4;`, in | `var gán lại được: 4` |
| 1b | Đổi `var` thành `final` | Không chạy được: `Error: Can't assign to the final variable 'seats'.` Xong thì **xoá** ba dòng này |
| 2 | `final codes = ['A1', 'A2'];` rồi `codes.add('A3');`, in | `final sửa ruột: [A1, A2, A3]` ← **`final` mà vẫn đổi được?** |
| 3a | `const fixed = ['A1', 'A2'];` rồi `fixed.add('A3');`, in | Dòng lượt 2, rồi **sập**: `Unsupported operation: Cannot add to an unmodifiable list` |
| 3b | Bọc lệnh `add` trong `try/catch`, in lỗi theo mẫu đề | 2 dòng đầu của đề |
| 4a | `const openedAt = DateTime.now();`, in năm | Không chạy được: `Error: Cannot invoke a non-'const' constructor where a const expression is expected.` |
| 4b | Đổi thành `final`, in `openedAt.year > 2000` theo mẫu đề | 3 dòng đầu của đề |
| 5 | Hai list **thường** cùng nội dung `x`, `y`: in `identical(x, y)`. Rồi in `identical(fixed, const ['A1', 'A2'])` | Đủ 5 dòng như đề |

Lượt 2 là chỗ hay hiểu sai nhất: `final` khoá **cái nhãn** (biến `codes` luôn trỏ tới đúng cái list đó), không khoá
**cái hộp** (list vẫn thêm bớt được).

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1b, 4a: lỗi lúc biên dịch

Hai lượt này **không in được dòng nào**, kể cả các dòng `print` phía trên chỗ sai: Dart đọc hết file, thấy sai là từ
chối chạy. Khác với lượt 3a: chương trình chạy, in được dòng đầu, tới đúng dòng `add` mới sập.

### Lượt 5: `identical`

```dart
final a = 'xin chào'.toUpperCase();
final b = 'xin chào'.toUpperCase();
print(a == b); // true: cùng nội dung
print(identical(a, b)); // false: hai chuỗi tạo ra lúc chạy, nằm hai chỗ
```

`identical(a, b)` hỏi "`a` và `b` có phải **cùng một object** trong bộ nhớ không". Viết `const ['A1', 'A2']` ở hai nơi
khác nhau trong chương trình, Dart chỉ tạo **một** list lúc biên dịch và dùng chung.

## Thử phá

1. Đổi `identical(fixed, const ['A1', 'A2'])` thành `identical(fixed, const ['A1', 'A3'])`. Khác nội dung thì là hai
   object. Trả lại.
2. Thêm hai dòng:
   `print(identical(Duration(seconds: 3), Duration(seconds: 3)));` và
   `print(identical(const Duration(seconds: 3), const Duration(seconds: 3)));`
   Ra `false` rồi `true`. Chữ `const` đứng trước một **lời gọi tạo object** cũng có nghĩa y vậy: tạo lúc biên dịch,
   dùng chung.

## Bắc cầu sang project

| Bài 22 | EH |
|---|---|
| `final` gán một lần | `app/lib/features/auth/presentation/view_models/login/login_cubit.dart` dòng 11: `final AuthRepository _repository;` (gán trong constructor, lúc chạy) |
| `const` trước lời gọi tạo object | Cùng file dòng 13, 16, 29: `const LoginState.idle()`, `const LoginState.submitting()` |
| Thử phá 2 | `verify_email_cubit.dart` dòng 18: `const Duration(seconds: 3)` |
| Giá trị chỉ biết lúc chạy | `seat_lock_remote_datasource.dart` dòng 147: `final expiresAt = DateTime.now().add(...)` |
| Hằng số cả app dùng | Cùng file dòng 12, 19: `const Duration kSeatHoldWhileSelecting = Duration(minutes: 1);` |

- **Vì sao Flutter rải `const` khắp nơi** (`const Text('Đăng nhập')`, `const SizedBox(height: 16)`): widget `const` là
  **cùng một object** qua mọi lần `build`. Flutter thấy "vẫn y cái object cũ" thì **không vẽ lại** nhánh đó. Bài 36
  cho bạn đếm số lần `build` để thấy.
- **Lớp muốn tạo được bằng `const`** thì constructor phải có chữ `const` và mọi field phải `final`. `DateTime.now()`
  không thể là `const` vì giá trị của nó tuỳ lúc chạy (lượt 4a).
- Thói quen của EH (và của linter): mặc định `final`; cái gì viết được `const` thì viết `const`; `var` chỉ khi thật
  sự phải gán lại.

## Xong khi

- [ ] In đúng 5 dòng như đề
- [ ] Đã thấy 2 lỗi biên dịch (1b, 4a) và 1 lần sập lúc chạy (3a), và nói được chúng khác nhau chỗ nào
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What's the difference between final and const?"
