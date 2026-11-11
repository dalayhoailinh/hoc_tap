# Bài 18: giữ ghế có hạn

**Lõi một câu:** chọn một ghế là ghi lên ghế đó một cái **khoá**: của ai, **hết hạn lúc nào**. Người khác gặp khoá
còn hạn thì không chọn được. Khoá quá hạn thì coi như không có, không cần ai tới xoá. Ghế đã bán là khoá không có
hạn.

## Đề

`bai18.dart`: mọi thứ trong `main`, ba hàm nhỏ trong `main`, không package, khoảng 30 dòng.

- Giữ ghế được 2 phút. Giờ là **giờ giả** (bài 4), bắt đầu 8:10.
- Chỉ một ghế: `A1`.

Dòng thời gian:
1. 8:10 An chọn A1.
2. 8:11 Bình chọn A1.
3. An tắt máy đi ngủ, không bấm gì nữa.
4. 8:13 Bình chọn A1 lần nữa.
5. Bình trả tiền xong: A1 thành ghế **đã bán**.
6. 8:30 An quay lại chọn A1.

Phải in ra đúng:

```
8:10 An chọn A1: giữ được tới 8:12
8:11 Bình chọn A1: An đang giữ
8:13 Bình chọn A1: giữ được tới 8:15
8:30 An chọn A1: đã bán
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Kho `seats` (Map: mã ghế → khoá). Hàm `lockSeat(user, code)` ghi khoá `{'status': 'selecting', 'userId': user}` và trả `giữ được`. An chọn, Bình chọn, in kho | Cả hai `giữ được`; kho: `{A1: {status: selecting, userId: Bình}}` ← **An tưởng mình đang giữ ghế** |
| 2 | Ghế đang có khoá của **người khác** thì trả `<tên> đang giữ`, không ghi. Thêm: in `(An tắt máy đi ngủ)` rồi Bình chọn lần nữa | `Bình chọn A1: An đang giữ`, hai lần ← **An đi ngủ, ghế bị ôm tới sáng** |
| 3 | Giờ giả `now`. Khoá có thêm `expiresAt` = lúc chọn + 2 phút; khoá người khác chỉ chặn khi **còn hạn**. Hàm `clock(time)` in giờ:phút. Hàm `at(minute, user)`: tua `now` tới 8:phút đó rồi in một dòng theo mẫu đề | 3 dòng đầu của đề |
| 4a | Bước 5: ghi thẳng vào kho `{'status': 'sold', 'userId': 'Bình'}` (khoá bán không có hạn). Rồi bước 6 | 3 dòng đầu, rồi **sập**: `type 'Null' is not a subtype of type 'DateTime' in type cast` |
| 4b | Khoá `sold` thì trả `đã bán`, kiểm **trước** mọi thứ khác | Đủ 4 dòng như đề |

Lượt 2 là cái hỏng của bài: khoá không có hạn thì một người bỏ đi là ghế chết. Không có kẻ xấu nào: chỉ là đóng tab,
hết pin, đổi ý.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: lấy tên người đang giữ

Tra kho ra khoá (có thể `null`). Hai điều kiện cùng phải đúng: **có** khoá, **và** khoá không phải của mình. Chủ
khoá bấm lại ghế của chính mình thì vẫn đi tiếp xuống dòng ghi.

### Lượt 3: hạn

```dart
var now = DateTime(2026, 11, 11, 9, 0);
final hetHan = now.add(const Duration(minutes: 30)); // 9:30
now = DateTime(2026, 11, 11, 9, 45);
print(now.isBefore(hetHan)); // false: đã quá hạn
String clock(DateTime time) => '${time.hour}:${time.minute}';
print(clock(hetHan)); // 9:30
```

- `expiresAt` nằm trong Map trộn kiểu: lấy ra cần `as DateTime` (bài 8).
- Điều kiện chặn giờ có **ba** vế nối `&&`: có khoá, không phải của mình, còn hạn.
- Không ai "xoá" khoá của An lúc 8:12. Nó vẫn nằm trong kho; chỉ là không ai còn tin nó. Bình ghi đè lên.

### Lượt 4b

Một dòng `if (...) return 'đã bán';` đặt ngay dưới dòng tra kho. Nó phải đứng trên dòng có `as DateTime`.

## Thử phá

1. Đổi hạn giữ thành `Duration(days: 365)`. Dòng 8:13 ra gì? Trong EH, **app** là người ghi `expiresAt`, nên ai sửa app
   là tự cho mình giữ ghế cả năm. Hạn phải do bên không thể bị sửa (rules, server) **chặn trên**. Trả lại.
2. Bỏ vế "không phải của mình" khỏi điều kiện chặn, đổi dòng 8:11 thành An chọn lại A1. Ra gì? Chủ khoá bấm lại ghế
   của mình là **gia hạn**; thiếu vế đó thì tự mình chặn mình. Trả lại.

## Bắc cầu sang project

Code này **đã có sẵn** trong EH, phía app. Mở
`app/lib/features/booking/data/datasources/seat_lock_remote_datasource.dart`:

| Bài 18 | Code thật |
|---|---|
| Kho `seats` | Realtime Database, đường dẫn `eventState/{eventId}/seats/{seatCode}` (dòng 92–96) |
| Khoá `{status, userId, expiresAt}` | Dòng 173–177 |
| 2 phút | Dòng 12: `kSeatHoldWhileSelecting`, thật là **1 phút** |
| `lockSeat` | Dòng 140–195 |
| Lượt 4b: đã bán | Dòng 160–162: `if (existingStatus == 'sold') return Transaction.abort();` |
| Lượt 2 + 3: người khác, còn hạn | Dòng 165–170 |
| Chủ khoá bấm lại = gia hạn | Dòng 230–255, `extendSeatLock`: sang trang thanh toán thì hạn thành 5 phút (dòng 19) |
| "Quá hạn thì coi như không có" | Dòng 40–44: `isExpired`; màn hình tự coi khoá hết hạn là ghế trống |
| Ghi khoá `sold` | Không phải app: `functions/bookings/onBookingStatusChanged.js` dòng 81–89, trigger ghi khi đơn `confirmed` |

- **Lõi:** ba dòng điều kiện + `expiresAt`.
- **Vỏ:** `ref.runTransaction(...)` của Realtime Database (đọc khoá rồi ghi trong một bước: đúng bài 2, hai người bấm
  cùng lúc thì một người `abort`); đổi lỗi thành `ServerException('seat-locked-by-other')`.
- **Khoá hết hạn vẫn nằm đó:** job `functions/bookings/cleanupExpiredSeatLocks.js` chạy mỗi phút để dọn (dòng 74–79).
  Job chết thì hệ thống vẫn đúng, chỉ là kho bẩn.
- **Thử phá 1 là lỗ có thật:** dòng 147, app tự tính `expiresAt` bằng đồng hồ của máy người dùng.
  `database.rules.json` dòng 12 chỉ đòi `expiresAt` là một con số. gd4 Bước 4 sửa rules: bắt buộc có `expiresAt`,
  phải lớn hơn `now` **của server** và không quá 15 phút.
- **Chỗ framework làm hộ:** cả màn hình sơ đồ ghế của mọi người tự đổi màu khi một khoá xuất hiện, vì app nghe
  `onValue` (dòng 107–137). Đó là bài 16.
- Khoá này **chưa** chống được hai người mua cùng ghế. Vì sao: bài 20.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 1 (ghi đè), lượt 2 (ôm ghế mãi), lượt 4a (sập)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "A user selects a seat and walks away: what happens to
  that seat?"
