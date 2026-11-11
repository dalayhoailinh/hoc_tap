# Bài 19: lời dặn trước khi rớt mạng

**Lõi một câu:** app đã chết thì không tự dọn được gì. Nên lúc **còn sống**, ngay khi giữ ghế, app dặn trước server:
"nếu tôi mất kết nối thì xoá khoá này giúp". **Server** là người nhận ra kết nối đứt và làm theo lời dặn.

Bài 18 lo ca "bỏ đi": chờ hết hạn. Bài này lo cho nhanh hơn: rớt là nhả.

## Đề

`bai19.dart`: mọi thứ trong `main`, ba hàm nhỏ trong `main`, không package, khoảng 30 dòng.

Kho ghế ở bài này gọn lại: Map mã ghế → tên người giữ (hạn giữ đã học ở bài 18, cắt đi).

Dòng thời gian:
1. An chọn A1 và A2.
2. Điện thoại An hết pin: **rớt mạng**.
3. Bình chọn B1.
4. Bình bấm "Đặt vé", sang trang thanh toán. Từ lúc này ghế gắn với một đơn đang chờ tiền.
5. Bình chuyển sang app ngân hàng để quét mã: app của mình xuống nền, **rớt mạng**.

Phải in ra đúng:

```
An rớt mạng -> server xoá [A1, A2]
Bình sang thanh toán: hủy lời dặn
Bình rớt mạng -> server xoá []
Ghế đang bị giữ: {B1: Bình}
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Kho `seats`. Hàm `lockSeat(user, code)` ghi khoá. Bước 1, in kho | `Ghế đang bị giữ: {A1: An, A2: An}` |
| 2 | Bước 2: chỉ là một dòng `print('An rớt mạng')`, vì app đã chết thì **không chạy thêm được dòng code nào** | `An rớt mạng`, `Ghế đang bị giữ: {A1: An, A2: An}` ← **hai ghế kẹt** |
| 3 | Sổ lời dặn `onDisconnect` (Map: người → danh sách ghế phải xoá). `lockSeat` ghi khoá **và** ghi lời dặn. Hàm `disconnect(user)` đóng vai server: lấy lời dặn của người đó ra, xoá các ghế, in | `An rớt mạng -> server xoá [A1, A2]`, `Ghế đang bị giữ: {}` |
| 4 | Bước 3, 4, 5. Bước 4 tạm là một dòng `print('Bình sang thanh toán')` | `Bình rớt mạng -> server xoá [B1]`, kho rỗng ← **đang đi trả tiền thì mất ghế** |
| 5 | Hàm `startPayment(user)`: **hủy** lời dặn của người đó, in `... sang thanh toán: hủy lời dặn` | Đủ 4 dòng như đề |

Lượt 2 là gốc: không có cách nào viết code "khi tôi chết thì…" ở phía app. Rút dây mạng, hết pin, hệ điều hành giết
app: không có dòng nào của app được chạy.

Lượt 4 là mặt trái: lời dặn quá sốt sắng. Trên điện thoại, **rời app một lát là rớt kết nối**, mà trả tiền bằng QR
thì gần như chắc chắn phải rời app.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 3: Map mà value là List

```dart
final gio = <String, List<String>>{};
gio.putIfAbsent('Chi', () => []).add('táo');
gio.putIfAbsent('Chi', () => []).add('cam');
print(gio); // {Chi: [táo, cam]}

final lay = gio.remove('Chi') ?? [];
print(lay); // [táo, cam]
print(gio); // {}
print(gio.remove('Dũng') ?? []); // []: không có thì remove trả null
```

- `putIfAbsent(key, () => [])`: chưa có danh sách của key đó thì tạo danh sách rỗng, rồi trả danh sách ra để `add`.
- `remove(key)` vừa xoá vừa **trả lại** thứ vừa xoá. Lời dặn làm xong là hết, nên lấy ra bằng `remove`.
- Xoá nhiều key khỏi một Map: `codes.forEach(seats.remove);` (bài 16).

Để ý ai gọi `disconnect`: dòng thời gian của bạn, đóng vai **server**. Không có dòng nào đóng vai app của An sau lúc
rớt mạng.

### Lượt 5

Hủy lời dặn là xoá mục của người đó khỏi sổ, không đụng tới kho ghế.

## Thử phá

1. Trong `lockSeat`, xoá dòng ghi lời dặn. Chạy: kho cuối cùng còn gì? Đây là ca có thật: app ghi khoá xong, **chưa
   kịp** dặn thì chết. Ghế chỉ còn trông vào hạn giữ của bài 18. Hai cơ chế không thay nhau, chúng **chồng** lên
   nhau: lời dặn cho nhanh, hạn giữ cho chắc. Trả lại.
2. Đổi thứ tự bước 4 và 5: Bình rớt mạng **trước**, rồi mới `startPayment`. Ghế B1 còn không? Hủy lời dặn phải xong
   trước khi người dùng rời app. Trả lại.

## Bắc cầu sang project

Mở `app/lib/features/booking/data/datasources/seat_lock_remote_datasource.dart`:

| Bài 19 | Code thật |
|---|---|
| `lockSeat` ghi khoá | Dòng 150–178: `ref.runTransaction(...)` |
| `lockSeat` ghi lời dặn | Dòng 188: `await ref.onDisconnect().remove();` |
| Sổ `onDisconnect` | **Không có dòng nào.** Realtime Database giữ sổ này ở phía server |
| `disconnect(user)` | **Không có dòng nào.** Server của Realtime Database tự biết một kết nối đã đứt rồi làm theo sổ |
| `startPayment` | Dòng 230–255, `extendSeatLock`: gia hạn lên 5 phút rồi dòng 248 `await ref.onDisconnect().cancel();` |
| Thử phá 1 | Giữa dòng 150 (ghi khoá) và dòng 188 (dặn) là hai lời gọi mạng riêng. Chết ở giữa thì còn `expiresAt` |

- **Lõi:** một dòng dặn lúc giữ, một dòng hủy lúc sang thanh toán.
- **Sao server biết kết nối đứt?** App giữ **một kết nối mở liên tục** tới Realtime Database (đó cũng là đường nó
  nhận thay đổi của sơ đồ ghế, bài 16). Kết nối đóng, hoặc im quá lâu, là server biết. Đóng app đàng hoàng thì biết
  ngay; rút dây mạng thì server phải chờ một lúc không thấy tín hiệu mới kết luận. Bài 21 cho bạn tự dựng kết nối
  đó và rút nó.
- **Vì sao phải hủy lời dặn khi thanh toán:** chú thích ở dòng 245–247 ghi đúng lý do của lượt 4: ghế đã gắn với
  đơn thì giữ đủ 5 phút theo `expiresAt`, dù đóng tab hay giết app.
- **Rời trang đàng hoàng thì khác:** app còn sống nên tự dọn. `releaseManySeats` (dòng 257–289) xoá khoá và
  `cancel()` lời dặn; `BookingCreateBloc` gọi nó khi đóng trang chọn ghế.
- **Firestore không có `onDisconnect`.** Đây là lý do EH dùng **hai** database: Firestore cho đơn và tiền (có
  transaction nhiều doc), Realtime Database cho trạng thái "đang có mặt" của ghế.

Ba lớp nhả ghế của EH, từ nhanh tới chắc:

| Chuyện gì | Ai nhả | Mất bao lâu |
|---|---|---|
| Rời trang chọn ghế | App tự xoá (`releaseManySeats`) | Ngay |
| Rớt mạng, app chết lúc đang chọn | Server làm theo `onDisconnect` | Vài giây tới cả phút |
| Mọi ca còn sót | `expiresAt` (bài 18) + job dọn mỗi phút | 1 phút lúc chọn, 5 phút lúc thanh toán |

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 2 (ghế kẹt) và lượt 4 (mất ghế lúc trả tiền)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "A user holds seats, then loses connection or leaves: how
  are the seats released?" (kể đủ ba lớp)
