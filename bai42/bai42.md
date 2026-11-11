# Bài 42: CI tí hon

**Lõi một câu:** CI là **một cái máy khác** tự chạy lại đúng những lệnh kiểm mà bạn vẫn chạy tay (format, analyze,
test), theo thứ tự, mỗi lần có code mới. Máy không đọc chữ "SAI": nó chỉ nhìn **mã thoát** của từng lệnh. `0` là
xanh, khác `0` là đỏ, và đỏ ở đâu thì **dừng ở đó**.

## Đề

Bài này cần một thứ để kiểm, nên có **ba file nhỏ** trong `D:\dev\hoc\bai42\`: `gia.dart` (code "sản phẩm", 3 dòng),
`gia_test.dart` (test, kiểu bài 8), `ci.dart` (cái CI, khoảng 20 dòng, mọi thứ trong `main`). Không package.

Phải in ra đúng khi chạy `dart run ci.dart`:

```
XANH format (mã thoát 0)
XANH analyze (mã thoát 0)
XANH test (mã thoát 0)
CI xanh
```

Xem mã thoát của lệnh vừa chạy (PowerShell): `echo $LASTEXITCODE`

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | `gia.dart`: hàm `total(price, quantity)` trả giá × số lượng. `gia_test.dart`: hàm `check` (bài 8 lượt 7), hai ca (2 vé 500000 → 1000000; 3 vé giá 0 → 0), in `n/m ca đúng` | `dart run gia_test.dart` → `2/2 ca đúng`; `echo $LASTEXITCODE` → `0` |
| 2a | Phá: trong `gia.dart` đổi `*` thành `+`. Chạy lại test, xem mã thoát | `SAI  2 vé VIP: ra 500002`, `0/2 ca đúng`, nhưng `echo $LASTEXITCODE` → **`0`** ← người đọc thấy đỏ, **máy thấy xanh** |
| 2b | Cuối `gia_test.dart`: có ca sai thì thoát với mã `1` | Vẫn in như trên; `echo $LASTEXITCODE` → `1` |
| 3 | `ci.dart`: chạy lệnh `dart run gia_test.dart` bằng `Process.runSync`, in `XANH test` hoặc `ĐỎ   test` kèm mã thoát. (Code đang phá) | `ĐỎ   test (mã thoát 1)`. Sửa `gia.dart` lại, chạy lại: `XANH test (mã thoát 0)` |
| 4 | Ba bước trong một Map (tên → tham số của lệnh `dart`): `format`, `analyze`, `test`. Vòng lặp chạy từng bước; bước nào đỏ thì in output của bước đó, rồi **thoát với mã 1**. Hết vòng in `CI xanh` | Đủ 4 dòng như đề |

Lượt 2a là lõi của cả bài. Một bộ test in "SAI" mà vẫn thoát mã `0` thì với CI nó **luôn xanh**. (Lượt 3 cũng dính
đúng bệnh đó: `ci.dart` in `ĐỎ` nhưng chính nó thoát `0`. Lượt 4 chữa bằng `exit(1)`.)

## Gợi ý từng lượt

Ví dụ dùng lệnh khác bài.

### Lượt 2b: thoát với mã

```dart
import 'dart:io';

void main() {
  final ok = 1 + 1 == 3;
  exit(ok ? 0 : 1);
}
```

`exit(n)` dừng chương trình ngay và trả `n` cho ai đã gọi nó.

### Lượt 3: chạy một lệnh từ Dart

```dart
import 'dart:io';

final result = Process.runSync('dart', ['--version'], runInShell: true);
print(result.exitCode); // 0
print(result.stdout); // Dart SDK version: ...
```

- Tham số thứ hai là danh sách các chữ đứng sau tên lệnh: `dart run gia_test.dart` là `['run', 'gia_test.dart']`.
- `runInShell: true` để Windows tìm ra lệnh `dart`.
- `result.exitCode` là mã thoát; `result.stdout` là những gì lệnh đó in ra.

### Lượt 4: ba bước

| Bước | Lệnh gõ tay | Kiểm cái gì |
|---|---|---|
| `format` | `dart format --output=none --set-exit-if-changed .` | Code đã xếp đúng kiểu chưa. `--output=none`: chỉ kiểm, không sửa file. `--set-exit-if-changed`: có file lệch thì mã thoát `1` |
| `analyze` | `dart analyze` | Lỗi và cảnh báo tĩnh (biến thừa, sai kiểu) |
| `test` | `dart run gia_test.dart` | Hành vi |

Thứ tự rẻ trước đắt sau: format mất chưa tới một giây, test lâu nhất. Đỏ sớm thì biết sớm.

In output của bước đỏ: `stdout.write(result.stdout);`

## Thử phá

Mỗi lần phá một kiểu, chạy `dart run ci.dart`, xem **dừng ở bước nào**, rồi trả lại:

1. Trong `gia.dart`, thụt dòng `return` vào 6 dấu cách. → `ĐỎ   format (mã thoát 1)`, kèm `Changed gia.dart`. Hai bước
   sau **không chạy**.
2. Thêm một dòng `final unused = 1;` vào hàm `total`. → `XANH format`, `ĐỎ   analyze (mã thoát 2)`.
3. Đổi `*` thành `+`. → hai bước đầu xanh, `ĐỎ   test (mã thoát 1)`.

## Bắc cầu sang project

Mở `.github/workflows/ci.yml` của EH. Nó là `ci.dart` của bạn, viết bằng YAML, chạy trên máy của GitHub:

| Bài 42 | `ci.yml` |
|---|---|
| "Mỗi lần có code mới" | Dòng 3–7: `on: pull_request` và `push` lên `main`, `develop`, `feature/**` |
| "Một cái máy khác" | Dòng 12: `runs-on: ubuntu-latest`. Máy **Linux, trắng tinh**, chỉ có đúng thứ đã commit |
| Map ba bước | Dòng 33–40 (job `app`): `dart format --set-exit-if-changed .` → `flutter analyze` → `flutter test`. Đúng ba bước, đúng thứ tự |
| Bước đỏ thì dừng | GitHub Actions làm sẵn: một `run:` thoát mã khác 0 là job đỏ, các bước sau bị bỏ |
| `exit(1)` | Job đỏ → dấu ✗ đỏ cạnh commit, PR bị chặn merge |

Bốn job, chạy song song:

| Job | Dòng | Chạy gì | Là tầng test nào (bài 41) |
|---|---|---|---|
| `app` | 10–40 | format, analyze, `flutter test` | unit + widget của Flutter |
| `functions` | 42–71 | `npm run lint`, `npm run build`, `npm test` | unit của server |
| `rules` | 73–102 | rules test trên Firestore emulator | integration (rules) |
| `integration` | 104–148 | callable thật trên emulator | integration (functions) |

- **Vì sao "máy khác" quan trọng:** máy bạn có sẵn file chưa commit, biến môi trường, cache. Lỗi có thật của EH
  (ghi trong `05_sua_v1.md`): `Google.svg` so với `google.svg`. Windows không phân biệt hoa thường nên máy bạn chạy
  được; Linux của CI có phân biệt nên **đỏ**. CI bắt được thứ "trên máy em vẫn chạy".
- **CI không có bí mật:** dòng 129–139 ghi một `.env.local` toàn giá trị giả (`ci-fake`). Test tích hợp chạy được vì
  thanh toán và AI đi qua cổng có bản giả (bài 13). Không có khoá thật nào nằm trên GitHub.
- **Phiên bản cố định:** dòng 27 `flutter-version: 3.41.5`, dòng 57 `node-version: 22`: máy CI dùng đúng bản như máy
  bạn, khỏi "xanh hôm nay, đỏ ngày mai vì công cụ tự lên đời".
- **Câu lệnh kiểm trước khi push** trong `CLAUDE.md` của EH (`dart format --set-exit-if-changed . && flutter analyze
  && flutter test`) là chạy tay đúng job `app`. Dấu `&&` làm đúng việc "đỏ thì dừng": lệnh sau chỉ chạy khi lệnh
  trước thoát `0`.

## Xong khi

- [ ] `dart run ci.dart` in đúng 4 dòng như đề
- [ ] Đã thấy lượt 2a: in `SAI` mà `$LASTEXITCODE` là `0`
- [ ] Đã thử phá cả 3 kiểu, mỗi kiểu dừng đúng một bước khác nhau
- [ ] Mở `ci.yml`, chỉ ra ba bước của job `app`
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "What does your CI pipeline do?"
