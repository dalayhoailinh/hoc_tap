# Bài 13: cổng có bản giả

**Lõi một câu:** chỗ nào code của mình gọi ra **dịch vụ bên ngoài** (PayOS) thì gọi qua một **hợp đồng** ("ai làm
cổng thanh toán thì phải có hàm này"). Chạy thật thì đưa bản thật vào, lúc thử và ở máy mình thì đưa **bản giả** cùng
hình dạng. Phần code còn lại không biết, cũng không cần biết, nó đang cầm bản nào.

## Đề

`bai13.dart`: ba lớp nhỏ nằm ngoài `main` (Dart không cho khai lớp trong hàm), còn lại trong `main`, không package,
khoảng 40 dòng.

- Đơn của An: `orderCode: 7`, `totalAmount: 300000`.
- "PayOS thật" trong bài chỉ là đóng vai: nó tăng một biến đếm `realCalls` (coi như một lần gọi mạng, tốn tiền thật)
  rồi trả link `https://pay.payos.vn/<mã đơn>`.

Phải in ra đúng:

```
FAKE-PAYOS|7|300000
OK   số tiền gửi cổng là tiền của đơn
PayOS thật bị gọi: 0 lần
máy mình: FakeGateway, cloud: PayosGateway
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | Biến `realCalls` (ngoài `main`). Hàm `payosCreateLink(orderCode, amount)` đóng vai PayOS thật. Hàm `checkout(booking)` gọi nó bằng mã đơn và tiền **của đơn**. Gọi một lần, in link và số lần gọi | `https://pay.payos.vn/7` và `PayOS thật bị gọi: 1 lần` |
| 2 | Muốn thử `checkout` kỹ hơn: gọi thêm hai đơn nữa (mã 8 tiền 50000, mã 9 tiền 1200000) | `PayOS thật bị gọi: 3 lần` ← **mỗi lần chạy thử là 3 link thanh toán thật**; mà nhìn 3 cái link cũng không biết `checkout` đã gửi đi bao nhiêu tiền |
| 3 | Hợp đồng `abstract class PaymentGateway` có một hàm `createLink`. Lớp `PayosGateway implements` nó, ruột là hàm `payosCreateLink` cũ. `checkout` nhận thêm tham số `gateway` | Y như lượt 2 (đổi hình, chưa đổi hành vi) |
| 4 | Lớp `FakeGateway implements PaymentGateway`: không đụng `realCalls`, trả chuỗi `FAKE-PAYOS\|<mã đơn>\|<số tiền>`. Đưa bản giả vào 3 lời gọi | `FAKE-PAYOS\|7\|300000`, `FAKE-PAYOS\|8\|50000`, `FAKE-PAYOS\|9\|1200000`, `PayOS thật bị gọi: 0 lần` |
| 5 | Dùng bản giả để **kiểm tiền**: chỉ giữ đơn của An; tách chuỗi trả về, lấy phần cuối, so với `300000`, in `OK  ` hoặc `SAI ` | 3 dòng đầu của đề |
| 6 | Hàm `paymentGateway(isEmulator)` (ngoài `main`): ở máy mình trả bản giả, trên cloud trả bản thật. In tên lớp của hai trường hợp | Đủ 4 dòng như đề |

Lượt 2 là cái hỏng: không có gì "sai", nhưng bạn không thể chạy thử code của mình mà không làm phiền một công ty
khác, không tốn tiền, không cần mạng. Và thứ đáng kiểm nhất (số tiền gửi đi) lại không nhìn thấy được.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1: biến ngoài `main`

Biến khai ngoài `main` thì mọi hàm, mọi lớp trong file đều thấy. Lượt 3 cần vậy, vì lớp nằm ngoài `main`.

### Lượt 3: hợp đồng và người làm theo

```dart
abstract class Loa {
  void keu(String cau);
}

class LoaPhuong implements Loa {
  @override
  void keu(String cau) => print('!!! $cau !!!');
}

void thongBao(Loa loa) {
  loa.keu('họp tổ dân phố');
}

void main() {
  thongBao(LoaPhuong()); // !!! họp tổ dân phố !!!
}
```

- `abstract class` chỉ ghi **tên hàm, tham số, kiểu trả về**, không có ruột. Không tạo object từ nó được.
- `implements Loa` là lời cam kết "tôi có đủ mọi hàm của `Loa`". Thiếu một hàm là Dart báo lỗi ngay lúc biên dịch.
- `@override` đánh dấu "hàm này làm theo hợp đồng".
- `thongBao` nhận kiểu `Loa`: đưa lớp nào `implements Loa` vào cũng được.

### Lượt 5: tách chuỗi

```dart
final bien = '43A|123.45|đỏ';
print(bien.split('|').last); // đỏ
```

Phần cuối tách ra là **chữ**, nên so với `'300000'` (có nháy).

### Lượt 6: tên lớp của một object

```dart
print(LoaPhuong().runtimeType); // LoaPhuong
```

Kiểu trả về của `paymentGateway` là **hợp đồng** (`PaymentGateway`), không phải một trong hai lớp cụ thể.

## Thử phá

1. Trong `checkout`, gửi cứng `1000` thay cho tiền của đơn. Chạy: dòng 2 thành `SAI`. Đây là lỗ L3 của EH (trả 1.000đ
   cho vé 300.000đ), và **bản giả bắt được nó** mà không tốn một lời gọi PayOS nào. Trả lại.
2. Trong `paymentGateway`, đảo hai nhánh. Dòng cuối ra gì? Ở máy mình mà cầm bản thật là mỗi lần chạy thử gọi PayOS
   thật. Vì vậy dấu hiệu "đang ở máy mình" phải là thứ **chỉ máy mình có**, không phải thứ người ta tự gõ. Trả lại.
3. Cho `FakeGateway` trả về chuỗi `'FAKE'` trơn. Dòng 2 `SAI` dù `checkout` đúng. Bản giả lệch hình dạng thì test
   nói dối. Bản giả phải **giống bản thật ở mọi thứ mà code của mình nhìn vào**.

## Bắc cầu sang project

**Bạn sẽ gõ ở gd4 Chặng 1.1**, `functions/src/payment/gateway.ts`:

| Bài 13 | Code thật |
|---|---|
| `abstract class PaymentGateway` | `export interface PaymentGateway { createLink(...); cancelLink(...); }` |
| `PayosGateway` | `payosGateway(env)`: bọc SDK `@payos/node`, đây mới là chỗ gọi mạng |
| `FakeGateway`, chuỗi `FAKE-PAYOS\|mã\|tiền` | `fakeGateway`: `` qrCode: `FAKE-PAYOS|${order.orderCode}|${order.amount}` `` |
| `paymentGateway(isEmulator)` | `paymentGateway()`: `process.env.FUNCTIONS_EMULATOR === "true" ? fakeGateway : payosGateway(process.env)` |
| Lượt 5 | gd4 Chặng 1.4, test "tiền lấy từ đơn": gửi kèm `amount: 1000`, rồi đọc số tiền ở cuối chuỗi QR |
| Thử phá 2 | `FUNCTIONS_EMULATOR` là biến **chỉ emulator đặt**: trên cloud không thể lỡ dùng bản giả, ở máy không thể lỡ gọi PayOS thật |

- **Lõi:** hợp đồng + hai bản + một chỗ chọn.
- **Vỏ:** `createLink` thật là `async` (gọi mạng thì phải đợi), trả cả `paymentLinkId` lẫn `qrCode`; có thêm
  `cancelLink`; bắt lỗi PayOS đổi thành `HttpsError("unavailable", ...)`.
- **Hiện tại EH đang ở lượt 2:** `functions/bookings/onBookingStatusChanged.js` dòng 209–210 gọi thẳng
  `getPayOS().cancelPaymentLink(...)`. Chạy trên emulator là nó gọi **PayOS thật** bằng khoá giả. gd4 Chặng 2.2 cho
  nó đi qua cổng.
- **Luật của EH:** "thanh toán và AI phải đi qua cổng có bản giả" (`CLAUDE.md`, mục Tiền và bí mật). Đây là cái
  phanh chi phí.

**Phía Flutter đã có sẵn đúng hình này**, mở ra xem:

- Hợp đồng: `app/lib/features/auth/domain/repositories/auth_repository.dart` dòng 4, `abstract class AuthRepository`.
- Bản thật: `app/lib/features/auth/data/repositories/auth_repository_impl.dart` dòng 10–11,
  `@LazySingleton(as: AuthRepository)` rồi `class AuthRepositoryImpl implements AuthRepository`. Dòng `@LazySingleton`
  là chỗ chọn: "ai xin `AuthRepository` thì đưa bản này" (gói `injectable` làm hộ hàm `paymentGateway` của bạn).
- Người dùng cổng: `app/lib/features/auth/presentation/view_models/login/login_cubit.dart` dòng 11–13,
  `LoginCubit(this._repository)`. Cubit chỉ biết hợp đồng.
- Bản giả: `app/test/features/auth/presentation/login_cubit_test.dart` dòng 11,
  `class _MockAuthRepository extends Mock implements AuthRepository {}`. Gói `mocktail` viết hộ ruột của bản giả; bài
  30 sẽ tự viết một bản.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 2 (3 lần gọi thật)
- [ ] Đã thử phá cả 3 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How do you mock Firebase or a payment provider in tests?"
