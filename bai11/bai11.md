# Bài 11: hai cửa vào kho

**Lõi một câu:** kho có **hai cửa**: cửa app (mỗi lần ghi phải qua rules) và cửa server (code của mình chạy trên
server, ghi thẳng, rules không hỏi tới). Viết xong hàm server tính tiền đúng mà cửa app vẫn mở thì kẻ xấu cứ đi cửa
cũ. Đóng lỗ là: chuyển việc ghi sang cửa server, **rồi khoá cửa app**.

## Đề

`bai11.dart`: mọi thứ trong `main`, ba hàm nhỏ trong `main`, không package, khoảng 25 dòng.

- Giá vé: 100000.
- An là người mua thật: 2 vé.
- Kẻ xấu muốn có vé `confirmed` mà không trả đồng nào.

Phải in ra đúng:

```
an gọi server tạo don1: xong
ke_xau ghi don2 qua cửa app: bị chặn
{don1: {userId: an, status: pending, totalAmount: 200000}}
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Kho `bookings` (Map: mã đơn → doc). Hàm `clientWrite(uid, id, doc)` ghi thẳng doc vào kho, in `... qua cửa app: cho qua`. An tự ghi đơn của mình: `userId: 'an'`, `status: 'pending'`, `totalAmount: 200000` | `an ghi don1 qua cửa app: cho qua` và kho có `don1` |
| 2 | Hàm `rules(uid, doc)` trả `true`/`false`: `userId` trong doc phải là người đang ghi, `status` phải là `pending` hoặc `confirmed`. `clientWrite` hỏi `rules` trước, sai thì in `bị chặn` và dừng. Thử: kẻ xấu ghi một đơn mang `userId: 'an'` | `ke_xau ghi don2 qua cửa app: bị chặn` |
| 3 | Kẻ xấu đổi cách: `userId: 'ke_xau'`, `status: 'confirmed'`, `totalAmount: 0` | `ke_xau ghi don2 qua cửa app: cho qua` ← **đúng luật từng chữ, có vé 0 đồng** |
| 4 | Cửa server: hàm `createBooking(uid, id, quantity)` tự tính tiền (bài 7), ghi thẳng vào kho, **không hỏi `rules`**. An đổi sang gọi nó | `an gọi server tạo don1: xong`, nhưng `don2` của kẻ xấu **vẫn lọt** |
| 5 | Khoá cửa app: `rules` trả `false` cho mọi lần ghi | Đủ 3 dòng như đề |

Lượt 4 là cái hỏng đáng nhớ nhất: bạn vừa viết xong một hàm server đẹp, tính tiền đúng, và **không có gì thay đổi**
với kẻ xấu. Nó không gọi hàm của bạn. Nó đi cửa cũ.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: Map lồng Map, rỗng

```dart
final lop = <String, Map<String, Object>>{};
lop['hs1'] = {'ten': 'Chi', 'diem': 8};
print(lop); // {hs1: {ten: Chi, diem: 8}}
```

### Lượt 2: hỏi "có nằm trong mấy giá trị này không"

```dart
print({'đỏ', 'vàng'}.contains('xanh')); // false
```

Một Set viết ngay tại chỗ (bài 1). Hai điều kiện cùng phải đúng thì nối `&&`.

Dừng hàm sớm khi bị chặn: `if (!rules(uid, doc)) { print(...); return; }`. Dấu `!` đứng trước là "không".

### Lượt 4: hằng số

`const price = 100000;` đặt đầu `main`. Hàm `createBooking` tự dựng doc: `userId` là người gọi, `status` luôn
`pending`, `totalAmount` do nó nhân ra. Người gọi **không đưa doc**, chỉ đưa số lượng.

## Thử phá

1. Quay về rules của lượt 4, thử "vá bằng rules": thêm điều kiện `&& (doc['totalAmount'] as int) > 0`. Kẻ xấu đổi
   `totalAmount` thành `1`. Lọt không? Rules chỉ nhìn được **hình dạng** của doc gửi lên; nó không biết giá đúng là
   bao nhiêu. Thêm điều kiện là chạy đua với kẻ xấu, thua chắc.
2. Về lại lượt 5. Cho An quay lại dùng `clientWrite` như lượt 1. Chuyện gì xảy ra với người mua thật? Đây là lý do
   thứ tự không đảo được: **có cửa server và app đã gọi nó trước, khoá cửa app sau**. Khoá trước là app chết.

## Bắc cầu sang project

| Bài 11 | Code thật |
|---|---|
| Cửa app `clientWrite` | App ghi bằng SDK client: `booking_remote_datasource.dart` dòng 233 `transaction.set(bookingRef, ...)` |
| `rules` của lượt 2 | `firestore.rules` dòng 247–250: `request.resource.data.userId == request.auth.uid && request.resource.data.status in ['pending', 'confirmed']`. **Y hệt, EH đang ở lượt 3** |
| Kẻ xấu lượt 3 | Lỗ L1 trong `05_sua_v1.md`; đòn "Đơn giả" đầu guide gd3 |
| Cửa server `createBooking` | Callable chạy trên Cloud Functions, ghi bằng **Admin SDK**: `getFirestore()` trong `functions/src/**` (bạn đã dùng ở `completeSignUp.ts` dòng 17) |
| "Không hỏi `rules`" | **Không có dòng nào.** Admin SDK luôn bỏ qua rules, đó là thiết kế của Firebase |
| Lượt 5 | gd3 Chặng 4.2, chỗ ⑤: `allow create: if false;` cho `bookings`; chỗ ③ `allow create, update: if false;` cho `buyers` |
| Thử phá 2 | Guide gd3: "phải có `createBooking`, `cancelBooking` và app đã gọi chúng **trước**, rồi mới khoá" |

- **Lõi:** `if false` ở cửa app + hàm server là nơi duy nhất còn ghi được.
- **Vỏ:** `allow read` vẫn mở cho chủ đơn (app vẫn **đọc** thẳng để hiện Vé của tôi); nhà tổ chức và nhân viên vẫn
  được sửa đúng hai field check-in (đó là bài 1); test kẻ tấn công chạy trên emulator (gd3 Chặng 4.1: 6 đòn **đỏ**
  trên rules cũ rồi mới xanh).
- **Cửa server không qua rules thì ai kiểm?** Chính code của bạn: `request.auth` (bài 4), zod, `planBooking` (bài 7,
  8). Rules không cứu được một callable viết ẩu.
- **Mẫu "chỉ server được ghi" đã có sẵn trong EH**, mở ra xem: `firestore.rules` dòng 208 (`staff_attendance`), 335
  (`withdrawals`), 343 (`refunds`): `allow create, update, delete: if false;`.
- **gd1 Bước 4 là đúng bài này cho doc user:** server tạo `users/{uid}` (`onUserCreated`, `completeSignUp`), rồi
  rules thôi cho app tự tạo và chỉ cho sửa vài field (bài 1).

Bốn câu hỏi để đọc bất kỳ function nào trong EH: **ai gọi** (app hay database), **đi cửa nào** (rules hay Admin SDK),
**tin cái gì từ bên ngoài** (chỉ ý định), **ghi mấy chỗ** (một transaction hay nhiều).

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thấy lượt 3 và lượt 4 (có hàm server rồi mà kẻ xấu vẫn lọt)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do Firestore Security Rules protect data?" (ghép với
  bài 1: rules làm được gì, không làm được gì, và khi nào phải chuyển việc ghi lên server)
