# Bài 3: bấm hai lần vẫn chỉ một đơn

**Lõi một câu:** idempotency (gửi một yêu cầu nhiều lần cũng chỉ có tác dụng một lần) là đặt tên đơn theo **mã ý
định** của người mua; tên đó có rồi thì trả lại đơn cũ, **không tạo mới, không ghi đè**.

## Đề

`bai3.dart`: mọi thứ trong `main`, được dùng một hàm nhỏ trong `main` như bài 2, không package, dưới 30 dòng.

Dòng thời gian:
1. An bấm "Đặt vé". App sinh mã ý định `a1` cho lần bấm này.
2. An trả tiền xong, đơn thành `paid`.
3. Mạng chập chờn, app **gửi lại** đúng yêu cầu cũ (vẫn mã `a1`).
4. An đặt thêm một đơn khác hẳn: mã mới `a2`.

Phải in ra đúng:

```
An_a1: tạo mới
An_a1: đã có, trả lại đơn cũ
An_a2: tạo mới
Đơn: {An_a1: paid, An_a2: pending}
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Map đơn hàng rỗng (tên đơn → trạng thái), in ra | `Đơn: {}` |
| 2 | Hàm `create(user, intent)`: tên đơn = `don` + số thứ tự, trạng thái `pending`, in "tạo mới". Gọi `create('An', 'a1')` **hai lần** (An bấm hai lần) | `{don1: pending, don2: pending}` ← **bấm 2 lần ra 2 đơn** |
| 3 | Tên đơn đổi thành `user_intent`. Viết đủ 4 bước dòng thời gian của đề | `{An_a1: pending, An_a2: pending}` ← **trả tiền rồi mà đơn quay về chờ** |
| 4 | Tên đơn có rồi thì in "đã có, trả lại đơn cũ" và dừng | Đủ 4 dòng như đề |

Lượt 2 và 3 cố ý ra **sai**, mỗi lượt một kiểu sai. Lượt 3 nguy hiểm hơn: số đơn trông đúng (2 đơn), nhưng An đã trả
tiền mà app lại báo "chờ thanh toán".

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: Map rỗng

```dart
final phones = <String, String>{};
print('Danh bạ: $phones'); // Danh bạ: {}
```

Rỗng thì Dart không đoán được kiểu, nên ghi `<kiểu key, kiểu value>`, giống `<String>[]` ở bài 2.

### Lượt 2: thêm vào Map, đếm Map

```dart
phones['Chi'] = '0901';
print(phones.length); // 1
```

- `map[key] = value`: chưa có key thì thêm mới, **có rồi thì ghi đè** (nhớ câu này cho lượt 3).
- `.length` là số phần tử đang có. Đơn thứ mấy = số đơn đang có + 1.
- Hàm nhỏ trong `main`: y như hàm `write` bạn viết ở bài 2.

### Lượt 3: ghép chuỗi có dấu `_`

```dart
final name = 'Chi';
print('${name}_01'); // Chi_01
print('$name-01'); // Chi-01
```

Phải có `{}` khi ngay sau tên biến là chữ, số hoặc `_`. Viết `'$name_01'` thì Dart hiểu là biến tên `name_01`, báo
lỗi không tìm thấy.

Bước 2 của dòng thời gian (tiền về) không gọi hàm, chỉ là một dòng gán trạng thái `paid` cho đơn đó.

### Lượt 4: có rồi thì dừng

- Map có hàm `containsKey(key)` trả `true`/`false`.
- Dừng hàm sớm bằng `return;`, giống bài 2.

## Thử phá

1. Xoá phần kiểm `containsKey`. Chạy lại, đơn `An_a1` còn `paid` không?
2. Trả lại như cũ, rồi đổi tên đơn về kiểu đếm `don1, don2...`. Chạy lại: kiểm `containsKey` còn cứu được không? Vì sao?

## Bắc cầu sang project

`gd03_phan_server.md`, đoạn `createBooking`:
- dòng tạo `bookingId` từ `uid` và `bookingIntentId`
- dòng `if (bookingSnap.exists)` trả về `duplicate: true`

Tự ghép với lượt 3 và lượt 4. Rồi nghĩ: `bookingIntentId` do **ai** sinh ra, lúc **nào**? (Gợi ý: nếu sinh lại mỗi lần
gửi thì chuyện gì xảy ra — chính là lần thử phá số 2.)

Webhook thanh toán gửi tới 2 lần (gd4) cũng là cùng ý này: có dấu "đã xử lý" rồi thì bỏ qua.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy cả hai kiểu sai ở lượt 2 và lượt 3
- [ ] Đã thử phá cả hai cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What is idempotency, and how did you implement it?"
