# Bài 43 (thí nghiệm git): merge và rebase

**Lõi một câu:** nhánh của mình và `main` đã rẽ đôi. **Merge** giữ nguyên cả hai đường và thêm **một commit nối** có
hai cha. **Rebase** nhấc commit của mình lên, **chép lại** chúng lên đầu `main`: lịch sử thành một đường thẳng, nhưng
commit của mình mang **mã mới**, tức là lịch sử đã bị viết lại.

Bài này không có Dart. Bạn gõ lệnh git trong một **repo thử riêng**, không đụng repo nào đang dùng.

## Chuẩn bị

Tạo repo thử **bên ngoài** `D:\dev\hoc` (repo lồng trong repo dễ rối):

```powershell
mkdir D:\dev\thu-git
cd D:\dev\thu-git
git init -b main thu
git init --bare remote.git
cd thu
```

`remote.git` đóng vai GitHub (một kho "ở xa" để `push` tới). Xong bài thì xoá cả `D:\dev\thu-git`.

Lệnh xem lịch sử dùng suốt bài: `git log --graph --oneline --all`

Mã commit (7 ký tự đầu dòng) của bạn sẽ **khác** trong bài. Thứ cần so là **hình dạng** và việc mã có **đổi** hay
không.

## Các lượt

| Lượt | Làm gì | Chạy thấy |
|---|---|---|
| 1 | Dựng cảnh rẽ đôi: commit `A` trên `main`; tạo nhánh `bai`, commit `B`; về `main`, commit `C`. Đẩy cả hai nhánh lên `remote` | Hình 1: hai đường tách ra từ `A` |
| 2 | Trên `bai`: `git merge main -m "nối main vào bai"` | Hình 2: thêm một commit có **hai đường nhập lại**. `B` giữ nguyên mã |
| 3 | Quay lại như chưa merge: `git reset --hard HEAD~1` | `git log --oneline` chỉ còn `B`, `A` |
| 4 | Trên `bai`: `git rebase main` | Hình 3: **một đường thẳng** `A → C → B`. Mã của `B` **đã đổi** |
| 5 | `git push` | **Bị từ chối:** `! [rejected] bai -> bai (non-fast-forward)` |
| 6 | Về `main`: `git merge --squash bai` rồi `git commit -m "bài: lời giải"` | Hình 4: `main` có thêm **một** commit gói cả nhánh |

## Từng lượt

### Lượt 1: dựng cảnh

```powershell
"A" > a.txt; git add .; git commit -m "A: nền"
git switch -c bai
"B" > b.txt; git add .; git commit -m "B: bài của mình"
git switch main
"C" > c.txt; git add .; git commit -m "C: người khác đẩy lên main"
git remote add origin ../remote.git
git push -u origin main bai
git log --graph --oneline --all
```

Hình 1:

```
* d1e828c C: người khác đẩy lên main
| * 6d0dc1e B: bài của mình
|/
* 13e7bdb A: nền
```

Đây là chuyện thường ngày: bạn đang làm trên nhánh, trong lúc đó `main` có thêm commit của người khác.

### Lượt 2: merge

```powershell
git switch bai
git merge main -m "nối main vào bai"
git log --graph --oneline
```

Hình 2:

```
*   6c23ed7 nối main vào bai
|\
| * d1e828c C: người khác đẩy lên main
* | 6d0dc1e B: bài của mình
|/
* 13e7bdb A: nền
```

- Commit `6c23ed7` là commit nối: nó không chứa thay đổi nào của riêng ai, chỉ ghi "hai đường này gặp nhau ở đây".
- `B` vẫn là `6d0dc1e`. **Không commit cũ nào bị đụng tới.** Merge chỉ thêm.
- `dir` thấy đủ `a.txt`, `b.txt`, `c.txt`.

### Lượt 3: quay lại

`git reset --hard HEAD~1` bỏ commit trên cùng (commit nối) **và** đưa file về như trước. An toàn ở đây vì commit nối
chưa `push`. (README của `hoc` có ghi: đã push rồi thì hỏi trước khi sửa.)

### Lượt 4: rebase

```powershell
git rebase main
git log --graph --oneline
```

Hình 3:

```
* 9720f4b B: bài của mình
* d1e828c C: người khác đẩy lên main
* 13e7bdb A: nền
```

- Đường thẳng, không có commit nối. Đọc như thể bạn bắt đầu làm **sau khi** `C` đã có.
- `B` giờ là `9720f4b`, không còn `6d0dc1e`. Cùng nội dung, cùng câu ghi, nhưng là **một commit khác**: cha của nó
  đổi từ `A` sang `C`, mà mã commit tính từ cả cha. Git không "dời" commit được; nó tạo bản sao rồi bỏ bản cũ.

### Lượt 5: cái giá của viết lại lịch sử

```
 ! [rejected]        bai -> bai (non-fast-forward)
error: failed to push some refs to '../remote.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart.
```

Trên `remote`, nhánh `bai` vẫn trỏ `6d0dc1e` (đã đẩy ở lượt 1). Máy bạn giờ không có commit đó nữa. Git từ chối vì
đẩy lên nghĩa là **xoá** `6d0dc1e` ở kho chung.

Ép được bằng `git push --force-with-lease`. Trên nhánh **chỉ mình bạn dùng** thì ổn. Trên nhánh **người khác cũng
đang kéo về** thì bạn vừa rút mất nền dưới chân họ.

Luật ngón tay cái: **đừng rebase thứ đã push lên nhánh dùng chung.**

### Lượt 6: squash

```powershell
git switch main
git merge --squash bai
git commit -m "bài: lời giải"
git log --graph --oneline
```

Hình 4:

```
* 1e1e47a bài: lời giải
* d1e828c C: người khác đẩy lên main
* 13e7bdb A: nền
```

`--squash` lấy **toàn bộ thay đổi** của nhánh, dồn thành một lần sửa chưa commit; bạn commit nó thành **một** commit
trên `main`. Nhánh `bai` vẫn còn nguyên với từng commit nhỏ của nó.

## Thử phá

1. Làm lại từ lượt 1 trong một thư mục mới, nhưng cho `B` và `C` **cùng sửa `a.txt`** theo hai cách khác nhau. Merge
   hay rebase đều dừng lại báo **conflict**. Mở `a.txt`, thấy `<<<<<<<`, `=======`, `>>>>>>>`: sửa tay, `git add`,
   rồi `git merge --continue` hoặc `git rebase --continue`. Merge và rebase khác nhau ở **hình dạng lịch sử**, không
   khác ở chuyện có conflict hay không.
2. Sau lượt 4, gõ `git reflog`. Thấy `6d0dc1e` vẫn còn đó: git giữ commit "đã bỏ" thêm một thời gian. Rebase hỏng thì
   `git reset --hard <mã cũ>` là về lại.

## Bắc cầu sang project

| Bài 43 | Chỗ bạn đang dùng |
|---|---|
| Lượt 6 | `D:\dev\hoc\README.md`, mục Git: "Xong cả bài: `git switch main` → `git merge --squash baiN` → `git commit`". Mỗi bài một commit trên `main`, từng lượt vẫn xem lại được trên nhánh `baiN` |
| Lượt 2 | EH: `git merge origin/cloud/gd4-guide` (ghi trong `PROGRESS.md`) để gộp việc của phiên khác vào `feature/v2-core`. Giữ được dấu vết "phần này đến từ nhánh kia" |
| Lượt 4 | Trước khi mở PR từ một nhánh **của riêng mình**: `git rebase develop` cho nhánh nằm trên bản mới nhất, lịch sử gọn |
| Lượt 5 | Lý do README của `hoc` dặn: "Đã push rồi thì hỏi trước khi sửa" |

Chọn cái nào:

| Tình huống | Dùng |
|---|---|
| Gộp một nhánh tính năng đã xong vào nhánh chính | **Merge** (hoặc squash merge nếu muốn mỗi tính năng một commit) |
| Cập nhật nhánh riêng của mình cho kịp nhánh chính, chưa ai khác dùng nhánh đó | **Rebase** |
| Nhánh nhiều người cùng đẩy (`main`, `develop`, nhánh chung) | **Không bao giờ rebase**, chỉ merge |

Câu trả lời ngắn khi phỏng vấn: "Merge preserves history and adds a merge commit; rebase rewrites my commits on top
of the target for a linear history. I rebase my own unpushed work, and never rebase shared branches."

## Xong khi

- [ ] Thấy đủ 4 hình
- [ ] Chỉ ra được mã của `B` ở hình 2 (giữ nguyên) và hình 3 (đã đổi)
- [ ] Đã thấy `push` bị từ chối ở lượt 5 và giải thích được vì sao
- [ ] Đã thử phá 2 (`reflog`)
- [ ] Đã xoá `D:\dev\thu-git`
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "Merge vs rebase"
