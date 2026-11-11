# Bài 33 (thí nghiệm Flutter): ba cái cây, và `context` là ai

**Lõi một câu:** **Widget** là bản mô tả, rẻ, bị tạo mới mỗi lần `build`. **Element** là "chỗ đứng" của widget trên
cây: sống lâu, giữ State, và nối widget với **RenderObject** là thứ thật sự đo kích thước và vẽ. `BuildContext`
**chính là Element**: nó là vị trí của bạn trên cây, nên `X.of(context)` nghĩa là "từ chỗ tôi đứng, **đi ngược lên**
tìm X".

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai33
flutter create --empty --platforms=windows app
cd app
flutter pub add flutter_bloc
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Bài này có hai màn riêng: lượt 1–2 một file, lượt 3–5 thay file khác.

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ A** bên dưới. Trong `build` của `_ProbeState`: so `widget` và `context` lần này với lần trước bằng `identical`, in ra | Bấm **Vẽ lại**: `widget mới: true`, `context mới: false` |
| 2 | Hàm `_inspect()` in 4 dòng (gợi ý bên dưới), gọi một lần sau khung hình đầu | Mở app: `context là Element: true`, `Element giữ widget này: true`, `RenderObject: RenderParagraph`, `có kích thước: true` |
| 3 | **Vỏ B** bên dưới: nút gọi `Scaffold.of(context).openDrawer()` | Bấm **Mở ngăn kéo**: không mở; terminal đỏ: `Scaffold.of() called with a context that does not contain a Scaffold.` |
| 4 | Bọc nút trong `Builder`, dùng `context` **của Builder** | Bấm: ngăn kéo mở, thấy chữ `Ngăn kéo` |
| 5 | Cùng lỗi, thư viện khác: **vỏ C**, `BlocProvider` và `context.read` nằm chung một `build` | Bấm **Đọc cubit**: `Error: Could not find the correct Provider<PaymentCubit> above this HomePage Widget` |

Lượt 1 là điều đáng nhớ nhất: mỗi lần cha vẽ lại, object `Probe` là **một object mới**, còn `context` (Element) thì
**vẫn là cái cũ**. State bám vào Element, nên nó sống qua được (bài 32 lượt 4).

Lượt 3 và lượt 5 là một lỗi: `context` bạn đang cầm là của `HomePage`, mà `HomePage` đứng **trên** cái `Scaffold`
(hay `BlocProvider`) do chính nó tạo ra. Đi ngược lên từ đó thì không bao giờ gặp.

## Từng lượt

### Vỏ A (lượt 1–2)

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _redraws = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Probe(label: 'lần $_redraws'),
          TextButton(
            onPressed: () => setState(() => _redraws++),
            child: const Text('Vẽ lại'),
          ),
        ],
      ),
    );
  }
}

class Probe extends StatefulWidget {
  const Probe({super.key, required this.label});
  final String label;

  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  Probe? _lastWidget;
  BuildContext? _lastContext;

  @override
  Widget build(BuildContext context) {
    // lõi lượt 1
    return Text('Đang soi (${widget.label})');
  }
}
```

Lượt 1, tự viết: nếu đã có `_lastWidget` thì in hai dòng so sánh (`identical`, bài 22), rồi cập nhật `_lastWidget`,
`_lastContext`.

Lượt 2, bốn thứ để in trong `_inspect()`:

| In | Biểu thức |
|---|---|
| `context là Element` | `context is Element` |
| `Element giữ widget này` | `(context as Element).widget == widget` |
| `RenderObject` | `context.findRenderObject().runtimeType` |
| `có kích thước` | `context.size != null` |

Gọi sau khung hình đầu (lúc `build` đang chạy thì chưa có kích thước):

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inspect());
  }
```

Widget `Text` của bạn **không có** `size`. Thứ biết kích thước là `RenderParagraph`, và đường tới nó đi qua
`context`.

### Vỏ B (lượt 3–4)

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(child: Text('Ngăn kéo')),
      body: TextButton(
        onPressed: () => Scaffold.of(context).openDrawer(),
        child: const Text('Mở ngăn kéo'),
      ),
    );
  }
}
```

Lượt 4: `Builder` là một widget không vẽ gì, chỉ để **có một `context` mới nằm bên dưới**:

```dart
Builder(
  builder: (inner) {
    return Text('${Theme.of(inner).brightness}');
  },
)
```

Đặt tên tham số là `inner` để khỏi nhầm với `context` bên ngoài. Cách thứ hai, hay dùng hơn trong app thật: **tách
cái nút ra một widget riêng**; `build` của widget đó tự có `context` nằm dưới `Scaffold`.

### Vỏ C (lượt 5)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentCubit extends Cubit<String> {
  PaymentCubit() : super('đang chờ');
}

void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentCubit(),
      child: Scaffold(
        body: TextButton(
          onPressed: () => debugPrint(context.read<PaymentCubit>().state),
          child: const Text('Đọc cubit'),
        ),
      ),
    );
  }
}
```

Tự sửa bằng một trong hai cách của lượt 4. Sửa xong bấm nút phải in `đang chờ`.

## Thử phá

1. Ở vỏ A, cho `Probe` có `const` và **không** tham số (`const Probe()`, bỏ `label`). Bấm Vẽ lại: hai dòng so sánh
   **không in nữa**. Widget `const` là cùng một object (bài 22); Flutter thấy "y cái cũ" nên **không gọi `build`**
   của nó. Đây là cách rẻ nhất để chặn vẽ lại thừa (bài 36). Trả lại.
2. Ở vỏ B bản đã sửa, đổi `Scaffold.of(inner)` về `Scaffold.of(context)`. Lỗi quay lại dù `Builder` vẫn còn. Cái
   quyết định là bạn **cầm `context` nào**, không phải có `Builder` hay không.

## Bắc cầu sang project

| Bài 33 | EH |
|---|---|
| `X.of(context)` đi ngược lên | `app/lib/core/utils/extensions.dart` dòng 49–55: `Theme.of(this)`, `MediaQuery.of(this)`, gói lại thành `context.colorScheme`, `context.screenWidth` |
| `context.read<T>()` | `booking_payment_page_web.dart`: `BlocProvider` ở dòng 23, các widget con (`_PaymentCard`…) là **lớp riêng** nên `context` của chúng nằm dưới provider |
| Lỗi lượt 5 | Lỗi "thiếu `BlocProvider`" hay gặp nhất khi thêm trang mới: provider đặt trong `build` của chính trang đó rồi dùng `context` của trang |
| Tách widget để có `context` bên dưới | Lý do các trang EH có nhiều lớp con `_PaymentCard`, `_Header`… chứ không chỉ để gọn |
| Element giữ State | Bài 32 lượt 4; bài 34 (Key là cách bảo Flutter "Element nào khớp với widget nào") |
| RenderObject | Bài 35 (constraints), lỗi tràn `RenderFlex overflowed` |

- **Vì sao tách ba cây:** bạn viết lại cả cây widget mỗi lần `build` (đơn giản, khai báo "màn hình trông thế này").
  Flutter so cây mới với cây cũ qua Element và **chỉ đụng tới những RenderObject thật sự đổi**. Widget rẻ nên tạo
  lại thoải mái; RenderObject đắt nên giữ lại.
- **`context` sau `await`:** `context` là một Element; trang đóng thì Element đó chết. Vì vậy mới có
  `if (!context.mounted) return;` (bài 31, 32).
- Sổ học của bạn có mục "`BootPage`, `_SessionGate`": `_SessionGate` (`app/lib/main.dart` dòng 160) đứng **trên**
  `MaterialApp.router` chính là để mọi trang bên dưới đều "đi ngược lên" gặp được `AuthBloc`.

## Xong khi

- [ ] Thấy đủ 5 "Chạy thấy"
- [ ] Sửa được vỏ C để in `đang chờ`
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm hai câu trả lời: "Widget, Element, RenderObject: what is each?" và
  "What is BuildContext?"
