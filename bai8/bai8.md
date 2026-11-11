# Bài 8: hàm quyết định không tự xem đồng hồ

**Lõi một câu:** phần "được hay không, vì sao" viết thành một **hàm thuần**: mọi thứ nó cần, kể cả "bây giờ là mấy
giờ", đều đưa vào qua tham số; nó trả `null` (được) hoặc một **mã lý do**. Nhờ vậy thử một ca chỉ tốn một dòng.

## Đề

`bai8.dart`: mọi thứ trong `main`, hai hàm nhỏ trong `main`, không package, khoảng 30 dòng.

Luật hủy vé: chỉ **chủ đơn** được hủy, chỉ đơn **`confirmed`**, và chỉ khi sự kiện **chưa bắt đầu**.

- Đơn của An: `userId: 'an'`, `status: 'confirmed'`, sự kiện bắt đầu 19:00 ngày 24/12/2030.
- Hai mốc giờ để thử: 18:00 và 20:00 cùng ngày.

Phải in ra đúng:

```
OK   An hủy lúc 18:00
OK   Bình hủy đơn của An
OK   An hủy lúc 20:00 đêm diễn
OK   An hủy đơn chưa trả tiền
OK   An hủy đơn không có
5/5 ca đúng
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Đơn của An (Map, giờ bắt đầu là một `DateTime`), in ra | `{userId: an, status: confirmed, startAt: 2030-12-24 19:00:00.000}` |
| 2 | Hàm `canCancel(booking, uid)` trả `true`/`false`, tự lấy giờ bằng `DateTime.now()`. Thử An và Bình | `An hủy: true` và `Bình hủy đơn của An: false` |
| 3 | Thử thêm ca "An hủy lúc 20:00 đêm diễn" | `An hủy lúc 20:00 đêm diễn: true` ← **không có cách nào bảo hàm "giả vờ bây giờ là 20:00"** |
| 4 | `canCancel` nhận thêm tham số `now`. Hai biến `before` (18:00), `after` (20:00) | `An hủy lúc 18:00: true`, `Bình...: false`, `An hủy lúc 20:00 đêm diễn: false` |
| 5 | Trả **mã lý do** thay cho `true`/`false`: được thì `null`, không thì `not-owner`, `not-cancellable`, `event-started`. Thêm ca đơn `pending` | `null`, `not-owner`, `event-started`, `not-cancellable` |
| 6 | Ca "đơn không có": truyền `null` thay cho đơn, mã `booking-not-found` | Thêm dòng `An hủy đơn không có: booking-not-found` |
| 7 | Hàm `check(name, actual, expected)` in `OK` hoặc `SAI`, đếm số ca đúng. Đổi 5 dòng `print` thành 5 dòng `check` | Đủ 6 dòng như đề |

Lượt 3 là cái hỏng của bài: hàm tự xem đồng hồ thì kết quả phụ thuộc **ngày bạn chạy**. Hôm nay nó in `true`; tới
năm 2031 cùng file đó in `false`. Và ca "sau giờ diễn" không thử được nếu không sửa dữ liệu.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: so giờ

```dart
final dong = DateTime(2030, 1, 1, 22, 0); // quán đóng 22:00
print(DateTime.now().isBefore(dong)); // true tới hết năm 2029
```

- Lấy `DateTime` ra khỏi Map trộn kiểu cũng cần `as DateTime`, như `as int` ở bài 7.
- Viết ba dòng `if (...) return false;` nối nhau rồi `return true;` ở cuối. Mỗi luật một dòng, dễ đọc hơn một dòng
  `&&` dài.
- "Chưa bắt đầu" là `now.isBefore(start)`. Đúng 19:00 thì đã bắt đầu, nên điều kiện chặn là `!now.isBefore(start)`.

### Lượt 5: `String?` làm câu trả lời

```dart
String? vaoQuan(int tuoi) {
  if (tuoi < 18) return 'chua-du-tuoi';
  return null;
}
print(vaoQuan(15)); // chua-du-tuoi
print(vaoQuan(20)); // null
```

`null` nghĩa là "không có lý do nào để chặn". Mã viết kiểu `chu-thuong-gach-ngang` vì nó dành cho **máy** so sánh;
câu cho người đọc là chuyện của app.

Đơn `pending`: chép đơn cũ, đổi một field (bài 1 lượt 4).

### Lượt 6: tham số có thể null

Đổi kiểu tham số thành `Map<String, Object>?`. Kiểm `== null` **đầu tiên**, vì các dòng dưới đều lấy field của đơn.

### Lượt 7: tự viết `check`

```dart
var passed = 0;
void check(String name, int actual, int expected) {
  if (actual == expected) passed++;
  print(actual == expected ? 'OK   $name' : 'SAI  $name: ra $actual, mong $expected');
}
check('một cộng một', 1 + 1, 2); // OK   một cộng một
check('hai nhân hai', 2 * 2, 5); // SAI  hai nhân hai: ra 4, mong 5
```

Bài mình: `actual` và `expected` là `String?`. Dòng cuối in `$passed/5 ca đúng`: đếm để biết ca nào cũng **đã chạy**,
không phải lặng lẽ bị bỏ qua.

## Thử phá

1. Xoá dòng kiểm chủ đơn. Chạy: ca nào `SAI`, mấy trên 5? Đây là việc của test: bạn lỡ tay xoá một luật, nó kêu.
2. Trả lại như cũ. Thêm ca thứ 6: `check('An hủy đúng 19:00', canCancel(booking, 'an', start), 'event-started');`
   (nhớ sửa `/5` thành `/6`). Chạy phải `OK`. Giờ đổi `!now.isBefore(...)` thành `now.isAfter(...)`: ca đó `SAI`. Hai
   cách viết trông như nhau, chỉ khác nhau **đúng một giây ở ranh**; không có ca thử ở ranh thì không ai thấy.

## Bắc cầu sang project

**Code bạn đã gõ ở gd1** là đúng khuôn này:

- `functions/src/auth/signUp.ts` dòng 27–29: `canCompleteSignUp(currentRole)` là hàm thuần, chỉ nhận một giá trị, trả
  được/không. Dòng 10–24 `parseSignUpInput` trả `null` khi dữ liệu sai.
- `functions/src/auth/completeSignUp.ts` dòng 20–21: vỏ đọc doc (`tx.get`) rồi **đưa** `snapshot.get("role")` cho hàm
  thuần. Hàm thuần không biết Firestore là gì.
- `functions/src/auth/signUp.test.ts`: `expect(input).toEqual(...)` chính là `check` của bạn, do thư viện vitest viết
  sẵn (thêm phần gom nhóm `describe`/`it` và đếm).

**Bạn sẽ gõ ở gd3, gd4** (cùng khuôn, bốn lần):

| Hàm thuần | Ở đâu | Trả gì |
|---|---|---|
| `canCancel({booking, uid, nowMs})` | gd3 Chặng 3.1, `cancelPolicy.ts` | Gần như y bài này: `booking-not-found`, `not-owner`, `not-cancellable`, `event-started` |
| `planBooking({..., nowMs})` | gd3 Chặng 1.1 | `{ok: true, plan}` hoặc `{ok: false, code, message}` |
| `canPay({booking, uid, nowMs})` | gd4 Chặng 1.2, `payPolicy.ts` | `null` hoặc mã |
| `decidePayment(booking, paidAmount)` | gd4 Chặng 3.2 | Một trong 4 mã |

- **Lõi:** ba dòng `if (...) return 'mã';` và tham số `nowMs`. Giờ thật chỉ xuất hiện ở vỏ: `cancelBooking.ts` gọi
  `canCancel({..., nowMs: Date.now()})`.
- **Vỏ:** `onCall`, kiểm đăng nhập, zod, đọc doc trong transaction, đổi mã thành
  `HttpsError("failed-precondition", câu cho người đọc, { code: mã })`.
- Thử phá 2 có thật trong guide: `cancelPolicy.test.ts` có ca `eventStartAtMs: NOW` mong `event-started`.
- Flutter cũng có một hàm như vậy: `app/lib/core/routes/route_policy.dart` dòng 32 `decideRedirect(...)`, thử bằng
  bảng ca trong `app/test/core/routes/route_policy_test.dart`.
- **Hiện tại EH làm ngược:** luật hủy nằm trong app, `booking_remote_datasource.dart` dòng 389–399, trộn chung với
  lệnh đọc và ghi Firestore, nên không có test nào cho nó.

## Xong khi

- [ ] In đúng 6 dòng như đề
- [ ] Đã thấy lượt 3 không thử được ca "sau giờ diễn"
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What is a unit test, and what makes code easy to unit
  test?" (một nửa của câu "Unit vs widget vs integration test")
