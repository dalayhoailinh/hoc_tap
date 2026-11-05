# Bài 2: hai người, một vé cuối

**Lõi một câu:** transaction là trước khi ghi, kiểm xem từ lúc mình đọc tới giờ có ai ghi chen không; có thì
**đọc lại và làm lại** với số mới.

## Đề

`bai2.dart`: mọi thứ trong `main`, không tách hàm, không package, khoảng 30 dòng. Không dùng `async`: tự viết ra
từng bước theo đúng thứ tự thời gian.

Kho còn **1 vé**. An và Bình **cùng mở trang một lúc**, nên cả hai cùng đọc thấy "còn 1 vé". An bấm mua trước, Bình
bấm sau một chút.

Phải in ra đúng:

```
Bình: bị chen, đọc lại
Bình: hết vé
Đã bán: [An], còn 0 vé
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Số vé còn (`stock`), danh sách người đã mua (rỗng), một dòng in tổng kết | `Đã bán: [], còn 1 vé` |
| 2 | **Chỉ An** mua: đọc `stock` vào một biến, còn vé thì ghi `stock` mới và thêm An vào danh sách | `Đã bán: [An], còn 0 vé` |
| 3 | Thêm Bình y như An, nhưng **Bình đọc trước khi An ghi** (hai dòng đọc đứng liền nhau ở trên) | `Đã bán: [An, Bình], còn 0 vé` ← **bán trùng** |
| 4 | Thêm `version`: nhớ lúc đọc, kiểm lúc ghi, ghi xong tăng lên. Không khớp thì in `Bình: bị chen, đọc lại` | Dòng "bị chen" + `Đã bán: [An], còn 0 vé` |
| 5 | Bị chen thì **đọc lại** `stock`, còn vé thì mua, hết thì in `Bình: hết vé` | Đủ 3 dòng như đề |

Lượt 3 cố ý ra **sai**. Nhìn kỹ dòng đó: kho ghi "còn 0" trông rất bình thường, nhưng đã bán 2 vé. Không ai báo lỗi.
Đó là cái đáng sợ của lỗi này.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài. Đọc ví dụ, rồi tự chuyển sang dữ liệu của mình.

### Lượt 1: List rỗng và `var`

```dart
var count = 3;
final names = <String>[];
names.add('Chi');
print('Có: $names, đếm $count');
```

- `<String>[]` là List rỗng, chỉ chứa chữ. Rỗng thì Dart không tự đoán được kiểu, nên phải ghi `<String>`.
- `stock` sẽ bị gán lại nên dùng `var`. Danh sách thì chỉ `add` thêm, không gán lại, nên vẫn `final`.

### Lượt 2: đọc là chụp ảnh

```dart
var temp = 30;
final seen = temp; // ảnh chụp lúc này
temp = 35;
print('$seen $temp'); // 30 35
```

Biến đọc ra là **ảnh chụp** lúc đọc. Kho đổi sau đó thì ảnh không đổi theo. Cả bài xoay quanh chuyện này: người
mua quyết định dựa trên **ảnh chụp**, không phải dựa trên kho lúc ghi.

### Lượt 3: thứ tự thời gian

Không cần cú pháp mới. Viết code **đúng thứ tự chuyện xảy ra**: An đọc, Bình đọc, An ghi, Bình ghi. Bình ghi dựa
trên ảnh chụp của Bình (còn 1), nên tính ra "còn 0" và ghi đè lên, y như An.

### Lượt 4: số phiên bản

Giống "lịch sử chỉnh sửa" trong Google Docs: mỗi lần ai sửa, số đếm tăng 1. Lúc đọc, nhớ số đó. Lúc ghi, so lại:
số vẫn y như lúc mình đọc thì chưa ai chen, ghi được; số đã tăng thì có người ghi chen giữa chừng.

- Hai điều kiện cùng đúng: `a && b`.
- Tăng 1: `version++`.
- Nhánh còn lại: `if (...) { ... } else { ... }`.

### Lượt 5: làm lại

Trong `else`: chụp ảnh **mới** của `stock` (đặt tên khác ảnh cũ), rồi kiểm và ghi y như lần đầu. Đây chính là việc
Firestore tự làm khi transaction bị chen: chạy lại hàm của bạn với dữ liệu mới.

## Thử phá

1. Xoá phần kiểm `version` ở lần ghi của Bình. Chạy lại: bán mấy vé?
2. Trả lại như cũ, rồi đổi kho thành **2 vé**. Đúng thì cả hai cùng mua được, dù Bình vẫn bị chen một lần. Thấy được
   vì sao transaction là "làm lại", không phải "từ chối người đến sau".

## Bắc cầu sang project

- `functions/src/auth/completeSignUp.ts` dòng 19–46: tìm dòng **đọc**, dòng **kiểm**, dòng **ghi**.
- `gd03_phan_server.md` (Bước đặt vé, `createBooking`): `tx.getAll(...)` → `planBooking(...)` → `tx.set` / `tx.update`.

Tự trả lời: phần `version` và nhánh đọc lại của bài này nằm ở dòng nào trong code thật? (Gợi ý: không ở dòng nào.)

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thấy lượt 3 bán trùng mà kho vẫn "trông đúng"
- [ ] Đã thử phá cả hai cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "chống đặt trùng ghế thế nào?"
