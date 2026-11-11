# Bài 9: ghi vào bản nháp

**Lõi một câu:** trong transaction, lệnh ghi chưa chạm vào kho: nó ghi vào một **bản nháp**. Hàm chạy tới cuối không
lỗi thì áp cả bản nháp một lần; hỏng giữa chừng thì vứt nháp, kho y như chưa có gì xảy ra. **Tất cả, hoặc không gì
cả.**

Bài 2 là nửa kia của transaction (bị chen thì làm lại). Bài này là nửa "một lần đặt vé ghi nhiều chỗ".

## Đề

`bai9.dart`: mọi thứ trong `main`, một hàm nhỏ trong `main`, không package, khoảng 20 dòng.

Kho là một Map ba số: `đơn` (số đơn đã tạo), `đã bán` (số vé đã bán), `đơn của An` (số đơn An đã đặt, dùng cho hạn
mức). Cả ba bắt đầu từ 0. Một lần đặt vé phải ghi **cả ba**.

Dòng thời gian:
1. An đặt 2 vé: trót lọt.
2. An đặt 2 vé nữa, nhưng server **mất điện** ngay sau lệnh ghi đầu tiên.

Phải in ra đúng:

```
lần 1: xong
lần 2: hỏng giữa chừng (mất điện)
{đơn: 1, đã bán: 2, đơn của An: 1}
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Kho (Map), in ra | `{đơn: 0, đã bán: 0, đơn của An: 0}` |
| 2 | Hàm `book(quantity)` ghi thẳng vào kho ba dòng: `đơn` + 1, `đã bán` + số vé, `đơn của An` + 1. Gọi một lần | `lần 1: xong` và `{đơn: 1, đã bán: 2, đơn của An: 1}` |
| 3 | `book` nhận thêm `crash`: nếu `true` thì ném lỗi `'mất điện'` **giữa** dòng ghi 1 và dòng ghi 2. Gọi lần 2 với `crash: true`, bọc `try/catch` | `{đơn: 2, đã bán: 2, đơn của An: 1}` ← **2 đơn mà chỉ bán 2 vé: một đơn ma** |
| 4 | Trong `book`: tạo Map `draft` rỗng, ba dòng ghi đổi sang ghi vào `draft` (vẫn **đọc** từ kho). Cuối hàm in `nháp: ...` | `nháp: {đơn: 1, đã bán: 2, đơn của An: 1}` nhưng kho vẫn `{đơn: 0, đã bán: 0, đơn của An: 0}` |
| 5 | Dòng in nháp đổi thành: đổ cả `draft` vào kho | Đủ 3 dòng như đề |

Lượt 3 là cái hỏng: không có lỗi logic nào, mọi dòng đều đúng, chỉ là chương trình dừng **giữa hai dòng ghi**. Server
thật dừng giữa chừng vì đủ lý do: mất mạng tới database, hết thời gian chạy, một dòng phía dưới ném lỗi.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: cộng vào một ô của Map

```dart
final diem = {'An': 7};
diem['An'] = diem['An']! + 1;
print(diem); // {An: 8}
```

Tra Map ra kiểu có thể null (bài 4), nên cần `!` trước khi cộng.

### Lượt 3: ném lỗi và bắt lỗi

```dart
void nau(bool hetGas) {
  print('bắc nồi');
  if (hetGas) throw 'hết gas';
  print('chín');
}

try {
  nau(true);
  print('ăn thôi');
} catch (e) {
  print('nhịn: $e');
}
// bắc nồi
// nhịn: hết gas
```

- `throw` dừng hàm **ngay tại dòng đó**: `chín` không in.
- Nó cũng nhảy qua phần còn lại của khối `try`: `ăn thôi` không in. Chương trình chạy tiếp từ `catch`.
- Dòng đã chạy trước `throw` (`bắc nồi`) thì **đã chạy rồi**, không ai hoàn lại. Đó là gốc của cái hỏng ở lượt này.

### Lượt 4, 5: Map nháp

```dart
final that = {'a': 1, 'b': 2};
final nhap = <String, int>{};
nhap['a'] = that['a']! + 10;
print(that); // {a: 1, b: 2}  <- chưa đổi
that.addAll(nhap);
print(that); // {a: 11, b: 2}
```

`addAll` đổ mọi cặp của Map kia vào Map này, trùng key thì ghi đè. Nghĩ xem nó phải nằm **trước** hay **sau** dòng
`throw`.

## Thử phá

1. Dời dòng `db.addAll(draft)` lên ngay dưới dòng ghi nháp đầu tiên. Chạy: kho ra gì? Áp nháp sớm thì nháp vô nghĩa.
2. Trả lại như cũ. Ngay dưới dòng ghi nháp đầu tiên, thêm `print('đọc lại: ${db['đơn']}');`. Bạn vừa "ghi" `đơn` mà
   đọc lại vẫn ra số cũ. Code nào đọc sau khi ghi rồi tính tiếp trên số đó là tính sai. Firestore không cho bạn mắc
   lỗi này: trong transaction, đọc sau khi đã ghi là nó ném lỗi. Vì vậy mới có luật **đọc hết trước, ghi sau**.

## Bắc cầu sang project

`tx` trong `db.runTransaction(async (tx) => {...})` **chính là bản nháp** của bạn.

| Bài 9 | Code thật |
|---|---|
| Đọc từ kho | `tx.get(...)`, `tx.getAll(...)` |
| Ghi vào `draft` | `tx.set(...)`, `tx.update(...)` |
| `throw` giữa chừng → nháp bị vứt | `throw new HttpsError(...)` trong hàm |
| `db.addAll(draft)` | Không có dòng nào: hàm `return` là Firestore tự áp nháp (commit) |
| Thử phá 2 | Luật "đọc trước ghi sau" |

- **Code bạn đã gõ:** `functions/src/auth/completeSignUp.ts` dòng 19–47. Dòng 20 đọc, dòng 22 có thể `throw`, dòng 42
  ghi nháp. Chỉ một lệnh ghi nên chưa thấy rõ "tất cả hoặc không".
- **Bạn sẽ gõ ở gd3 Chặng 2.1**, `createBooking.ts`: **một** `tx.getAll(bookingRef, eventRef, detailRef, buyerRef,
  userRef)`, rồi **bốn** lệnh ghi nháp: `tx.set(bookingRef, ...)` (đơn), `tx.update(detailRef, ...)` (kho từng loại
  vé), `tx.update(eventRef, ...)` (tổng đã bán), `tx.set(buyerRef, ...)` (số đơn của người mua). Ba số của bài này
  chính là ba chỗ đó.
- **Bản đang chạy phía app** cũng cùng hình: `booking_remote_datasource.dart` dòng 98–256. Dòng 101 có sẵn câu chú
  thích "mọi get() phải chạy trước set/update"; bốn lệnh ghi ở dòng 233, 237, 242, 247.
- **Lượt 3 có thật trong EH:** `functions/bookings/onBookingStatusChanged.js` dòng 64 và 66 gọi **hai transaction
  riêng**: trả kho, rồi mới trả hạn mức. Function chết giữa hai dòng đó thì kho đã trả mà hạn mức chưa. gd3 Chặng 3.2
  (`release.ts`) gom đổi trạng thái + trả kho + trả hạn mức vào **một** transaction.
- **Framework làm hộ, code không có dòng nào:** áp nháp; và lúc áp thì kiểm "có ai ghi chen vào thứ mình đã đọc
  không", có thì vứt nháp và **chạy lại cả hàm** (bài 2 lượt 4–5). Vì hàm có thể chạy lại nhiều lần, đừng làm trong
  đó việc không hoàn lại được như gọi PayOS hay gửi email (gd4 Chặng 1.3 để lời gọi PayOS **ngoài** transaction).
- `db.batch()` (`functions/bookings/expireBookings.js` dòng 30–40) là bản nháp **không có phần đọc**: ghi nhiều chỗ,
  áp một lần.

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thấy "đơn ma" ở lượt 3
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What does a Firestore transaction guarantee?" (hai ý: bài
  2 và bài này)
