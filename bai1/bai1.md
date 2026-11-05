# Bài 1: chỉ cho đổi field được phép

**Lõi một câu:** rules là câu hỏi có/không cho mỗi lần ghi: so doc cũ với doc mới, chỉ cho qua khi **mọi field bị
đổi** đều nằm trong danh sách được phép.

## Đề

`bai1.dart`: mọi thứ trong `main`, không tách hàm, không package, dưới 30 dòng.

- Doc cũ: `displayName: 'Alice'`, `role: 'user'`, `isActive: true`
- Field được phép đổi: `displayName`, `phoneNumber`, `photoUrl`, `updatedAt`
- Ba lần thử ghi (mỗi lần gửi lên một patch):
  1. "sửa tên": `displayName: 'Alice Mới'`
  2. "giấu role trong lần sửa tên": `displayName: 'Alice 2'`, `role: 'admin'`
  3. "gửi lại isActive y như cũ": `isActive: true`

Phải in ra đúng:

```
sửa tên: đổi {displayName} -> cho qua
giấu role trong lần sửa tên: đổi {displayName, role} -> chặn
gửi lại isActive y như cũ: đổi {} -> cho qua
```

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | `print('hello')` trong `main` | `hello` |
| 2 | Doc cũ (Map) + field được phép (Set), in cả hai | `{displayName: Alice, role: user, isActive: true}` và `{displayName, phoneNumber, photoUrl, updatedAt}` |
| 3a | Ba lần thử gom vào một Map lồng Map, in ra | Một dòng dài có đủ 3 lần thử |
| 3b | Vòng lặp in tên từng lần thử | 3 dòng tên |
| 4 | Trong vòng lặp: ghép doc cũ với patch thành doc mới, in ra | Lần 2 có `role: admin`; lần 3 y hệt doc cũ |
| 5 | Tìm field bị đổi, in ra | `{displayName}`, `{displayName, role}`, `{}` |
| 6 | Kiểm, rồi một `print` in đúng mẫu đề | Đủ 3 dòng như đề |

## Gợi ý từng lượt

Ví dụ dùng dữ liệu khác bài. Đọc ví dụ, rồi tự chuyển sang dữ liệu của mình.

### Lượt 2: Map và Set

- **Map** là cặp tên → giá trị: `{'tên': giá trị}`. Doc là một Map.
- **Set** là cái túi các phần tử khác nhau, chỉ để hỏi "cái này có trong túi không": `{'a', 'b'}`.
  Như danh sách khách mời: không quan tâm thứ tự, không ai ghi hai lần.
- Phân biệt bằng dấu `:`. Có `:` là Map, không có là Set.
- Set này chứa **tên field** (bên trái dấu `:` của doc), không chứa giá trị.

```dart
final list = ['a', 'b', 'a'];
final set = {'a', 'b', 'a'};
print(list); // [a, b, a]
print(set); // {a, b}
print(set.contains('a')); // true
```

### Lượt 3a: Map lồng Map

Value của một Map có thể lại là một Map:

```dart
final menu = {
  'phở': {'giá': 40},
  'bún bò': {'giá': 45, 'cay': true},
};
print(menu);
```

Bài mình: key là tên lần thử, value là patch.

### Lượt 3b: vòng lặp qua Map

```dart
for (final entry in menu.entries) {
  print(entry.key); // phở, rồi bún bò
}
```

Đọc thành lời: "với mỗi cặp trong `menu`, gọi nó là `entry`, in phần key". `entry.value` là Map bên trong.

### Lượt 4: ghép hai Map

```dart
final a = {'x': 1, 'y': 2};
final b = {'y': 9};
print({...a, ...b}); // {x: 1, y: 9}
```

`...a` là "đổ hết các cặp của `a` vào đây". Trùng key thì **cái viết sau thắng**. Nghĩ xem doc cũ hay patch phải
viết sau.

### Lượt 5: giữ lại những cái thoả điều kiện

```dart
final scores = {'An': 7, 'Bình': 4, 'Chi': 9};
final passed = scores.keys.where((name) => scores[name]! >= 5).toSet();
print(passed); // {An, Chi}
```

- `keys` là **cả danh sách** tên; `name` là **từng tên một**, `where` gọi hàm nhỏ `(name) => ...` cho mỗi tên:
  `true` thì giữ, `false` thì bỏ. Tên `name` tự đặt, gọi `field` cũng được.
- "Bị đổi" là giá trị ở doc mới **khác** (`!=`) doc cũ, không phải "có mặt trong patch". Lần thử 3 có `isActive`
  nhưng giá trị y như cũ, nên không tính.

### Lượt 6: kiểm và in

- Câu cần hỏi: "danh sách được phép có chứa **hết** các field bị đổi không?". Set có hàm `containsAll`.
- Set rỗng thì luôn "chứa hết": không đổi gì thì không có gì để chặn.
- Chọn chữ bằng `dieuKien ? 'cho qua' : 'chặn'`.
- Chèn biến vào chuỗi bằng `$ten`, chèn biểu thức bằng `${...}`. Đừng nối bằng `+` và `.toString()`.
- Đặt tên đúng thứ biến chứa: biến đúng/sai thì gọi `ok`, còn chữ thì chọn lúc in.

## Thử phá

Đổi điều kiện thành "chỉ cần **một** field bị đổi được phép là cho qua" (Set có hàm `.any(...)`). Chạy lại, xem lần
nào lọt, lần nào bị chặn oan. Nghĩ xem kẻ tấn công lợi dụng chỗ lọt đó thế nào. Xong nhớ đổi lại.

## Bắc cầu sang project

Trong `firestore.rules` của Event Horizon, khối `match /users/{userId}` có dòng:

```
request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])
```

Tự ghép từng mảnh của dòng này với một lượt trong bài: cái nào là doc cũ, doc mới, field bị đổi, phép kiểm.

## Xong khi

- [ ] In đúng 3 dòng như đề
- [ ] Đã thử phá và thấy lần nào lọt
- [ ] Ghép được từng mảnh dòng rules với bài của mình
- [ ] Nói lại câu lõi bằng lời của mình
