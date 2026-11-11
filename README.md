# Học bằng bản tí hon

Mỗi thư mục `baiN/` là một khái niệm lõi. Mỗi bài có `baiN.md` (đề + các lượt + gợi ý) và `baiN.dart` mình tự viết.
Không có đáp án trong thư mục: bí thì hỏi, người dạy gợi ý tới đúng chỗ đang vướng.

## Luật của một bài

- **Một ý, nói được trong một câu.** Câu đó ghi ở đầu đề.
- **Một file, mọi thứ trong `main`, không tách hàm, không package, dưới 30 dòng.**
- **Cắt vỏ, không cắt lõi.** Bỏ kiểm lỗi, bảo mật, cấu trúc; giữ cái làm nên khái niệm.
- **Tự viết từ file trắng.** Không chép, không gõ theo.

**Bài ghép** (bài 6, 12, 17, 21) là ngoại lệ: ráp lõi của mấy bài trước thành một thứ chạy thật, nên có nhiều file,
có package, dài hơn 30 dòng. Lõi vẫn tự viết; vỏ (khung server, widget) có sẵn code trong đề, gõ nhanh.

**Thí nghiệm Flutter** (bài 31–41) là ngoại lệ thứ hai: câu hỏi về widget không ép được vô một file Dart thuần, nên
làm trong một app Flutter trống (`flutter create --empty`), chỉ sửa `lib/main.dart`. Vẫn một ý, vẫn theo lượt, vẫn có
"Chạy thấy" (dòng in ở terminal hoặc thứ đổi trên màn hình). Phần khung của các bài này có sẵn code trong đề (vỏ);
phần làm nên khái niệm thì tự viết.

Bài nào cần `class` (bài 13, 23, 27, 29, 30) thì class nằm ngoài `main` vì Dart bắt vậy; phần còn lại vẫn trong
`main`. Bài 42 có ba file nhỏ (CI cần một thứ để kiểm). Bài 43 không có Dart: gõ lệnh git trong một repo thử.

## Cách làm một bài

1. Đọc câu lõi và kết quả phải in ra.
2. Làm từng **lượt**. Mỗi lượt chỉ thêm **một thứ mới**, lưu xong chạy, phải thấy đúng cái cột "Chạy thấy".
3. Bí thì đọc gợi ý của đúng lượt đó. Gợi ý dùng **dữ liệu khác** với bài, để mình tự chuyển sang bài của mình.
4. Lượt nào thấy khó quá: lượt đó đang nhồi hai thứ mới, xin tách nhỏ ra.
5. Xong thì **thử phá**: sửa một dòng cho sai, chạy lại, thấy cái hỏng.
6. **Bắc cầu:** tìm đúng dòng trong project thật làm việc này, nhìn ra phần nào là lõi mình vừa viết, phần nào là vỏ.
7. Nói lại câu lõi bằng lời của mình. Nói trôi thì xong.

## Chạy

```powershell
cd D:\dev\hoc\bai1
dart run bai1.dart
```

## Git: mỗi bài một nhánh

`main` chỉ chứa đề và lời giải **đã xong**. Code đang làm dở nằm trên nhánh của bài.

| Lúc | Lệnh |
|---|---|
| Có đề mới (đang ở `main`) | `git add baiN/baiN.md README.md` → `git commit -m "bài N: đề"` → `git push` |
| Bắt đầu làm | `git switch -c baiN` (tạo nhánh từ `main`) |
| Xong mỗi lượt | `git add baiN/baiN.dart` → `git commit -m "bài N: lượt 3b"` → `git push -u origin baiN` (lần đầu; sau đó chỉ `git push`) |
| Xong cả bài | `git switch main` → `git merge --squash baiN` → `git commit -m "bài N: lời giải"` → `git push` |

- `--squash` gộp mọi commit của các lượt thành **một** commit trên `main`. Lịch sử từng lượt vẫn còn trên nhánh
  `baiN`, muốn xem lại cách mình đi từng bước thì `git log baiN`.
- Trước khi commit luôn chạy `git status` xem mình đang ở nhánh nào và sắp commit file gì.
- Lỡ commit nhầm lên `main` mà **chưa push**: `git reset --soft HEAD~1` (bỏ commit, giữ nguyên file).
  Đã push rồi thì hỏi trước khi sửa.

## Danh sách bài

| Bài | Lõi | Nằm ở đâu trong project |
|---|---|---|
| [bai1](bai1/bai1.md) | Rules chỉ cho đổi field được phép | `firestore.rules`: `diff().affectedKeys().hasOnly()` |
| [bai2](bai2/bai2.md) | Transaction: bị chen thì đọc lại, làm lại | `completeSignUp.ts`, `createBooking`: `runTransaction` |
| [bai3](bai3/bai3.md) | Idempotency: bấm hai lần vẫn một đơn | `createBooking`: `bookingId = uid_intentId` + `bookingSnap.exists` |
| [bai4](bai4/bai4.md) | Token là cái vé: server phát, ghi sổ, tra sổ (401/403, hết hạn) | `completeSignUp.ts`: `request.auth`; `firestore.rules`: `isAdmin()` |
| [bai5](bai5/bai5.md) | App nghe stream user, không đi hỏi | `auth_remote_datasource.dart`: `userChanges()`; `app_router.dart`: `.map().distinct()` |
| [bai6](bai6/bai6.md) | Ghép bài 4 + 5: server Dart + `users.txt` + app Flutter, có refresh token | Cả phần auth: `_SessionGate`, `decideRedirect`, `_hasLiveSession` |
| **Cụm đặt vé + hủy vé (gd3)** | | |
| [bai7](bai7/bai7.md) | Server tính tiền: app chỉ gửi "loại vé + số lượng" | gd3 Chặng 1.1: `types.ts` (schema không có `price`), `planBooking` |
| [bai8](bai8/bai8.md) | Quyết định là hàm thuần: nhận cả "bây giờ", trả ok hoặc **mã lý do**; thử bằng một dòng `check` | `planBooking`, `canCancel`, `canPay`, `decidePayment` và các file `.test.ts` |
| [bai9](bai9/bai9.md) | Transaction là bản nháp: ghi hết vào nháp, xong mới áp; hỏng giữa chừng thì vứt nháp | `createBooking.ts`: một `tx.getAll` rồi 4 lệnh `tx.set/update` |
| [bai10](bai10/bai10.md) | Trigger chạy "ít nhất một lần": người hủy trả kho và để dấu trong cùng lần ghi, trigger thấy dấu thì thôi | `release.ts` (`inventoryReleasedAt`), `stockGuard.ts`, `onBookingStatusChanged.js` |
| [bai11](bai11/bai11.md) | Hai cửa vào kho: cửa app qua rules, cửa server thì không; có cửa server rồi phải khoá cửa app | `firestore.rules` khối `bookings`; gd3 Bước 4 |
| [bai12](bai12/bai12.md) | **Ghép** 2, 3, 7–11: server Dart + file txt + app Flutter, nút Đặt vé và Hủy vé | `createBooking.ts`, `cancelBooking.ts`, `release.ts`, trang chọn vé, Vé của tôi |
| **Cụm thanh toán (gd4 Bước 1–3)** | | |
| [bai13](bai13/bai13.md) | Cổng có bản giả: code gọi ra ngoài qua một hợp đồng, lúc thử đưa bản giả vào | `gateway.ts` (`PaymentGateway`, `fakeGateway`); `login_cubit_test.dart`: `_MockAuthRepository` |
| [bai14](bai14/bai14.md) | Chữ ký webhook: băm (dữ liệu + khoá bí mật); sửa một số là chữ ký sai | `signature.ts`: `payosSignature`, `isSignedByPayos` |
| [bai15](bai15/bai15.md) | Tiền về: nhìn trạng thái đơn trước, số tiền sau; gọi lại bao nhiêu lần cũng ăn một lần | `decidePayment.ts`, `confirmPaidBooking.ts`, `payosWebhook.ts` |
| [bai16](bai16/bai16.md) | Doc là nguồn sự thật: ai nghe lúc nào cũng nhận ngay bản hiện tại (app sập rồi mở lại vẫn thấy vé) | `booking_payment_bloc.dart`: `snapshots()`; `VerifyEmailCubit` (polling) |
| [bai17](bai17/bai17.md) | **Ghép** 13–16: nút Thanh toán → QR giả → `pay.dart` đóng vai PayOS gọi webhook → trang tự sang vé | `createPayosOrder.ts`, `payosWebhook.ts`, `dev/pay.ts`, trang thanh toán |
| **Cụm giữ ghế (gd4 Bước 4, RTDB)** | | |
| [bai18](bai18/bai18.md) | Giữ ghế có hạn: khoá mang `expiresAt`, quá hạn thì coi như trống | `seat_lock_remote_datasource.dart`: `lockSeat`; `cleanupExpiredSeatLocks.js` |
| [bai19](bai19/bai19.md) | Lời dặn trước: "nếu tôi rớt mạng thì xoá khoá này giúp" (`onDisconnect`) | `seat_lock_remote_datasource.dart`: `onDisconnect().remove()`, `.cancel()` |
| [bai20](bai20/bai20.md) | Khoá trên màn hình chỉ để lịch sự; chống trùng ghế thật là sổ ghế server ghi trong transaction | `seatLedger.ts` (gd4 Bước 4), `database.rules.json` |
| [bai21](bai21/bai21.md) | **Ghép** 18–20: server Dart giữ ghế qua WebSocket + app lưới ghế có hai người cạnh nhau | `BookingCreateBloc` phần ghế, `seat_lock_remote_datasource.dart`, `createBooking` phần ghế |
| **Cụm Dart (8 câu Dart; câu Future/Stream đã có ở bài 5)** | | |
| [bai22](bai22/bai22.md) | `final` gán một lần lúc chạy; `const` biết từ lúc biên dịch và dùng chung một bản | `const LoginState.idle()`, `const Duration(...)` khắp app |
| [bai23](bai23/bai23.md) | `==` mặc định hỏi "cùng một object không"; muốn so nội dung thì tự viết `==` và `hashCode` | `BookingPaymentState extends Equatable`; `auth_bloc.dart`: "Same state twice emits nothing" |
| [bai24](bai24/bai24.md) | Event loop: chạy hết việc đang làm, rồi microtask, rồi event; `await` là nhường chỗ | Mọi hàm `async` trong app; `VerifyEmailCubit`: `Timer.periodic` |
| [bai25](bai25/bai25.md) | Lỗi trong code async chỉ bắt được khi có `await` (hoặc `onError` với stream) | `core/result/guard.dart`; `auth_bloc.dart`: `onError: addError` |
| [bai26](bai26/bai26.md) | Null safety: `?` là "có thể không có", compiler bắt kiểm; `!` và `late` là lời hứa | `_currentUserId`; `late _MockAuthRepository repository`; tham số `required` |
| [bai27](bai27/bai27.md) | Gắn thêm hàm vào một kiểu mà không kế thừa: `mixin` cho lớp mình, `extension` cho lớp người khác | `core/utils/extensions.dart`; `SingleTickerProviderStateMixin` |
| [bai28](bai28/bai28.md) | Isolate: việc nặng chạy ở một luồng riêng, bộ nhớ riêng, trả kết quả bằng tin nhắn | EH chưa dùng; chỗ sẽ cần: xử lý sơ đồ ghế lớn |
| **Cụm BLoC (4 câu BLoC)** | | |
| [bai29](bai29/bai29.md) | Cubit tự viết: giữ state, phát state mới ra stream; Bloc là Cubit nhận **event** thay vì gọi hàm | `LoginCubit`, `AuthBloc` (`_AuthUserChanged`) |
| [bai30](bai30/bai30.md) | Thử một cubit: đưa repo giả, gọi hàm, so **danh sách state** đã phát | `login_cubit_test.dart`: `blocTest(build, act, expect)` |
| [bai31](bai31/bai31.md) | Thí nghiệm: `BlocBuilder` để vẽ, `BlocListener` để làm một lần, `BlocConsumer` là cả hai | `booking_payment_page_web.dart`, `booking_detail_page_web.dart` |
| **Cụm Flutter (thí nghiệm trong app trống)** | | |
| [bai32](bai32/bai32.md) | Vòng đời của `State`, và `setState` chỉ đánh dấu "cần vẽ lại" | `LoginPage` (`dispose` controller), `if (mounted)` |
| [bai33](bai33/bai33.md) | Widget là bản vẽ bị vứt mỗi lần build; Element giữ chỗ và giữ State; `BuildContext` chính là Element | `context.read`, `Theme.of(context)`, lỗi thiếu `BlocProvider` |
| [bai34](bai34/bai34.md) | Key: cách Flutter nhận ra "vẫn là widget cũ" khi danh sách đổi thứ tự | `key: ValueKey(id)` ở trang đọc theo id (ADR 11) |
| [bai35](bai35/bai35.md) | Constraints đi xuống, size đi lên, cha đặt vị trí | Lỗi tràn, `Expanded`, `web_page_frames_test.dart` |
| [bai36](bai36/bai36.md) | Vẽ lại thừa: tìm bằng cách đếm `build`, sửa bằng `const`, tách widget, `buildWhen` | `listenWhen` / `buildWhen` trong trang booking |
| [bai37](bai37/bai37.md) | Jank: một khung hình quá 16 ms vì việc nặng chạy trên luồng UI | DevTools Performance; bài 28 |
| [bai38](bai38/bai38.md) | GoRouter: URL là nguồn sự thật, `redirect` quyết ai được vào; mở thẳng link sâu vẫn đúng | `app_router.dart`, `route_policy.dart`: `decideRedirect`, `?redirect=` |
| [bai39](bai39/bai39.md) | Hot reload giữ State và không chạy lại `main`; hot restart thì làm lại từ đầu | Bẫy "DI, route, `main.dart` không nạp nóng được" |
| [bai40](bai40/bai40.md) | Platform channel: gửi "tên hàm + tham số" qua một kênh có tên sang phía native, chờ trả lời | Mọi plugin Firebase; lỗi `MissingPluginException` |
| **Cụm Test và Git** | | |
| [bai41](bai41/bai41.md) | Widget test: dựng widget trong bộ nhớ, bấm, `pump`, rồi tìm chữ | `app/test/**`; ba tầng test của EH |
| [bai42](bai42/bai42.md) | CI tí hon: một máy khác chạy lại đúng các lệnh kiểm; lệnh nào thoát mã khác 0 là đỏ | `.github/workflows/ci.yml` (4 job) |
| [bai43](bai43/bai43.md) | Merge giữ nguyên hai nhánh và thêm một commit nối; rebase chép commit của mình lên đầu nhánh kia | Cách làm nhánh `baiN`, `feature/v2-core` |

## Thứ tự nên làm

| Trước khi | Làm bài | Vì |
|---|---|---|
| Gõ tiếp gd1 Bước 4–5 (rules `users`) | 6 (đang dở), 11 | Bước 4 là "khoá cửa app" của doc user |
| Gõ gd3 Bước 1 (`planBooking`) | 7, 8 | Hai ý của chính file đó |
| Gõ gd3 Bước 2 (`createBooking`) | 9 (đã có 2, 3) | Đọc một lần, ghi bốn chỗ |
| Gõ gd3 Bước 3 (`cancelBooking`, trigger cũ) | 10 | Dấu `inventoryReleasedAt` |
| Gõ gd3 Bước 4 (khoá rules) | 12 | Bài ghép đi trọn nút Đặt và nút Hủy; làm xong mới mở guide gd3 thì nhận ra từng bước |
| Gõ gd4 Bước 1 (`createPayosOrder`) | 13 | Cổng giả |
| Gõ gd4 Bước 2 (webhook, `dev:pay`) | 14, 16 | Chữ ký; trang tự sang vé |
| Gõ gd4 Bước 3 (`decidePayment`) | 15, rồi 17 | Bài ghép 17 đi trọn nút Thanh toán |
| gd4 Bước 4 (ghế, guide chưa có) | 18, 19, 20, 21 | Code khoá ghế phía app đã có sẵn để đối chiếu |

Các cụm còn lại không phụ thuộc gd nào, làm xen theo lịch ôn của Chặng 1: cụm Dart (22–28) tuần 4; cụm BLoC và
Flutter (29–40) tuần 5–6; cụm Test và Git (41–43) tuần 7–8.
