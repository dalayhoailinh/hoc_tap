# Bài 5: app nghe user đổi, không đi hỏi

**Lõi một câu:** app không đi hỏi "ai đang đăng nhập"; nó **nghe một stream user**. Mỗi lần user đổi (đăng nhập, đổi
role, đăng xuất) stream báo giá trị mới, và app chọn lại màn hình theo đúng giá trị đó.

## Đề

`bai5.dart`: mọi thứ trong `main`, không package (`dart:async` có sẵn trong Dart, được dùng), dưới 30 dòng.

User là một Map, ví dụ `{'name': 'Bình', 'role': 'user'}`; chưa ai đăng nhập thì là `null`.

Dòng thời gian, mỗi bước là một lần stream báo user mới:
1. Mở app: chưa ai đăng nhập.
2. Bình đăng nhập, role `user`.
3. Admin nâng Bình lên `admin`, app của Bình tải lại user.
4. Bình đăng xuất.

Phải in ra đúng (dòng "ai đăng nhập" lùi 3 dấu cách):

```
-> Màn đăng nhập
   ai đăng nhập: null
-> Trang chủ (Bình)
   ai đăng nhập: Bình
-> Trang quản trị (Bình)
-> Màn đăng nhập
   ai đăng nhập: null
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | `StreamController` broadcast tên `userChanges`. Một người nghe in thẳng giá trị nhận được. `add` 4 lần theo dòng thời gian | `null`, `{name: Bình, role: user}`, `{name: Bình, role: admin}`, `null` |
| 2 | Người nghe chọn màn: `null` → Màn đăng nhập; role `admin` → Trang quản trị; còn lại → Trang chủ | 4 dòng `-> ...` |
| 3 | Người nghe thứ hai chỉ quan tâm **ai** đăng nhập: `map` lấy tên, `distinct` bỏ giá trị trùng lần trước | Đủ 7 dòng như đề |

Nhìn kỹ lượt 3: lúc Bình lên admin, dòng "ai đăng nhập" **không** in. Người vẫn là Bình, chỉ role đổi. Hai người nghe
này chính là hai stream của Firebase: `userChanges()` báo **mọi lần** user đổi, `authStateChanges()` chỉ báo khi
**người** đăng nhập đổi.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: StreamController

```dart
import 'dart:async'; // dòng đầu file

final temps = StreamController<int>.broadcast();
temps.stream.listen((t) => print('Nhận: $t độ'));
temps.add(30);
temps.add(31);
// Nhận: 30 độ
// Nhận: 31 độ
```

- `StreamController` như cái loa: `add` là nói, `listen` là đăng ký nghe. Mỗi lần `add`, mọi người đang nghe đều nhận.
- `.broadcast()` cho nhiều người cùng nghe. Lượt 3 cần hai người.
- Kiểu của user: `Map<String, String>?`, dấu `?` vì "chưa ai đăng nhập" là `null`.
- Để ý: thêm `print('hết main')` ở cuối `main` thì dòng đó in **trước** mọi dòng "Nhận". `add` chỉ gửi đi; người nghe
  nhận sau khi `main` chạy xong phần của nó.

### Lượt 2: chọn màn

- `if / else if / else` như bài 1, lấy role bằng `user['role']`.
- Phải kiểm `user == null` **trước**: lấy `['role']` của `null` là lỗi.

### Lượt 3: map và distinct

```dart
temps.stream.map((t) => t >= 30 ? 'nóng' : 'mát').distinct().listen(print);
temps.add(31);
temps.add(33);
temps.add(25);
// nóng
// mát   <- 33 cũng "nóng", trùng lần trước nên distinct bỏ
```

- `map` đổi mỗi giá trị thành thứ khác, giống `map` của List.
- `distinct()`: giá trị mới **y hệt** giá trị vừa rồi thì bỏ, không báo.
- Lấy tên từ user có thể `null`: `user?['name']` (user `null` thì ra `null`, không lỗi).

## Thử phá

1. Bỏ `.broadcast()`. Chạy: `Bad state: Stream has already been listened to.` Stream thường chỉ cho **một** người
   nghe. User thì cả app cùng nghe (màn hình, router, giỏ hàng...), nên phải broadcast.
2. Trả lại như cũ. Dời khối `listen` thứ nhất xuống **dưới** dòng `add` đầu tiên. Mất dòng nào? Người nghe đến muộn
   không biết giá trị trước đó. Firebase tránh chuyện này bằng cách báo ngay user hiện tại cho mỗi người mới nghe;
   stream tự làm thì không.

## Bắc cầu sang project

- EH `app/lib/features/auth/data/datasources/auth_remote_datasource.dart` dòng 74: `firebaseAuth.userChanges()` chính
  là `userChanges.stream` của bạn.
- EH `app/lib/core/routes/app_router.dart` dòng 30–33: `_authBloc.stream.map((auth) => auth.user?.id).distinct()` y
  hệt người nghe thứ hai ở lượt 3: chỉ khi **người** đổi mới điều hướng lại.
- EH `app/lib/core/routes/route_policy.dart`: `homeFor(role)` (dòng 22) và `decideRedirect(user: ...)` (dòng 32) là
  khối `if/else` lượt 2 của bạn (null → đăng nhập, theo role → trang của role), cộng thêm phần URL.

## Xong khi

- [ ] In đúng 7 dòng như đề
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Future vs Stream: when do you use each?" (gợi ý: đăng
  nhập trả kết quả mấy lần? user đổi mấy lần?)
