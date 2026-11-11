# Bài 34 (thí nghiệm Flutter): Key

**Lõi một câu:** sau mỗi lần `build`, Flutter ghép widget mới với Element cũ (và State của nó) theo **loại widget +
vị trí**. Danh sách bị xoá bớt hay đổi thứ tự thì ghép theo vị trí là **ghép nhầm**: State của dòng này dính sang
dòng khác. `Key` là cái tên bạn đặt cho từng widget để Flutter ghép theo **tên** thay vì theo vị trí.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai34
flutter create --empty --platforms=windows app
cd app
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R`.

## Đề

Giỏ có hai ghế `A1`, `B2`. Mỗi ghế là một dòng `SeatTile` có State riêng: số bắp rang gọi kèm (bấm vào dòng để
cộng 1). Hai nút: **Bỏ ghế đầu**, **Đảo thứ tự**.

Xong khi: bấm A1 ba lần, rồi Bỏ ghế đầu, màn hình còn `B2: 0 bắp` và terminal in `dispose: State tạo cho A1`.

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** bên dưới (chưa có key) | Mở app: `initState: State cho A1`, `initState: State cho B2`. Bấm A1 ba lần: `A1: 3 bắp`, `B2: 0 bắp` |
| 2 | Bấm **Bỏ ghế đầu** | Màn hình: `B2: 3 bắp` ← **3 bắp của A1 giờ thuộc về B2**. Terminal: `dispose: State tạo cho B2` ← Flutter vứt **nhầm** State |
| 3 | `R` để làm lại. Bấm A1 ba lần, bấm **Đảo thứ tự** | `B2: 3 bắp`, `A1: 0 bắp` ← chữ đổi chỗ, **số đứng yên** |
| 4 | Thêm `key: ValueKey(code)` cho mỗi `SeatTile`. Làm lại lượt 2 rồi lượt 3 | Bỏ ghế đầu: `B2: 0 bắp`, `dispose: State tạo cho A1`. Đảo thứ tự: `B2: 0 bắp`, `A1: 3 bắp` |

Lượt 2 đáng sợ ở chỗ không có lỗi nào. Màn hình trông hợp lệ, chỉ là dữ liệu của ghế này nằm ở ghế kia.

Vì sao: trước khi bỏ, cây có `[SeatTile, SeatTile]`; sau khi bỏ còn `[SeatTile]`. Flutter nhìn vị trí 1: "vẫn là một
`SeatTile`" → **giữ State ở vị trí 1** (State của A1, đang có 3 bắp), chỉ báo cho nó widget mới (`code: 'B2'`).
Vị trí 2 không còn ai → vứt State ở đó (State của B2).

## Từng lượt

### Lượt 1 (vỏ)

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: CartPage())));

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  var _codes = ['A1', 'B2'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final code in _codes) SeatTile(code: code),
        TextButton(
          onPressed: () => setState(() => _codes = _codes.sublist(1)),
          child: const Text('Bỏ ghế đầu'),
        ),
        TextButton(
          onPressed: () => setState(() => _codes = _codes.reversed.toList()),
          child: const Text('Đảo thứ tự'),
        ),
      ],
    );
  }
}

class SeatTile extends StatefulWidget {
  const SeatTile({super.key, required this.code});
  final String code;

  @override
  State<SeatTile> createState() => _SeatTileState();
}

class _SeatTileState extends State<SeatTile> {
  var _snacks = 0;
  late final String _madeFor;

  @override
  void initState() {
    super.initState();
    _madeFor = widget.code;
    debugPrint('initState: State cho $_madeFor');
  }

  @override
  void dispose() {
    debugPrint('dispose: State tạo cho $_madeFor');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _snacks++),
      child: Text('${widget.code}: $_snacks bắp'),
    );
  }
}
```

- `_madeFor` ghi lại State này **sinh ra cho ghế nào** (gán một lần trong `initState`, bài 26), để lúc `dispose` biết
  Flutter vừa vứt State của ai.
- Chữ trên dòng lấy từ `widget.code` (widget **hiện tại**); số bắp lấy từ State. Lượt 2 là lúc hai thứ đó lệch nhau.

### Lượt 4

`super.key` trong constructor của `SeatTile` đã nhận sẵn tham số `key`. Chỗ tạo widget chỉ cần đưa:
`SeatTile(key: ValueKey(code), code: code)`.

`ValueKey(x)`: hai key bằng nhau khi `x` bằng nhau. Chọn `x` là thứ **định danh** của dòng (mã ghế, id), không phải
vị trí.

## Thử phá

1. Đổi key thành `ValueKey(_codes.indexOf(code))` (key theo **vị trí**). Làm lại lượt 2. Lỗi quay về y nguyên: key
   theo vị trí thì cũng như không có key.
2. Đổi key thành `UniqueKey()`. Bấm A1 ba lần rồi Đảo thứ tự. Cả hai về `0 bắp`, terminal có thêm hai dòng
   `initState`. `UniqueKey()` tạo trong `build` thì **mỗi lần vẽ là một tên mới**: Flutter coi mọi dòng là dòng mới,
   vứt hết State cũ. Trả về `ValueKey(code)`.

## Bắc cầu sang project

| Bài 34 | EH |
|---|---|
| Key theo id cho từng dòng danh sách | `app/lib/features/events/presentation/widgets/list_events.dart` dòng 66 và `grid_events.dart` dòng 54: `EventCard(key: ValueKey('event-card-${event.id}'), …)`; `organizer_events_page.dart` dòng 743: `key: ValueKey(event.id)` |
| **Đổi key để cố ý làm mới State** | `booking_selection_page_mobile.dart` dòng 148–149: `UserSeatMapWidget(key: ValueKey(state.activeFloorIndex), …)`. Đổi tầng → key đổi → State cũ (vị trí zoom, kéo) bị vứt, sơ đồ tầng mới bắt đầu sạch |
| Cùng mẹo đó | Bài 12 lượt 7: `SelectionPage(key: ValueKey(uid))`, đổi người là trang mới |
| Trang đọc theo id trên URL | Kế hoạch (`05_sua_v1.md`, mục 4): trang `/booking/:bookingId/payment` có `key: ValueKey(id)`; đi từ đơn này sang đơn khác mà không có key thì State (bloc, đồng hồ) của đơn cũ sống tiếp với id mới |

Khi nào **cần** key:

| Tình huống | Cần key? |
|---|---|
| Danh sách widget **có State** mà phần tử có thể thêm, xoá, đổi thứ tự | Có, key theo id |
| Muốn State **làm lại từ đầu** khi một giá trị đổi (id, tầng, người dùng) | Có, key theo giá trị đó |
| Danh sách widget không có State (`Text`, `Icon`), hoặc không bao giờ đổi thứ tự | Không |

- **Lõi:** ghép theo loại + vị trí, trừ khi có key.
- **`GlobalKey`** là loại khác: một cái tay cầm để từ ngoài với tới State hay RenderObject của một widget
  (`booking_payment_page_mobile.dart` dòng 339 dùng nó để chụp ảnh mã QR). Đắt hơn, chỉ dùng khi thật cần.
- Đây là bài 32 lượt 4 và 5 nhìn từ phía Flutter: "tham số mới, State sống tiếp" là ghép **trúng**; "gỡ ra gắn lại,
  State mới" là ghép **không được**.

## Xong khi

- [ ] Thấy lượt 2 (`B2: 3 bắp`) và lượt 3 (số đứng yên)
- [ ] Có key: `B2: 0 bắp`, `dispose: State tạo cho A1`
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What are Keys, and when do you need them?"
