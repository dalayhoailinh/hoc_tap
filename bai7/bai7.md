# Bài 7: ai nói giá?

**Lõi một câu:** app chỉ gửi **ý định** (loại vé nào, mấy vé); giá và tổng tiền do server tra từ bảng giá của chính
nó. App có gửi kèm số tiền thì server không đọc tới.

## Đề

`bai7.dart`: mọi thứ trong `main`, được dùng một hàm nhỏ trong `main` như bài 2–4, không package, khoảng 20 dòng.

- Bảng giá nằm ở server: vé `thuong` 100000, vé `vip` 500000.
- Một đơn tối đa 10 vé.
- Bốn yêu cầu gửi lên (mỗi yêu cầu là một Map):
  1. "app thật": `type: 'vip'`, `quantity: 2`, `totalAmount: 1000000`
  2. "kẻ sửa giá": `type: 'vip'`, `quantity: 2`, `totalAmount: 2000`
  3. "loại vé bịa": `type: 'free'`, `quantity: 1`
  4. "số lượng âm": `type: 'vip'`, `quantity: -1`

Phải in ra đúng:

```
app thật: 1000000
kẻ sửa giá: 1000000
loại vé bịa: từ chối
số lượng âm: từ chối
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Bảng giá (Map) và yêu cầu "app thật" (Map), in cả hai | `{thuong: 100000, vip: 500000}` và `{type: vip, quantity: 2, totalAmount: 1000000}` |
| 2 | Gom "app thật" + "kẻ sửa giá" vào một Map lồng Map. Hàm `createBooking(request)` **tin app**: trả luôn `totalAmount` trong yêu cầu. Vòng lặp in kết quả | `app thật: 1000000` và `kẻ sửa giá: 2000` ← **2 vé VIP giá 2000 đồng** |
| 3 | `createBooking` thôi đọc `totalAmount`: tra giá trong bảng giá, nhân với số lượng | `kẻ sửa giá: 1000000` |
| 4 | Thêm yêu cầu "loại vé bịa" | Hai dòng đầu, rồi **sập**: `Null check operator used on a null value` |
| 5 | Không có loại vé đó thì trả `null`; lúc in, `null` thành chữ `từ chối` | `loại vé bịa: từ chối` |
| 6 | Thêm yêu cầu "số lượng âm" | `số lượng âm: -500000` ← **server nợ ngược lại người mua nửa triệu** |
| 7 | Số lượng phải từ 1 tới 10, ngoài khoảng đó thì từ chối | Đủ 4 dòng như đề |

Lượt 2 và lượt 6 cố ý ra **sai**. Nhìn kỹ lượt 2: không có lỗi nào hiện ra, đơn trông hoàn toàn bình thường, chỉ có
số tiền là do người mua tự điền.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: lấy một số ra khỏi Map trộn kiểu

```dart
final order = {'mon': 'phở', 'soBat': 3};
final soBat = order['soBat'] as int;
print(soBat + 1); // 4
```

- Map vừa có chữ vừa có số thì Dart coi value là `Object` (cái gì cũng được). Muốn cộng trừ nhân chia thì phải nói rõ
  "cái này là số": `as int`.
- Kiểu của một yêu cầu: `Map<String, Object>`. Hàm trả số nhưng lượt 5 sẽ cần trả `null`, nên khai luôn kiểu trả về
  là `int?`.

### Lượt 3: tra Map bằng một giá trị lấy từ Map khác

```dart
final gia = {'phở': 40, 'bún': 45};
final order = {'mon': 'bún', 'soBat': 3};
print(gia[order['mon']]); // 45
```

Tra Map ra kiểu "có thể null" (bài 4 lượt 3). Lượt này cứ hứa bằng `!` cho gọn; lượt 4 sẽ cho thấy hứa sai thì sao.

### Lượt 5: null thì in chữ khác

```dart
int? tuoi;
print(tuoi ?? 'chưa biết'); // chưa biết
```

`a ?? b`: `a` khác null thì lấy `a`, null thì lấy `b`. Bỏ dấu `!` ở lượt 3 đi, kiểm `== null` rồi `return null;`.

### Lượt 7: hai điều kiện "hoặc"

`a || b`: một trong hai đúng là đúng. Nối thêm vào chính dòng `if` của lượt 5.

## Thử phá

1. Trong `createBooking`, đổi dòng `return` cuối thành `return request['totalAmount'] as int?;`. Chạy: dòng nào đổi?
   Phần kiểm loại vé và số lượng vẫn còn nguyên mà kẻ sửa giá vẫn lọt: kiểm kỹ mấy cũng vô ích nếu con số cuối cùng
   vẫn lấy từ app. Xong nhớ đổi lại.
2. Bỏ phần kiểm số lượng, đổi yêu cầu 4 thành `quantity: 1000000`. Ra bao nhiêu? Một người ôm hết vé của sự kiện.

## Bắc cầu sang project

**Hiện tại EH đang ở đúng lượt 2**, ở hai chỗ:

- `app/lib/features/booking/data/datasources/booking_remote_datasource.dart` dòng 187–190: `totalAmount` được tính
  **trong app**, từ `item.price` mà app đang giữ. `firestore.rules` dòng 247–250 chỉ kiểm `userId` và `status`, không
  nhìn tới tiền. Đây là lỗ L1.
- `functions/payos/createPayosOrder.js` dòng 17: `const { bookingId, amount, description } = request.data;` rồi dòng
  63 gửi nguyên `amount` đó cho PayOS. Đây là lỗ L3.

**Bạn sẽ gõ lượt 3–7 ở gd3**, `gd03_phan_server.md` Chặng 1.1:

| Bài 7 | Code thật |
|---|---|
| Yêu cầu chỉ còn ý định | `types.ts`: `createBookingSchema` chỉ có `eventId`, `bookingIntentId`, `items[{ticketTypeId, quantity}]`. Không có `price`, `totalAmount` |
| Lượt 7: số lượng 1–10 | `quantity: z.number().int().min(1).max(MAX_TICKETS_PER_BOOKING)` |
| Lượt 5: loại vé bịa | `planBooking.ts`: `const type = ticketTypes.find(...)`, `if (!type) return reject("ticket-type-not-found", ...)` |
| Lượt 3: giá × số lượng | `planBooking.ts`: `totalAmount += type.price * item.quantity;` |
| Bảng giá của server | `private/detail.ticketTypes`, đọc **trong transaction** của `createBooking` (Chặng 2.1) |

- **Lõi** là đúng một dòng: `type.price * item.quantity`, với `type` lấy từ dữ liệu của server.
- **Vỏ:** zod (thư viện kiểm hình dạng dữ liệu vào: field lạ như `totalAmount` nó lặng lẽ bỏ đi), `HttpsError`, một
  đơn nhiều loại vé (`items` là mảng), đọc bảng giá từ Firestore.
- gd4 lặp lại y ý này cho PayOS: `createPayosOrder.ts` (Chặng 1.3) chỉ nhận `bookingId`, số tiền là
  `booking.totalAmount` mà `createBooking` đã tính.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 2 (2000 đồng) và lượt 6 (-500000)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Why must the server, not the app, decide the price?"
