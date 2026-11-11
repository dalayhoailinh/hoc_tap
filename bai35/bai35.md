# Bài 35 (thí nghiệm Flutter): ai quyết kích thước

**Lõi một câu:** *constraints đi xuống, size đi lên, cha đặt vị trí.* Cha đưa cho con một khoảng cho phép (rộng từ
`min` tới `max`, cao từ `min` tới `max`); con **chọn** một kích thước trong khoảng đó rồi báo lên; cha quyết đặt con
ở đâu. Con **không bao giờ** tự vượt được khoảng cha cho, dù bạn ghi `width: 500`.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai35
flutter create --empty --platforms=windows app
cd app
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R`.

Các con số dưới đây đo ở cửa sổ rộng 800. Cửa sổ của bạn rộng khác thì số khác; thứ cần nhìn là **`min` và `max`
bằng nhau hay khác nhau**, và con lấy bao nhiêu.

## Các lượt

Mỗi lượt chỉ thay phần trong `runApp(...)`. Widget `Probe` (vỏ bên dưới) in ra khoảng cha cho và kích thước con
lấy.

| Lượt | Trong `runApp` | Chạy thấy |
|---|---|---|
| 1 | Một cái hộp `Container(width: 100, height: 100, color: Colors.teal)` bọc trong `Probe` | Màu teal **phủ kín cửa sổ**. `hộp: cha cho rộng 800..800, con lấy 800` ← ghi 100 mà ra 800 |
| 2 | Bọc `Probe` trong `Center` | Hộp 100×100 ở giữa. `hộp: cha cho rộng 0..800, con lấy 100` |
| 3 | Trong `Center`: `SizedBox(width: 200)` chứa `Probe` chứa hộp ghi `width: 500` | Hộp rộng 200. `hộp: cha cho rộng 200..200, con lấy 200` ← ghi 500 mà ra 200 |
| 4a | `MaterialApp` → `Scaffold` → `Row` gồm một `Icon` và một `Text` rất dài | Sọc vàng đen bên phải; terminal: `A RenderFlex overflowed by 991 pixels on the right.` |
| 4b | Bọc `Text` trong `Expanded` (và `Probe` để đo) | Chữ tự xuống dòng. `chữ: cha cho rộng 776..776, con lấy 776` |
| 5a | `Scaffold` → `Column` gồm một `Text` và một `ListView` | Màn hình trắng/đỏ; terminal: `Vertical viewport was given unbounded height.` |
| 5b | Bọc `ListView` trong `Expanded` | Thấy `Vé của tôi`, `Vé 1`, `Vé 2` |

Đọc từng dòng in theo câu lõi:
- **Lượt 1:** màn hình là cha, và nó bắt con **đúng bằng** nó: `800..800`. Con không có lựa chọn; `width: 100` bị bỏ
  qua.
- **Lượt 2:** `Center` nhận `800..800` từ màn hình, nhưng **nới ra** cho con: `0..800`. Giờ con được chọn, và chọn
  100. `Center` đặt nó vào giữa.
- **Lượt 3:** `SizedBox(width: 200)` ép con `200..200`. Con xin 500, không được.
- **Lượt 4a:** `Row` hỏi từng con "bạn muốn rộng bao nhiêu?" với chiều rộng **không giới hạn**. `Text` trả lời "một
  dòng dài 1000 mấy pixel". Cộng lại quá cửa sổ → tràn.
- **Lượt 4b:** `Expanded` nói với `Row`: "con này lấy **phần còn lại**". `Text` nhận `776..776` (800 trừ icon 24) và
  tự xuống dòng.
- **Lượt 5a:** `Column` cho con chiều cao **không giới hạn** ("cứ cao tuỳ thích"). `ListView` là thứ cuộn được, nó
  muốn cao **hết mức cha cho**. Hết mức của vô hạn là vô hạn → lỗi.

## Từng lượt

### Vỏ

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(
    Probe('hộp', child: Container(width: 100, height: 100, color: Colors.teal)),
  );
}

// Prints what the parent allows (constraints) and what the child took (size).
class Probe extends StatelessWidget {
  const Probe(this.name, {super.key, required this.child});
  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final size = context.size!;
          debugPrint(
            '$name: cha cho rộng ${constraints.minWidth.round()}..'
            '${constraints.maxWidth.round()}, con lấy ${size.width.round()}',
          );
        });
        return child;
      },
    );
  }
}
```

`LayoutBuilder` là widget cho bạn **nhìn thấy constraints** cha đưa xuống. `context.size` (sau khi vẽ xong) là kích
thước đã chốt; nó đến từ RenderObject (bài 33 lượt 2).

Lượt 1 không có `MaterialApp`: cố ý, để cái hộp là con trực tiếp của màn hình.

### Lượt 4a, 5a: dữ liệu

Chữ dài của lượt 4a (một dòng, đừng xuống dòng trong code):

```dart
Text('Ghế A1, hàng đầu, sát sân khấu, có chỗ để chân rộng, gần lối ra, view thẳng, không bị cột che, kèm một phần bắp rang và nước')
```

`ListView` của lượt 5a: `ListView(children: const [Text('Vé 1'), Text('Vé 2')])`.

## Thử phá

1. Ở lượt 2, đổi `Center` thành `Align(alignment: Alignment.topLeft, ...)`. Hộp vẫn 100×100 nhưng lên góc. "Cha đặt
   vị trí": con không biết, cũng không quyết, mình nằm ở đâu.
2. Ở lượt 5b, thay `Expanded` bằng `SizedBox(height: 100, ...)`. Cũng hết lỗi. Mọi cách sửa lỗi "unbounded" đều là
   một việc: **cho nó một giới hạn**.

## Bắc cầu sang project

| Bài 35 | EH |
|---|---|
| `SizedBox`, `ConstrainedBox` ép con | `booking_payment_page_web.dart` dòng 45–47: `Align(topCenter)` → `ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520))`: thẻ thanh toán không bao giờ rộng quá 520 dù màn hình to cỡ nào |
| `Expanded` trong `Row`/`Column` | Khắp app. Bài 21 của bạn: `Row` hai cột `Expanded(child: SeatPanel(...))` |
| Lỗi 5a | Luật "web truyền thống" của EH (một thanh cuộn ngoài cùng): commit `35f4a02` sửa đúng lỗi họ này, vỏ web bọc cả trang trong vùng cuộn nên trang con có `ListView` nhận chiều cao vô hạn. Test canh nó: `app/test/features/shell/web_page_frames_test.dart` |
| `LayoutBuilder` | Chỗ nào bố cục đổi theo bề rộng (màn hẹp một cột, màn rộng hai cột) |
| Sọc vàng đen | Chỉ hiện ở bản debug. Bản release cắt mất phần tràn, không báo gì |

Ba câu để gỡ mọi lỗi bố cục:
1. Cha đưa cho widget này khoảng nào? (Bọc `LayoutBuilder` vào mà in, như `Probe`.)
2. Widget này chọn kích thước thế nào: nhỏ nhất có thể (`Text`, `Icon`), to nhất có thể (`ListView`, `Container`
   không có con), hay theo con?
3. Có ai trong chuỗi cha–con đang đưa xuống **vô hạn** không? (`Row` theo chiều ngang, `Column` và mọi thứ cuộn được
   theo chiều cuộn.)

## Xong khi

- [ ] Thấy đủ 7 "Chạy thấy"
- [ ] Giải thích được dòng in của lượt 1, 2, 3 bằng câu lõi
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Explain: constraints go down, sizes go up, parent sets
  position"
