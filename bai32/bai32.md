# Bài 32 (thí nghiệm Flutter): một State sống thế nào

**Lõi một câu:** `StatefulWidget` có một object `State` **sống lâu hơn** chính widget đó: sinh ra một lần
(`initState`), được vẽ nhiều lần (`build`), được báo khi cha đưa tham số mới (`didUpdateWidget`), và chết một lần
(`dispose`). `setState` không vẽ gì cả: nó chỉ **đánh dấu "tôi cần vẽ lại"**, Flutter gọi `build` ở khung hình kế.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai32
flutter create --empty --platforms=windows app
cd app
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R`. "Chạy thấy" là các dòng `debugPrint` ở terminal và chữ trên màn hình.

## Đề

Trang có một bộ đếm `Counter` (nhận `label` từ cha) và hai nút của cha: **Đổi nhãn**, **Ẩn hiện**. Bộ đếm có ba nút:
**Cộng**, **Lén**, **Chậm**.

Xong khi bấm lần lượt Cộng → Lén → Cộng → Đổi nhãn → Ẩn hiện → Ẩn hiện, terminal in đúng:

```
initState
build: 0
trước setState
sau setState
build: 1
cộng lén: _count = 2
trước setState
sau setState
build: 3
didUpdateWidget: Vé thường -> Vé VIP
build: 3
dispose
initState
build: 0
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** bên dưới: trang cha + `Counter` chỉ có `build` in `build: $_count` và nút Cộng gọi `setState` | Mở app: `build: 0`. Bấm Cộng: `build: 1`, màn hình `Vé thường: 1` |
| 2 | `initState` in `initState`. Trong hàm của nút Cộng: in `trước setState`, gọi `setState`, in `sau setState` | Mở app: `initState`, `build: 0`. Bấm Cộng: `trước setState`, `sau setState`, **rồi mới** `build: 1`. Không có `initState` lần hai |
| 3 | Nút **Lén**: tăng `_count` **không qua** `setState`, in `cộng lén: _count = ...` | Bấm Lén: `cộng lén: _count = 2`, màn hình **vẫn `1`**. Bấm Cộng: `build: 3`, màn hình nhảy thẳng lên `3` |
| 4 | `didUpdateWidget` in nhãn cũ → nhãn mới. Bấm **Đổi nhãn** | `didUpdateWidget: Vé thường -> Vé VIP`, `build: 3`. Số đếm **giữ nguyên 3**, không `initState` |
| 5 | `dispose` in `dispose`. Bấm **Ẩn hiện** hai lần | Lần một: `dispose`, bộ đếm biến mất. Lần hai: `initState`, `build: 0`: bộ đếm **mới**, số về 0 |
| 6a | Nút **Chậm**: đợi 1 giây rồi `setState` cộng 1. Bấm Chậm rồi bấm Ẩn hiện **ngay** | `dispose`, 1 giây sau lỗi đỏ ở terminal: `setState() called after dispose(): _CounterState#…(lifecycle state: defunct, not mounted)` |
| 6b | Sau dòng `await`, thêm `if (!mounted) return;` | Làm lại: `dispose`, không lỗi |

Ba điều thấy tận mắt:
- **Lượt 2:** `sau setState` in **trước** `build`. `setState` trả về ngay; vẽ là việc của khung hình sau.
- **Lượt 3:** dữ liệu đổi mà không ai báo thì màn hình không biết (bài 29 lượt 1). Số 2 có thật, chỉ là không ai vẽ.
- **Lượt 4 so với lượt 5:** cha đưa tham số mới thì State **sống tiếp** và giữ số đếm; cha gỡ widget ra rồi gắn lại
  thì là một State **mới**.

## Từng lượt

### Lượt 1 (vỏ)

`lib/main.dart`, thay hết:

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: HomePage())));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _show = true;
  var _label = 'Vé thường';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_show) Counter(label: _label),
        TextButton(
          onPressed: () => setState(() => _label = 'Vé VIP'),
          child: const Text('Đổi nhãn'),
        ),
        TextButton(
          onPressed: () => setState(() => _show = !_show),
          child: const Text('Ẩn hiện'),
        ),
      ],
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key, required this.label});
  final String label;

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  var _count = 0;

  void _add() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build: $_count');
    return Column(
      children: [
        Text('${widget.label}: $_count'),
        TextButton(onPressed: _add, child: const Text('Cộng')),
      ],
    );
  }
}
```

`Counter` (widget) chỉ giữ `label`, và là `const`: nó **không đổi được**. Thứ đổi được (`_count`) nằm trong
`_CounterState`. `widget.label` là cách State nhìn sang widget hiện tại của nó.

### Lượt 2, 4, 5: ba mốc đời

Gõ `initState`, `didUpdateWidget`, `dispose` trong lớp State rồi để VS Code tự điền khung (`@override` và lời gọi
`super`). Quy ước: `super.initState()` gọi **đầu** hàm, `super.dispose()` gọi **cuối** hàm.

```dart
  @override
  void didUpdateWidget(Counter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // oldWidget: widget cũ; widget: widget mới
  }
```

### Lượt 3, 6: hai nút còn lại

Thêm vào `Column` của `Counter` hai nút `Lén` và `Chậm`, mỗi nút một hàm. Hàm của `Chậm` là `async`:
`await Future.delayed(const Duration(seconds: 1));` rồi mới `setState`.

`mounted` là `true` chừng nào State còn gắn trên cây (giữa `initState` và `dispose`). Bạn đã gõ `if (mounted)` từ
bài 6 lượt 2; lượt 6a cho thấy thiếu nó thì sao.

## Thử phá

1. Đổi `Counter` thành `StatelessWidget` (xoá lớp State, `_count` thành biến trong `build`). Nút Cộng làm được gì?
   Không gì cả: `StatelessWidget` không có chỗ nào **sống qua** hai lần `build` để giữ số. Trả lại.
2. Trong `_add`, viết `_count++; setState(() {});` (đổi trước, gọi `setState` rỗng sau). Chạy vẫn đúng. `setState`
   không quan tâm bạn đổi gì trong hàm đưa cho nó; nó chỉ đánh dấu. Viết phép đổi **trong** `setState` là quy ước để
   người đọc thấy "dòng này làm màn hình đổi".

## Bắc cầu sang project

| Bài 32 | EH |
|---|---|
| `initState` + `late` | `app/lib/features/ai/presentation/widgets/chat_bubble.dart` dòng 112–114: `late final AnimationController _controller;` gán trong `initState` (bài 26) |
| `dispose` phải dọn | Trang đăng nhập bạn gõ ở bài 6: `_email.dispose(); _password.dispose();`. Bloc: `booking_payment_bloc.dart` dòng 47–58, `close()` hủy timer và hủy nghe stream |
| Lượt 6: `mounted` | Khắp app; `booking_payment_page_web.dart` dòng 28 `if (!context.mounted) return;` |
| Lượt 5: State mới thì số về 0 | Bài 12 lượt 7: mỗi lần về tab Đặt vé là một `SelectionPage` mới, nên mã ý định mới |
| Lượt 4: State sống qua tham số mới | Lý do bài 12 phải thêm `key: ValueKey(uid)` khi đổi người: không có key thì State cũ sống tiếp với dữ liệu của người cũ (bài 34) |
| `setState` | EH hầu như không dùng cho dữ liệu: state nằm trong Bloc/Cubit, `BlocBuilder` gọi `setState` hộ khi có state mới (bài 29, 31) |

- **`setState` làm gì bên trong:** chạy hàm bạn đưa → đánh dấu Element của State này là "bẩn" → xin Flutter một khung
  hình → tới khung hình đó Flutter gọi `build` của mọi Element bẩn, so cây widget mới với cũ, và chỉ vẽ lại chỗ
  khác. Gọi `setState` 5 lần liền trong một hàm vẫn chỉ `build` **một** lần.
- **Vì sao State sống lâu hơn widget:** mỗi lần cha `build`, nó tạo một object `Counter` **mới** (rẻ, chỉ là bản mô
  tả). Flutter thấy "cùng loại, cùng chỗ" nên giữ State cũ và chỉ báo `didUpdateWidget`. Bài 33 cho bạn nhìn thấy
  điều này.

## Xong khi

- [ ] Terminal in đúng 14 dòng như đề
- [ ] Đã thấy lượt 3 (màn hình đứng ở 1) và lượt 6a (lỗi sau `dispose`)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm hai câu trả lời: "StatelessWidget vs StatefulWidget, and the State
  lifecycle" và "What happens when you call setState?"
