# Bài 16: màn hình nghe doc

**Lõi một câu:** trang thanh toán không chờ ai "báo xong". Nó **nghe doc của đơn**: vừa nghe là được đưa ngay **bản
hiện tại**, rồi mỗi lần doc đổi lại được đưa bản mới. Sự thật nằm ở doc trên server, nên app sập đúng lúc tiền về,
mở lại vẫn ra đúng "đã thanh toán".

Bài 5 đã cho thấy stream. Bài này là mảnh còn thiếu của nó (bài 5 thử phá 2: người nghe đến muộn không biết gì).

## Đề

`bai16.dart`: mọi thứ trong `main`, ba hàm nhỏ trong `main`, không package, khoảng 30 dòng.

- Doc của đơn chỉ có một thứ đáng quan tâm: `status`, ban đầu `pending`.
- "Màn hình vẽ lại" trong bài là một dòng in `<tên màn> thấy: <status>`.
- Mỗi lần một màn nhận dữ liệu từ server, biến `reads` tăng 1 (trong Firestore, mỗi lần như vậy là một lần đọc tính
  tiền).

Dòng thời gian:
1. An mở trang thanh toán trên điện thoại, và mở thêm một tab web.
2. Điện thoại **sập**.
3. Tiền về: server ghi đơn thành `confirmed`.
4. An mở lại app trên điện thoại.

Phải in ra đúng:

```
điện thoại thấy: pending
web thấy: pending
điện thoại sập
server ghi: confirmed
web thấy: confirmed
điện thoại thấy: confirmed
số lần đọc: 4
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Biến `status`. Hàm `update(next)` đóng vai server: ghi status mới, in `server ghi: ...`. Gọi `update('confirmed')`, in `status` | `server ghi: confirmed` và `confirmed` |
| 2 | Biến `reads`. Hàm `show(screen)`: `reads` tăng 1, in `<màn> thấy: <status>`. Hai màn **hỏi một lần lúc mở** (gọi `show` cho điện thoại và web), rồi mới `update` | `điện thoại thấy: pending`, `web thấy: pending`, `server ghi: confirmed`, `số lần đọc: 2` ← **tiền về rồi mà hai màn vẫn đứng ở "pending"** |
| 3 | Hỏi theo nhịp (polling): Set `open` giữ tên các màn đang mở; `watch(screen)` thêm màn vào `open` rồi `show`; `tick()` in `--- 3 giây sau` rồi `show` mọi màn đang mở. Thứ tự: mở 2 màn, `tick`, `tick`, `update`, `tick` | Màn có đổi sang `confirmed`, nhưng **sau** nhịp kế; `số lần đọc: 8`, trong đó 4 lần hỏi ra y như cũ |
| 4 | Nghe: xoá `tick`. `update` tự `show` mọi màn đang mở. `watch` **chỉ** thêm vào `open`. Chạy đủ dòng thời gian của đề (sập = xoá điện thoại khỏi `open`, in `điện thoại sập`) | `điện thoại sập`, `server ghi: confirmed`, `web thấy: confirmed`, `số lần đọc: 1` ← **lúc mở, cả hai màn trống trơn; điện thoại mở lại cũng trống** |
| 5 | `watch` = thêm vào `open` **và** `show` ngay một lần | Đủ 7 dòng như đề |

Ba cách sai, ba kiểu hỏng khác nhau:
- Lượt 2 (hỏi một lần): không bao giờ biết tiền đã về.
- Lượt 3 (hỏi theo nhịp): biết, nhưng trễ tới 3 giây và tốn gấp đôi số lần đọc. Nhịp nhanh hơn thì bớt trễ nhưng tốn
  hơn nữa.
- Lượt 4 (chỉ nghe thay đổi): nhanh và rẻ, nhưng ai mở sau lúc đổi thì không thấy gì. Đúng ca "app sập rồi mở lại".

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 3: gọi một hàm cho từng phần tử của Set

```dart
final khach = <String>{};
void chao(String ten) => print('chào $ten');
khach.add('Chi');
khach.add('Dũng');
khach.forEach(chao);
// chào Chi
// chào Dũng
```

`khach.forEach(chao)` là "gọi `chao` cho từng người". Đưa **tên hàm**, không có dấu `()`.

### Lượt 4: bỏ khỏi Set

`khach.remove('Chi');`

Để ý chiều đi của dữ liệu đã đảo: ở lượt 3 **màn hình đi hỏi** (`tick` gọi `show`), ở lượt 4 **server đưa tới**
(`update` gọi `show`). Hàm `show` vẫn vậy, người gọi nó thì khác.

## Thử phá

1. Xoá dòng bỏ điện thoại khỏi `open` (màn đã đóng nhưng quên **hủy nghe**). Chạy: dòng nào thừa, `số lần đọc` mấy?
   Một màn đã chết vẫn nhận dữ liệu và vẫn bị tính tiền đọc. Trong Flutter còn tệ hơn: màn đã đóng mà gọi vẽ lại là
   lỗi. Mở trang nào nghe thì đóng trang đó phải hủy.
2. Trả lại như cũ. Đổi dòng thời gian: tiền về **trước cả** lúc An mở trang (dời `update` lên đầu). Hai màn in gì
   lúc mở? Trang thanh toán thật phải xử lý ca này: mở ra mà đơn đã `confirmed` thì đi thẳng tới vé.

## Bắc cầu sang project

| Bài 16 | Code thật |
|---|---|
| `watch` + `update` gọi `show` | `app/lib/features/booking/presentation/view_models/payment/booking_payment_bloc.dart` dòng 218–232: `.collection('bookings').doc(bookingId).snapshots().listen(...)` |
| `show` | Dòng 226–230: đọc `paymentStatus`, thấy `confirmed` thì `add(_BookingPaymentStatusUpdated(...))`; trang đổi sang "Đặt vé thành công!" |
| `update('confirmed')` | Webhook trên server ghi doc (bài 15). **App không được ai báo**; nó chỉ đang nghe doc |
| Lượt 5: đưa ngay bản hiện tại | **Không có dòng nào.** `snapshots()` của Firestore luôn phát bản hiện tại trước, rồi mới tới các thay đổi |
| Thử phá 1: hủy nghe | Cùng file dòng 47–58, `close()`: `await _bookingStream?.cancel();` |
| Trang Vé của tôi | `booking_remote_datasource.dart` dòng 290–320, `watchMyBookings()`: cũng `snapshots()` |

- **Câu "app sập lúc tiền về":** tiền về là chuyện giữa PayOS và server; server ghi doc, không cần app sống. Mở lại
  app, trang Vé của tôi nghe danh sách đơn và nhận ngay bản hiện tại: đơn đã `confirmed`, có mã QR vé. App còn nhớ
  mã đơn đang trả dở (`booking_payment_bloc.dart` dòng 116, `savePendingBookingId`) để mở lại đúng trang.
- **Vì sao vẫn có polling trong EH:** `app/lib/features/auth/presentation/view_models/verify_email/verify_email_cubit.dart`
  dòng 22–24, `Timer.periodic(_pollInterval, (_) => _poll())`, 3 giây một lần. Đó là lượt 3 của bạn. Nó phải hỏi
  theo nhịp vì "email đã xác minh chưa" nằm trong Firebase Auth, **không phải một doc để nghe**: người dùng bấm link
  trong trình duyệt, app không được ai báo, chỉ biết khi tự `reload()`. Có thứ để nghe thì nghe; không có thì mới
  hỏi theo nhịp.
- **Vỏ:** `StreamSubscription`, Bloc đổi sự kiện thành state, `BlocListener` điều hướng (bài 31).
- Bài 12 lượt 7 để lại một chỗ TẠM: trang phải tải lại mới thấy thay đổi. Bài 17 cho trang thanh toán nghe đơn thật,
  qua mạng.

## Xong khi

- [ ] In đúng 7 dòng như đề
- [ ] Đã thấy cả ba kiểu hỏng (lượt 2, 3, 4)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm hai câu trả lời: "Payment succeeded but the app crashed before showing
  it: what does the user see?" và "Polling vs listening to a stream: when do you use each?"
