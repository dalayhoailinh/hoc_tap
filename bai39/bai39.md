# Bài 39 (thí nghiệm Flutter): `r` và `R`

**Lõi một câu:** **hot reload** (`r`) thay code mới vào app **đang chạy**, giữ nguyên mọi State, rồi chỉ gọi lại
`build`: nó **không** chạy lại `main`, `initState`, hay giá trị khởi tạo của biến. **Hot restart** (`R`) vứt hết
State và chạy lại app từ `main`.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai39
flutter create --empty --platforms=windows app
cd app
flutter run -d windows
```

Bài này bạn **không viết code mới**. Bạn gõ vỏ một lần, rồi mỗi lượt **sửa một chỗ nhỏ**, lưu, bấm `r` hoặc `R` ở
terminal, và nhìn dòng in.

## Vỏ

`lib/main.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  debugPrint('main chạy');
  runApp(const MaterialApp(home: ClockPage()));
}

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  var _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    debugPrint('initState');
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _count++),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build: Bản 1, đếm $_count');
    return Scaffold(body: Center(child: Text('Bản 1 · đếm: $_count')));
  }
}
```

Một bộ đếm tự tăng mỗi giây (khỏi phải bấm). `_count` là State; nhìn nó để biết State còn sống hay đã bị làm lại.

## Các lượt

Mở app, đợi vài giây cho số đếm lên. Terminal lúc đầu: `main chạy`, `initState`, `build: Bản 1, đếm 0`, rồi mỗi giây
một dòng `build`.

| Lượt | Sửa gì, bấm gì | Chạy thấy |
|---|---|---|
| 1 | Trong `build`: đổi cả hai chữ `Bản 1` thành `Bản 2`. Lưu, bấm **`r`** | `build: Bản 2, đếm 3` (số đang đếm tới đâu thì **tiếp tục** từ đó), rồi `Reloaded 1 of … libraries in …ms`. Không có `main chạy`, không có `initState` |
| 2 | Đổi `var _count = 0;` thành `var _count = 100;`. Lưu, bấm **`r`** | Số **vẫn đếm tiếp** 6, 7, 8… ← **sửa rồi mà "không ăn"** |
| 3 | Đổi `debugPrint('initState');` thành `debugPrint('initState (đã sửa)');`. Lưu, bấm **`r`** | Không có dòng `initState` nào in ra. Số vẫn đếm tiếp |
| 4 | Không sửa gì. Bấm **`R`** | `Restarted application in …ms.`, rồi `main chạy`, `initState (đã sửa)`, `build: Bản 2, đếm 100` |

Lượt 2 và 3 không phải lỗi của Flutter. Code mới **đã** được nạp. Nhưng:
- `var _count = 100` là giá trị **lúc tạo** State. State đã được tạo từ trước, đang giữ số 8; không ai tạo nó lại.
- `initState` chỉ chạy **một lần** lúc State sinh ra (bài 32). Nó đã chạy rồi.

Lượt 4: `R` vứt State cũ, chạy lại `main` → State mới → mọi thứ bạn sửa ở lượt 2, 3 giờ mới có tác dụng.

## Khi nào `r` không đủ

| Bạn vừa sửa | `r` có thấy không | Vì sao |
|---|---|---|
| Thứ nằm trong `build` (chữ, màu, bố cục) | Có | `r` gọi lại `build` |
| Ruột một hàm sẽ được gọi lần sau (hàm của nút bấm) | Có, từ lần gọi sau | Code mới đã nạp |
| Giá trị khởi tạo của field trong State; code trong `initState` | Không | State đang sống không được tạo lại |
| `main()`; biến toàn cục; đăng ký phụ thuộc (get_it); bảng route | Không | Chỉ chạy một lần lúc mở app |
| Thêm/bớt field của một lớp, đổi `enum`, đổi kiểu generic | Thường phải `R` | Hình dạng object trong bộ nhớ đã khác |
| Code native (Kotlin, Swift, C++), thêm package có phần native, `pubspec.yaml`, asset mới | Cả `R` cũng không | Phải dừng hẳn rồi `flutter run` lại |

## Thử phá

1. Sau lượt 4, sửa `Duration(seconds: 1)` thành `Duration(milliseconds: 200)`, bấm `r`. Đồng hồ có nhanh lên không?
   Không: cái `Timer` đang chạy được tạo trong `initState` với nhịp cũ. Bấm `R` mới nhanh.
2. Gõ sai cú pháp (xoá một dấu `;`), lưu, bấm `r`. Terminal báo lỗi biên dịch và **app vẫn chạy bản cũ**, số vẫn đếm.
   Reload hỏng không làm chết app.

## Bắc cầu sang project

- **Bẫy đã ghi trong kế hoạch của EH** (`05_sua_v1.md`, mục "Bẫy đã biết"): "DI, route, `main.dart` không nạp nóng
  được: phải Hot Restart mới thấy". Giờ bạn biết vì sao: `configureDependencies()` (đăng ký get_it/injectable) và
  `GoRouter(...)` đều chạy **một lần** lúc mở app, như `main chạy` của bạn.
- **Bài 6, 12, 17, 21** đều dặn bấm `R`: các bài đó hay sửa `main`, lớp `Auth`, biến toàn cục `auth`.
- **Bloc cũng là State sống lâu:** sửa giá trị ban đầu trong `super(const LoginState.idle())` rồi `r` thì cubit đang
  sống vẫn giữ state cũ. `AuthBloc` là singleton (`@lazySingleton`) nên càng chắc chắn phải `R`.
- **Vì sao làm được hot reload:** bản debug chạy code Dart trên máy ảo, máy ảo cho phép **thay ruột lớp và hàm** trong
  lúc chạy. Bản release biên dịch thẳng ra mã máy nên không có `r`. Dòng `Reloaded 1 of 754 libraries` nghĩa là chỉ
  file bạn sửa bị thay.
- Trong VS Code: lưu file là tự `r` (biểu tượng tia sét); `Ctrl+Shift+F5` là `R`.

## Xong khi

- [ ] Thấy lượt 1 (số đếm tiếp tục) và lượt 2, 3 (sửa mà không ăn)
- [ ] Lượt 4: `main chạy`, `initState (đã sửa)`, đếm từ 100
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Hot reload vs hot restart"
