# Bài 15: tiền về, và về lần nữa

**Lõi một câu:** tin "tiền về" có thể tới **hai lần**, tới với **số tiền sai**, tới khi **đơn đã hết hạn**. Hàm xử lý
nhìn **trạng thái đơn trước**: đã xác nhận rồi thì bỏ qua, không ghi gì; không còn chờ thì không xác nhận; còn chờ
thì tiền phải **bằng đúng** tiền của đơn mới xác nhận.

Bài 14 trả lời "tin này có phải của PayOS không". Bài này trả lời "tin thật rồi, giờ làm gì với nó".

## Đề

`bai15.dart`: mọi thứ trong `main`, một hàm nhỏ trong `main`, không package, khoảng 25 dòng.

Ba đơn, đều 300000:
- `A`: `pending`
- `B`: `pending`
- `C`: `cancelled` (hết 5 phút giữ chỗ, đơn đã bị hủy, vé đã trả về kho)

Dòng thời gian, mỗi bước là một tin PayOS gửi tới (mã đơn + số tiền đã nhận):
1. Đơn A, 300000.
2. Đơn A, 300000 **lần nữa** (PayOS không nhận được câu trả lời kịp nên gửi lại).
3. Đơn B, 1000 (người mua chuyển thiếu).
4. Đơn C, 300000 (người mua lưu ảnh QR, 10 phút sau mới quét).
5. Đơn `X`, 300000 (mã không có thật; PayOS gửi thử một tin như vậy lúc mình đăng ký địa chỉ webhook).

Phải in ra đúng:

```
A lần 1: confirmed
A lần 2: already-confirmed
B trả 1000: amount-mismatch
C đã hết hạn: not-pending
mã lạ: not-found
vé đã phát: 1
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Kho `bookings` (Map: mã → doc có `status`, `totalAmount`), biến đếm `issued`. Hàm `confirm(id, paid)`: đổi đơn sang `confirmed`, `issued` tăng 1, trả `'confirmed'`. Bước 1 | `A lần 1: confirmed` và `vé đã phát: 1` |
| 2 | Bước 2 | `A lần 2: confirmed`, `vé đã phát: 2` ← **một lần trả tiền, hai vé** |
| 3 | Đơn đã `confirmed` thì trả `already-confirmed`, không ghi gì | `A lần 2: already-confirmed`, `vé đã phát: 1` |
| 4 | Bước 3 và 4 | `B trả 1000: confirmed`, `C đã hết hạn: confirmed`, `vé đã phát: 3` ← **vé 300.000đ giá 1.000đ; đơn đã hủy sống lại** |
| 5 | Tiền nhận khác tiền của đơn thì trả `amount-mismatch` | `B trả 1000: amount-mismatch`; C vẫn `confirmed`, `vé đã phát: 2` |
| 6 | Đơn không còn `pending` thì trả `not-pending`. Dòng này đứng **trên** dòng so tiền | `C đã hết hạn: not-pending`, `vé đã phát: 1` |
| 7a | Bước 5 | 4 dòng đầu, rồi **sập**: `Null check operator used on a null value` |
| 7b | Không có đơn thì trả `not-found` | Đủ 6 dòng như đề |

Ba cái hỏng (lượt 2, 4, 7a) đều không cần kẻ xấu nào. Mạng chậm, người mua chuyển nhầm, người mua quét trễ: chuyện
ngày nào cũng có.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: sửa một field của doc nằm trong kho

```dart
final lop = <String, Map<String, Object>>{
  'hs1': {'ten': 'Chi', 'diem': 7},
};
final hs = lop['hs1']!;
hs['diem'] = 8;
print(lop); // {hs1: {ten: Chi, diem: 8}}
```

`hs` và `lop['hs1']` là **cùng một Map**, nên sửa `hs` là kho đổi theo. (Khác bài 10, ở đó bạn tạo Map mới bằng
`{...}` để giữ lại bản trước.)

Ghi kiểu `<String, Map<String, Object>>` cho kho: doc vừa có chữ vừa có số.

### Lượt 3, 5, 6: thoát sớm

Mỗi luật một dòng `if (...) return 'mã';` đặt **trên** hai dòng ghi, như bài 8. Hàm chỉ chạm tới dòng ghi khi đã qua
hết các cửa.

So số trong Map trộn kiểu: `paid != booking['totalAmount']` so thẳng được, không cần `as int`.

### Lượt 7b

Bỏ dấu `!` khi tra kho, kiểm `== null` đầu tiên (bài 7 lượt 5).

## Thử phá

1. Dời dòng so tiền lên **trên** dòng `already-confirmed`, và cho tin lần 2 của đơn A mang số `1000`. Dòng 2 in gì?
   Đơn A đã xác nhận xong xuôi, vậy mà hệ thống kêu "lệch tiền". Trong đồ thật, `amount-mismatch` là báo động "có
   tiền thật của khách chưa khớp đơn, cần người hoàn lại". Báo động giả là có người mất công đi tìm một khoản tiền
   không tồn tại. Vì vậy: **trạng thái trước, tiền sau.** Trả lại.
2. Đổi luật tiền thành "nhận ít hơn mới là lệch" (`paid < ...`, cần `as int`), cho B trả `900000`. B ra gì? Trả
   thừa mà xác nhận luôn thì 600.000đ của khách nằm đâu? Thiếu hay thừa đều để **người** xử lý. Trả lại.

## Bắc cầu sang project

**Bạn sẽ gõ ở gd4 Bước 3:**

| Bài 15 | Code thật |
|---|---|
| Ba dòng `if` về trạng thái và tiền | Chặng 3.2, `decidePayment.ts`: hàm thuần `decidePayment(booking, paidAmount)` trả `"confirm"`, `"already-confirmed"`, `"not-pending"`, `"amount-mismatch"`. Cùng thứ tự |
| `not-found` | Chặng 3.3, `confirmPaidBooking.ts`: `if (found.empty) return "not-found";` (tìm đơn theo `payosOrderCode`) |
| Hai dòng ghi + `issued++` | `tx.update(bookingRef, { status: "confirmed", paymentStatus: "confirmed", confirmedAt, qrData })`. "Phát vé" là ghi `qrData` |
| "Không ghi gì" | `if (decision !== "confirm") return decision;` |
| Lượt 2, 4 (bản hỏng) | Chặng 2.2: bản `confirmPaidBooking` TẠM cố ý ăn cả ba; Chặng 3.1 viết 3 test **đỏ** trước rồi mới vá |
| Thử phá 1 | Chặng 3.2: "trạng thái trước, tiền sau"; test `decidePayment(done, 1000)` mong `already-confirmed` |
| Thử phá 2 | Test "trả thiếu hay trả thừa đều không khớp" (299000 và 300001) |

- **Lõi:** bốn dòng `if`. Trong code thật chúng là một hàm thuần riêng (bài 8), có 4 test.
- **Vỏ:** đọc và ghi nằm trong **một transaction** (bài 2, 9): hai tin tới cùng lúc thì một bên phải chạy lại, đọc
  thấy `confirmed`, ra `already-confirmed`. Bài này chạy tuần tự nên chưa cần; bài ghép 17 có.
- **Vỏ:** `amount-mismatch` và `not-pending` ghi `logger.error` kèm mã đơn và số tiền, để người hoàn tiền.
- **Vỏ:** webhook trả `200` cho **mọi** kết quả ở trên, kể cả `not-found`. PayOS gửi lại tới khi nhận được mã 2xx;
  trả lỗi là nó gửi mãi.
- **Bản đang chạy trong EH** (`functions/payos/payosWebhook.js`): dòng 57–65 có kiểm "không còn `pending` thì bỏ
  qua" (lượt 3 và 6 gộp làm một), nhưng dòng 69–74 xác nhận mà **không so tiền** (thiếu lượt 5). Đó là nửa sau của
  lỗ L3. Nửa đầu ở bài 7: `createPayosOrder.js` dòng 17 lấy `amount` từ app.
- Đây vẫn là **idempotency** của bài 3, chỉ khác chỗ để dấu: ở bài 3 dấu là "tên đơn đã có", ở đây dấu là "đơn đã
  `confirmed`".

## Xong khi

- [ ] In đúng 6 dòng như đề
- [ ] Đã thấy lượt 2 (hai vé), lượt 4 (ba vé), lượt 7a (sập)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "A webhook arrives twice: what happens in your system?"
