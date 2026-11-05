# Bài 4: token là cái vé

**Lõi một câu:** đăng nhập đúng thì server phát một **token** (chuỗi ngẫu nhiên, không đoán được) và **ghi sổ** "vé
này của ai, hết hạn lúc nào". Từ đó mỗi lần gọi chỉ cần đưa vé: server tra sổ, không thấy hoặc hết hạn là **401**
(không biết bạn là ai), thấy mà role không đủ là **403** (biết bạn là ai, nhưng không cho).

## Đề

`bai4.dart`: mọi thứ trong `main`, được dùng hàm nhỏ trong `main` như bài 2–3, không package, khoảng 30 dòng.

- An: mật khẩu `123`, role `admin`. Bình: mật khẩu `456`, role `user`.
- Token sống 30 phút. Đồng hồ là **giờ giả**, bắt đầu lúc 8:00, tự tua được (không phải ngồi đợi).

Dòng thời gian:
1. An gõ sai mật khẩu.
2. An và Bình đăng nhập đúng.
3. An, Bình và một kẻ lạ (gửi token bịa `abc`) cùng mở trang quản trị.
4. Tua tới 8:31, An mở lại trang quản trị.

Phải in ra đúng:

```
An gõ sai: null
An: 200, Bình: 403, Lạ: 401
8:31, An: 401
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Map mật khẩu (tên → mật khẩu). Hàm `login(name, password)` trả `true`/`false`. Gọi An gõ sai, An gõ đúng | `An gõ sai: false` và `An gõ đúng: true` |
| 2 | Đúng mật khẩu thì `login` trả **token** (số ngẫu nhiên viết hệ 16) và ghi vào sổ `owner` (token → tên). Sai thì trả `null` | `An gõ sai: null`, token của An **mỗi lần chạy một khác** |
| 3 | Hàm `adminPage(token)`: tra sổ, không thấy → `'401'`, thấy → `'200'`. Gọi bằng token của An và bằng `'abc'` | `An: 200, Lạ: 401` |
| 4 | Map role. Thấy token nhưng role không phải `admin` → `'403'`. Thêm Bình đăng nhập và mở trang | `An: 200, Bình: 403, Lạ: 401` |
| 5 | Giờ giả `now` + sổ `expiry` (token → hết hạn lúc). `login` ghi hạn = `now` + 30 phút. `adminPage` thấy quá hạn → `'401'`. Tua `now` thêm 31 phút, gọi lại An | Đủ 3 dòng như đề |

Lượt 2 là chỗ quan trọng nhất: server **nhớ** token nó phát ra. Không có sổ thì token chỉ là một chuỗi vô nghĩa,
server nhìn nó cũng không biết của ai.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: số ngẫu nhiên khó đoán

```dart
import 'dart:math'; // dòng đầu file, ngoài main

final r = Random.secure();
print(r.nextInt(100)); // 0..99, mỗi lần chạy một khác
print(r.nextInt(1 << 32).toRadixString(16)); // số tới ~4 tỉ, viết hệ 16: 6eca77e7
```

- `Random.secure()` cho số khó đoán, dùng cho token, mật khẩu. `Random()` thường đủ cho game, không đủ cho token.
- `1 << 32` là 2^32 (khoảng 4 tỉ), số lớn nhất `nextInt` nhận.
- Hàm trả "có thể không có gì" thì kiểu là `String?` và trả `null`, giống bài 3.

### Lượt 3: tra Map mà không có

```dart
final prices = {'phở': 50, 'bún': 40};
print(prices['phở']); // 50
print(prices['cơm']); // null: không có thì ra null, không báo lỗi
```

- `login` trả `String?`, nên `adminPage` cũng nhận `String?`.

### Lượt 5: giờ giả

```dart
var now = DateTime(2026, 11, 5, 9, 0); // 9:00
final closeAt = now.add(Duration(hours: 2)); // 11:00
now = now.add(Duration(hours: 3)); // tua tới 12:00
print(now.isAfter(closeAt)); // true: quá giờ đóng cửa
```

- Giờ là một biến thì tua được. Dùng `DateTime.now()` thì phải ngồi đợi 30 phút thật.
- `expiry[token]!`: tra Map ra kiểu có thể null, dấu `!` là lời hứa "chắc chắn có". Hứa được vì vế trước đã kiểm
  `name == null` (có tên thì chắc chắn có hạn). Hứa sai thì chương trình sập.

## Thử phá

1. Cho token là chính tên người dùng (`final token = name;`), rồi đổi token của kẻ lạ từ `'abc'` thành `'An'`. Kẻ lạ
   ra mấy? Số ngẫu nhiên ở lượt 2 là để chống đúng chuyện này.
2. Trả lại như cũ, xoá dòng kiểm role. Bình ra mấy? Token chỉ trả lời "**bạn là ai**"; "**được làm gì**" là một bước
   kiểm riêng.
3. Trả lại như cũ, bỏ phần kiểm hạn. 8:31 An ra mấy? Token lộ một lần thì kẻ cắp dùng được mãi.

## Bắc cầu sang project

- Firebase khác bài này đúng một chỗ: **không có sổ**. ID token của Firebase (dạng JWT) tự mang `uid`, role (custom
  claims), giờ hết hạn (1 giờ), kèm một **chữ ký** chỉ server làm ra được. Server kiểm chữ ký thay vì tra sổ, giống
  vé xem phim có dấu mộc: soát vé nhìn dấu là biết vé thật, không cần gọi về quầy.
- EH `functions/src/auth/completeSignUp.ts` dòng 11–12: `request.auth` rỗng thì ném `unauthenticated`. Đó là `'401'`
  của bạn; Firebase đã kiểm token hộ trước khi gọi hàm.
- EH `firestore.rules` dòng 4–14: `isSignedIn()` là "có token còn hạn" (401); `isAdmin()` đọc
  `request.auth.token.role`, tức role nằm **ngay trong token** (403).

Tự trả lời: trong EH, dòng nào làm phần sổ `owner` + `expiry` của bài này? (Gợi ý: đọc lại gạch đầu tiên.)

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thử phá cả 3 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What's the difference between 401 and 403?"
