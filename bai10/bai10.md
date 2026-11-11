# Bài 10: trigger có thể chạy hai lần

**Lõi một câu:** trigger là hàm **tự chạy sau khi một doc đổi**, nhận bản **trước** và bản **sau**; cùng một lần đổi
nó có thể được gọi **hơn một lần**. Nên người hủy vé tự trả kho ngay trong lần ghi của mình và để lại một **dấu**;
trigger thấy dấu vừa đổi thì không trả nữa.

## Đề

`bai10.dart`: mọi thứ trong `main`, ba hàm nhỏ trong `main`, không package, khoảng 30 dòng.

- Sự kiện đã bán 5 vé (2 của An, 3 của Bình). Chỉ cần một biến `sold = 5`.
- Đơn của An: `status: 'confirmed'`, `quantity: 2`.
- An hủy đơn. Database gọi trigger **hai lần** cho lần đổi đó.

Phải in ra đúng:

```
đơn: confirmed -> cancelled
trigger: người hủy đã trả kho, bỏ qua
trigger: người hủy đã trả kho, bỏ qua
đã bán: 3
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | `sold`, đơn của An (Map), in | `đã bán: 5, đơn: {status: confirmed, quantity: 2}` |
| 2 | Hàm `update(patch)` đóng vai database: giữ lại bản **trước**, ghép patch thành bản **sau**, in `đơn: trước -> sau`. An hủy: `update({'status': 'cancelled'})` | `đơn: confirmed -> cancelled`, `đã bán: 5` (chưa ai trả kho) |
| 3 | Hàm `onStatusChanged(before, after)`: status không đổi thì thôi; đổi sang `cancelled` thì trừ `sold`, in `trigger: trả 2 vé`. **`update` gọi nó** sau khi ghi | `trigger: trả 2 vé`, `đã bán: 3` |
| 4 | Trong `update`, gọi trigger **hai lần** liền nhau, cùng `before`, cùng `after` | `đã bán: 1` ← **đơn 2 vé mà kho được trả 4** |
| 5 | Hàm `cancel()`: tự trừ `sold`, rồi `update` với patch có thêm dấu `releasedAt: 1`. An hủy bằng `cancel()` | `đã bán: -1` ← **tệ hơn: giờ có hai nơi cùng trả** |
| 6 | Trong trigger: `releasedAt` ở bản trước **khác** bản sau thì in `trigger: người hủy đã trả kho, bỏ qua`, không trả | Đủ 4 dòng như đề |

Lượt 4 là cái hỏng gốc: database (Firebase) chỉ hứa gọi trigger **ít nhất một lần**. Mạng chập chờn, function khởi
động chậm, nó gọi lại. Bạn không tắt được chuyện này; chỉ viết được trigger sao cho chạy hai lần vẫn như một lần.

Lượt 5 cố ý ra **sai hơn** để thấy: dời việc sang chỗ mới mà chưa bảo chỗ cũ thôi làm thì việc bị làm hai nơi.

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài.

### Lượt 1, 2: biến giữ Map, gán Map mới

```dart
var ho = <String, Object>{'ten': 'Chi', 'tuoi': 20};
final truoc = ho;
ho = {...ho, 'tuoi': 21};
print('${truoc['tuoi']} -> ${ho['tuoi']}'); // 20 -> 21
```

- `{...ho, 'tuoi': 21}` tạo một Map **mới** (bài 1 lượt 4). `truoc` vẫn trỏ Map cũ, nên giữ được "ảnh chụp" như bài 2.
- Biến sẽ được gán Map khác nên dùng `var`. Ghi `<String, Object>` để lượt 5 thêm được field số.

### Lượt 3: hàm này gọi hàm kia

Hàm trong `main` phải được **khai trước** dòng dùng nó: viết `onStatusChanged` phía trên `update`.

Điều đáng nhìn: **không ai trong chương trình "gọi trigger"** ngoài `update`. An chỉ ghi doc. Trigger chạy là do
database.

### Lượt 6: so dấu trước và sau

```dart
final truoc = <String, Object>{'ten': 'Chi'};
final sau = <String, Object>{'ten': 'Chi', 'dau': 1};
print(truoc['dau'] != sau['dau']); // true: null khác 1
```

Field chưa có thì tra ra `null`. "Dấu vừa đổi trong lần ghi này" = dấu của bản trước khác dấu của bản sau. Kiểm chuyện
này **trước** nhánh trả kho, nối bằng `if (...) {...} else if (...) {...}`.

## Thử phá

1. Đổi điều kiện kiểm dấu thành `if (false)`. Chạy: `đã bán` ra mấy? (Guide gd3 Chặng 3.3 bảo bạn làm đúng trò này
   với code thật.)
2. Trả lại như cũ. Dòng cuối, thay `cancel();` bằng `update({'status': 'cancelled'});` (hủy theo **đường cũ**, không
   để dấu). Ra mấy? Dấu chỉ cứu đường đi qua `cancel`. Đường nào chưa chuyển thì vẫn còn nguyên cái lỗi chạy hai lần.

## Bắc cầu sang project

| Bài 10 | Code thật |
|---|---|
| `update` gọi trigger | **Không có dòng nào.** Firestore tự gọi function sau mỗi lần doc đổi |
| `onStatusChanged(before, after)` | `functions/bookings/onBookingStatusChanged.js` dòng 26–35: `onDocumentUpdated`, `event.data.before.data()`, `event.data.after.data()` |
| Status không đổi thì thôi | Dòng 39: `if (prevStatus === nextStatus) return;` |
| Trigger trả kho | Dòng 63–66: `adjustTicketInventory(after, eventId, -1)` |
| Trigger chạy hai lần (lượt 4) | **Không có dòng nào**, đó là cách Firebase giao việc ("at least once") |
| `cancel()` tự trả kho + để dấu | gd3 Chặng 3.2, `release.ts`: một `tx.update(bookingRef, { status, cancelledAt, inventoryReleasedAt: now })` cùng transaction với lệnh trả kho |
| Lượt 6 | gd3 Chặng 3.2, `stockGuard.ts`: `stockReturnedByWriter(before.inventoryReleasedAt, after.inventoryReleasedAt)`, và 2 chỗ sửa trong trigger cũ |

- **Lõi:** so dấu của `before` với `after`. Vì dấu được ghi **cùng một lần ghi** với việc đổi status, trigger được
  gọi lại bao nhiêu lần cũng nhận đúng cặp `before`/`after` đó, nên lần nào cũng bỏ qua.
- **Vỏ:** dấu là một `Timestamp` nên phải so bằng mili-giây (`toMillis()`); trigger còn làm hai việc khác không liên
  quan kho (đánh dấu ghế trên RTDB, hủy link PayOS), hai việc đó vẫn chạy.
- **Thử phá 2 có thật:** đơn hết hạn (`functions/bookings/expireBookings.js`) vẫn đổi status theo đường cũ, không để
  dấu. Guide gd3 ghi rõ đường này "vẫn đi qua trigger như cũ tới gd4".
- **Trigger bạn đã gõ ở gd1** cũng phải chịu chạy hai lần: `functions/src/auth/onUserCreated.ts` dòng 30–38. Nó dùng
  `.create()` (chỉ tạo khi doc chưa có) và nuốt lỗi "đã có": chạy lần hai không ghi đè gì. Cùng một bệnh, thuốc khác:
  ở đó "tạo nếu chưa có", ở đây "để dấu".
- **Callable khác trigger chỗ nào:** callable (`createBooking`, `cancelBooking`) do **app gọi**, trả kết quả về cho
  app. Trigger do **database gọi**, không ai chờ kết quả, và có thể bị gọi lại.

## Xong khi

- [ ] In đúng 4 dòng như đề
- [ ] Đã thấy lượt 4 (trả 4 vé) và lượt 5 (âm 1)
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Your Cloud Function trigger runs twice for the same
  change: what breaks, and how do you make it safe?"
