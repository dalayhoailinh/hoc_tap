# Học bằng bản tí hon

Mỗi thư mục `baiN/` là một khái niệm lõi. Mỗi bài có `baiN.md` (đề + các lượt + gợi ý) và `baiN.dart` mình tự viết.
Không có đáp án trong thư mục: bí thì hỏi, người dạy gợi ý tới đúng chỗ đang vướng.

## Luật của một bài

- **Một ý, nói được trong một câu.** Câu đó ghi ở đầu đề.
- **Một file, mọi thứ trong `main`, không tách hàm, không package, dưới 30 dòng.**
- **Cắt vỏ, không cắt lõi.** Bỏ kiểm lỗi, bảo mật, cấu trúc; giữ cái làm nên khái niệm.
- **Tự viết từ file trắng.** Không chép, không gõ theo.

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
