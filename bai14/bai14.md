# Bài 14: chữ ký của webhook

**Lõi một câu:** webhook là một địa chỉ công khai, ai biết cũng gửi được "đơn 7 đã trả 300.000đ". Người gửi thật
chứng minh mình bằng **chữ ký** = băm của (dữ liệu + một **khoá bí mật** chỉ hai bên biết). Mình tự tính lại từ dữ
liệu nhận được; khớp mới tin. Sửa một con số trong dữ liệu là chữ ký hết khớp.

## Đề

`bai14.dart`: mọi thứ trong `main`, bốn hàm nhỏ trong `main`, không package, khoảng 30 dòng.

- Khoá bí mật PayOS và server cùng giữ: `bi-mat-123`.
- Tin "tiền về": `orderCode: 7`, `amount: 300000`.
- Hàm băm là **đồ chơi tự viết** (mục "Đồ thật khác chỗ nào" ở cuối).

Bốn tin gửi tới webhook:
1. PayOS thật: ký bằng khoá thật.
2. Kẻ lạ: cùng dữ liệu, ký bằng khoá đoán `doan-mo`.
3. Người mua trả 1.000đ, PayOS ký tin "1000". Người đó sửa số tiền thành 300000, **giữ nguyên chữ ký cũ**.
4. PayOS thật, nhưng viết field theo thứ tự `amount` rồi mới `orderCode`.

Phải in ra đúng:

```
PayOS thật: tin
kẻ lạ ký bằng khoá đoán: không tin
sửa số tiền, giữ chữ ký cũ: không tin
PayOS xếp field kiểu khác: tin
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Tin `paid` (Map). Hàm `accept(data)` trả luôn `true`. Hàm `say(ok)` đổi `true`/`false` thành `tin`/`không tin`. Gửi hai lần: PayOS thật và kẻ lạ | `PayOS thật: tin` và `kẻ lạ: tin` ← **ai gửi cũng được xác nhận** |
| 2 | Hàm `toyHash(text)`: biến một chuỗi thành một số. In băm của `'amount=300000'` và `'amount=300001'` | `752753159` và `752753160` (hai dòng `tin` vẫn như cũ) |
| 3 | Khoá `key`. Hàm `sign(data, key)`: nối các field thành `orderCode=7&amount=300000`, thêm `\|` và khoá, rồi băm. `accept(data, signature)` tự `sign` lại bằng khoá của mình và so. Kẻ lạ ký bằng `doan-mo` | `PayOS thật: tin` và `kẻ lạ ký bằng khoá đoán: không tin` |
| 4 | Tin thứ ba: dữ liệu là `paid`, chữ ký là chữ ký thật của tin `cheap` (1000 đồng) | Thêm `sửa số tiền, giữ chữ ký cũ: không tin` |
| 5 | Tin thứ tư: PayOS ký trên Map `swapped` (cùng dữ liệu, `amount` viết trước) | `PayOS xếp field kiểu khác: không tin` ← **tin thật bị từ chối oan** |
| 6 | Trong `sign`: xếp tên field theo thứ tự chữ cái rồi mới nối | Đủ 4 dòng như đề |

Lượt 1 là lỗ gốc. Lượt 5 là cái hỏng tinh vi hơn: hai bên cùng khoá, cùng dữ liệu, cùng hàm băm, vẫn không khớp, vì
hai bên **dựng chuỗi khác nhau** trước khi băm.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 2: băm đồ chơi

```dart
int tong(String text) {
  var s = 0;
  for (final unit in text.codeUnits) {
    s = s + unit;
  }
  return s;
}
print('ab'.codeUnits); // [97, 98]
print(tong('ab')); // 195
print(tong('ba')); // 195  <- tệ: đổi chỗ hai chữ mà băm không đổi
```

- `codeUnits` là mã số của từng ký tự.
- Bản `tong` trên quá tệ. Bài mình dùng công thức khá hơn một chút: bắt đầu từ `7`, với mỗi ký tự:
  `hash = (hash * 31 + unit) % 1000000007`. Nhân 31 làm **vị trí** của ký tự có ảnh hưởng; `%` giữ số không phình mãi.
- Băm có ba tính chất cần nhớ: cùng chuỗi luôn ra cùng số; khác chuỗi thì (gần như) ra số khác; từ số **không lần
  ngược** ra chuỗi được.

### Lượt 3: nối các cặp của Map thành một chuỗi

```dart
final hs = {'ten': 'Chi', 'lop': '9A'};
print(hs.keys.map((k) => '$k=${hs[k]}').join('&')); // ten=Chi&lop=9A
```

`join('&')` nối các phần tử của một danh sách, chèn `&` vào giữa.

Hai bên không gửi khoá cho nhau qua mạng lần nào. Khoá được trao **một lần, từ trước**, bằng đường khác (PayOS hiện
nó trong trang quản trị, mình chép vào cấu hình server).

### Lượt 6: xếp thứ tự

```dart
final ten = ['Chi', 'An', 'Bình'];
ten.sort();
print(ten); // [An, Bình, Chi]
```

`data.keys` chưa phải List: thêm `.toList()` rồi mới `sort()`.

## Thử phá

1. Trong `sign`, băm chỉ dữ liệu, bỏ phần khoá. Chạy: kẻ lạ ra gì? Không có khoá thì đó chỉ là "mã kiểm lỗi", ai cũng
   tự tính được. Trả lại.
2. Đổi khoá của server thành chuỗi rỗng `''`, và cho kẻ lạ cũng ký bằng `''`. Kẻ lạ ra gì? Server quên cấu hình khoá
   là mở toang. Đồ thật có một dòng riêng: khoá rỗng thì **luôn** từ chối. Trả lại.

## Đồ thật khác chỗ nào

- `toyHash` của bạn yếu thấy rõ ở lượt 2: đổi một ký tự, băm chỉ lệch đúng 1. Kẻ xấu nhìn vài cặp là đoán được quy
  luật. Đồ thật dùng **HMAC-SHA256**: đổi một ký tự là khoảng nửa số bit đổi, kết quả dài 64 ký tự hệ 16, và chưa ai
  lần ngược được.
- Đồ thật so chữ ký bằng hàm so "thời gian đều" (`timingSafeEqual`), không dùng `==`: `==` dừng ở ký tự sai đầu
  tiên, kẻ gửi thử đo thời gian trả lời là đoán dần được chữ ký.

## Bắc cầu sang project

**Bạn sẽ gõ ở gd4 Chặng 2.1**, `functions/src/payment/signature.ts`:

| Bài 14 | Code thật |
|---|---|
| `sign(data, key)` | `payosSignature(data, checksumKey)` |
| Lượt 6: xếp tên field | `Object.keys(data).sort()` |
| `tên=giá trị` nối bằng `&` | `` .map((key) => `${key}=${...}`).join("&") `` |
| `toyHash(chuỗi + khoá)` | `createHmac("sha256", checksumKey).update(query).digest("hex")` |
| `accept(data, signature)` | `isSignedByPayos(body, checksumKey)` |
| Thử phá 2 | `if (!checksumKey || typeof signature !== "string") return false;` |

- **Lõi:** dựng chuỗi theo đúng một quy ước → băm cùng khoá → so.
- **Vỏ:** giá trị `null` viết thành chuỗi rỗng, bỏ field `undefined` (đúng cách PayOS dựng chuỗi); `timingSafeEqual`;
  thư viện `node:crypto`.
- **Sao biết mình dựng chuỗi giống PayOS?** Chặng 2.1 có một test chéo: body do hàm của mình ký, đưa cho
  `verifyPaymentWebhookData` của SDK PayOS kiểm. SDK chịu thì cách ký của mình giống hệt họ.
- **Bản đang chạy trong EH** để thư viện làm hết: `functions/payos/payosWebhook.js` dòng 24,
  `payos.verifyPaymentWebhookData(req.body)`; sai thì dòng 27 trả `400`. Đúng, nhưng bạn không thấy bên trong; và
  trên máy mình không tự ký được một tin "tiền về" để thử. Tự viết `payosSignature` thì `dev:pay` (Chặng 2.4) ký
  được bằng khoá giả.
- **Khoá nằm ở đâu:** `process.env.PAYOS_CHECKSUM_KEY` (`functions/payos/_shared.js` dòng 25), giá trị trong
  `functions/.env`, file **không bao giờ commit**. Khoá lộ thì ai cũng ký được tin "tiền về" hợp lệ; việc đầu tiên
  phải làm là thu hồi khoá.
- Cùng một ý với token ở bài 4: ID token của Firebase (JWT) mang chữ ký của Google; server kiểm chữ ký thay vì tra
  sổ.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 1 (ai gửi cũng tin) và lượt 5 (tin thật bị từ chối oan)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How does your server know a webhook really comes from the
  payment provider?"
