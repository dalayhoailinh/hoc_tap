# Bài 20: khoá trên màn hình không phải là cái khoá thật

**Lõi một câu:** khoá giữ ghế (bài 18, 19) do **app** ghi và **app** tự kiểm, nên nó chỉ ngăn được người dùng tử
tế. Chống bán trùng ghế thật nằm ở server: lúc đặt, server tra **sổ ghế của chính nó** ("ghế này đang thuộc đơn nào,
đơn đó còn sống không"), rồi ghi tên đơn mới vào sổ, trong cùng transaction tạo đơn.

## Đề

`bai20.dart`: mọi thứ trong `main`, một hàm nhỏ trong `main`, không package, khoảng 25 dòng.

- `locks`: khoá trên màn hình, đang có sẵn `A1` do An giữ. Server **không** đọc Map này.
- `bookings`: mã đơn → doc có `userId`, `seat`, `status`. Mã đơn đặt theo số thứ tự: `don1`, `don2`…
- Đơn "còn sống" là đơn `pending` hoặc `confirmed`.

Dòng thời gian:
1. An (đang giữ khoá A1) đặt A1 qua app.
2. Kẻ xấu không mở app, gọi thẳng server đặt A1.
3. An hủy đơn.
4. Bình đặt A1.

Phải in ra đúng:

```
Khoá trên màn hình: {A1: An}
An đặt A1: don1
Kẻ xấu đặt A1: seat-taken
An hủy don1
Bình đặt A1: don2
Sổ ghế: {A1: don2}
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | `locks`, `bookings`. Hàm `createBooking(user, seat)` tạo đơn `confirmed`, trả mã đơn. Bước 1 và 2, in `bookings` | `An đặt A1: don1`, `Kẻ xấu đặt A1: don2`; kho có **hai đơn `confirmed` cùng ghế A1**, dù khoá của An vẫn nằm đó |
| 2 | Sổ `seatLedger` (Map: ghế → mã đơn). Tạo đơn thì ghi sổ; ghế đã có trong sổ thì trả `seat-taken`. In sổ thay cho in `bookings` | `Kẻ xấu đặt A1: seat-taken`, `Sổ ghế: {A1: don1}` |
| 3 | Bước 3 (đổi `status` của `don1` thành `cancelled`, in `An hủy don1`) và bước 4 | `Bình đặt A1: seat-taken` ← **đơn đã hủy mà ghế chết luôn** |
| 4 | Ghế "có chủ" khi có trong sổ **và** đơn chủ còn sống | Đủ 6 dòng như đề |

Lượt 1: không ai phá khoá của An. Kẻ xấu chỉ **không hỏi tới nó**. Luật "ghế người khác đang giữ thì không bấm được"
nằm trong app; ai không dùng app thì không bị luật đó ràng.

Lượt 3 có cách vá dễ nghĩ tới: "hủy đơn thì xoá ghế khỏi sổ". Cách đó đúng cho tới khi có **một** đường làm đơn chết
mà quên xoá sổ (đơn hết hạn, hoàn tiền, xoá sự kiện…). Lượt 4 không phải nhớ gì: sổ chỉ trỏ tới đơn, đơn chết thì
ghế tự rảnh.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: mã theo số thứ tự

`'don${bookings.length + 1}'` (bài 3 lượt 2).

### Lượt 4: đi qua hai Map

```dart
final xeCua = {'43A-1': 'Chi'};
final nguoi = <String, Map<String, String>>{'Chi': {'nghe': 'bác sĩ'}};
final chu = xeCua['43A-9']; // null: xe lạ
print(nguoi[chu]?['nghe']); // null, không lỗi
print(nguoi[xeCua['43A-1']]?['nghe']); // bác sĩ
```

- Tra Map bằng key `null` thì ra `null`. `?[...]` đi tiếp an toàn (bài 5).
- Hỏi "có nằm trong mấy giá trị này không" bằng Set viết tại chỗ (bài 11). Set đó không chứa `null`, nên ghế chưa có
  trong sổ tự động là "không có chủ".

Đổi `status` của một đơn nằm trong kho: `bookings['don1']!['status'] = 'cancelled';` (bài 15 lượt 1).

## Thử phá

1. Xoá dòng ghi sổ. Kẻ xấu ra gì? Kiểm mà không ghi thì lần sau không còn gì để kiểm. Kiểm và ghi phải đi **cùng
   nhau**; trong code thật là cùng một transaction (bài 2, 9), nếu không hai người bấm cùng lúc đều qua bước kiểm.
   Trả lại.
2. Thử "vá bằng khoá": thay cả phần tra sổ bằng `if (locks[seat] != null && locks[seat] != user) return
   'seat-taken';`. Rồi cho kẻ xấu làm một việc trước khi đặt: `locks['A1'] = 'Kẻ xấu';`. Ra gì? App ghi được khoá thì
   kẻ xấu cũng ghi được; và khoá còn tự hết hạn. Thứ app ghi được thì server **không được tin**. Trả lại.

## Bắc cầu sang project

| Bài 20 | EH |
|---|---|
| `locks` | Realtime Database `eventState/{eventId}/seats` (bài 18, 19). App ghi, app kiểm |
| "Server không đọc `locks`" | Đúng nguyên văn: không function nào đọc khoá RTDB lúc tạo đơn |
| Lượt 1 | Lỗ gd4 đang mở, đòn "Hai người một ghế" đầu `gd04_phan_server.md`: gọi thẳng `createBooking` với `seatCodes: ["A1"]` của ghế đã bán |
| `createBooking` sau gd3 | `planBooking` chỉ kiểm **hình dạng**: số ghế bằng số vé (`seat-count-mismatch`), một ghế không chọn hai lần trong đơn (`duplicate-seat`). ADR 6 của gd3 ghi rõ phần còn lại để gd4 |
| `seatLedger` | gd4 Bước 4: mỗi ghế một doc `events/{eventId}/seats/{seatCode}` = `{bookingId, userId}` |
| Lượt 4 | Hàm thuần `firstTakenSeat(claims)`, `HOLDING_STATUSES = ["pending", "confirmed"]` |
| Tra sổ rồi tra đơn chủ | `readSeatClaims(tx, db, seatRefs)`: `tx.getAll` các doc ghế, rồi `tx.getAll` các đơn chủ |
| Ghi sổ | Trong transaction của `createBooking`: `tx.set(seatRef, { bookingId, userId: uid })` |
| `seat-taken` | `HttpsError("failed-precondition", 'Ghế "A1" đã có người đặt.', { code: "seat-taken" })` |

- **Guide gd4 chưa có Bước 4** (bảng "Bản đồ" ghi "đang viết"). Code đã chạy test nằm ở nhánh
  `origin/cloud/gd4-sb-b4-wip`, file `functions/src/booking/seatLedger.ts`; mình đã mở file đó để lấy các tên ở bảng
  trên. Lý do chọn kiểu sổ này ghi ở `ke_hoach_viet_lai/cloud/log_gd4-guide.md` (mục ngày 04/11), và cũng chính là
  hai đoạn dưới bảng lượt.
- **Lõi:** sổ trỏ tới đơn + "đơn còn sống" + kiểm và ghi cùng transaction.
- **Vỏ:** một đơn nhiều ghế (tối đa 10, đọc bằng một `tx.getAll`); rules khoá hẳn collection `seats` (chỉ server
  ghi, bài 11); lọc mã ghế bằng regex vì nó nằm trong đường dẫn doc.
- **Vậy khoá RTDB để làm gì?** Để **dễ dùng**: người đến sau thấy ghế xám ngay, khỏi chọn rồi mới bị từ chối ở bước
  trả tiền. Giống điều hướng theo role ở bài 6 lượt 7: màn hình lịch sự, khoá thật ở server.
- App hiện tô ghế "đã bán" bằng hai nguồn, đều chỉ để hiển thị: khoá `sold` trên RTDB (trigger ghi), và
  `getSoldSeatCodes` (`booking_remote_datasource.dart` dòng 414–431) đọc các đơn còn sống.

## Xong khi

- [ ] In đúng 6 dòng như đề
- [ ] Đã thấy lượt 1 (hai đơn một ghế) và lượt 3 (ghế chết sau khi hủy)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do you stop two users booking the same seat?" (hai
  tầng: khoá để dễ dùng, sổ ghế trong transaction để chắc)
