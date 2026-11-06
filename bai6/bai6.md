# Bài 6: ghép thành hệ đăng nhập chạy thật

**Lõi một câu:** server là **bài 4** bọc thêm HTTP và file `users.txt`; app là **bài 5** bọc thêm widget và lệnh gọi
HTTP. Lõi mới duy nhất là **refresh token** (lượt 10): vé ngắn hạn hết hạn thì dùng vé dài hạn đổi vé mới, người dùng
không phải đăng nhập lại.

Làm xong là đi trọn một vòng: đăng ký → đăng nhập ra token → màn theo role → đổi role → token hết hạn → tự đổi token.

Khác bài 1–5: nhiều file, có một package (`http`), dài hơn 30 dòng. Phần **lõi** đã viết ở bài 4–5 thì tự viết lại.
Phần **vỏ** (khung HTTP, widget) có sẵn code bên dưới: gõ nhanh, không cần nhớ.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai6
flutter create --empty --platforms=windows app
cd app
flutter pub add http
```

| | Server | App |
|---|---|---|
| File | `bai6\server.dart` | `bai6\app\lib\auth.dart`, `bai6\app\lib\main.dart` |
| Chạy | Terminal 1: `cd D:\dev\hoc\bai6` → `dart run server.dart` | Terminal 2: `cd D:\dev\hoc\bai6\app` → `flutter run -d windows` (lần đầu chờ 1–2 phút) |
| Sửa xong | `Ctrl+C` rồi chạy lại | Lưu file, bấm `R` ở terminal 2 |

- Vì sao `R` (hot restart) chứ không `r` (hot reload): `r` không chạy lại `main()` và giữ nguyên các object cũ, mà bài
  này hay đổi `main` và lớp `Auth`.
- Server tắt là **sổ token mất hết** (sổ nằm trong RAM). Sửa server xong thì đăng nhập lại trên app.
- Tài khoản: `an@hoc.test` / `123` là admin, server tự tạo lúc chạy lần đầu. Bình tự đăng ký ở lượt 4.

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** server: trả 404 cho mọi đường | Trình duyệt mở `localhost:3000/abc` → `{"error":"Không có đường này"}`; terminal 1: `GET /abc -> 404` |
| 2 | **Vỏ** app: màn đăng nhập, bấm nút thì hiện nguyên câu server trả (TẠM) | Bấm Đăng nhập → `404 {"error":"Không có đường này"}` |
| 3 | Server `POST /login` (bài 4 lượt 1–2): tìm dòng trong `users.txt`, so mật khẩu, phát token, ghi sổ | Sai: `401 {"error":"Sai email hoặc mật khẩu"}`; đúng: `200 {"token":"941e3fab"}` (mỗi lần một số khác) |
| 4 | Server `POST /register`: email có rồi → 409; chưa có → thêm dòng role `user`, phát token | Đăng ký `binh@hoc.test` / `456` → `200 {"token":…}`, `users.txt` có 2 dòng; bấm lần nữa → `409 {"error":"Email đã có"}` |
| 5a | Server: cái khoá (bài 4 lượt 3) + `GET /me` | Trình duyệt mở `localhost:3000/me` (không có token) → `{"error":"Cần đăng nhập"}`; terminal 1: `GET /me -> 401` |
| 5b | App: giữ token, gửi kèm khi hỏi `/me` (TẠM) | An → `200 {"email":"an@hoc.test","role":"admin"}` |
| 6a | App: cái loa trong `auth.dart` (bài 5 lượt 1), `reload()` báo user vào loa | Sai → `Sai email hoặc mật khẩu`; đúng → chữ dưới nút biến mất mà màn **không đổi** (chưa ai nghe loa), terminal 1: `GET /me -> 200` |
| 6b | App: `SessionGate` nghe loa, chọn màn theo role (bài 5 lượt 2) | An → màn **Quản trị**; Đăng xuất → về Đăng nhập; Bình → **Trang chủ** |
| 7 | Server `GET /users` chỉ cho admin (bài 4 lượt 4). App: nút Người dùng | An bấm → `200 {"users":["an@hoc.test","binh@hoc.test"]}` |
| 8 | App: nút Tải lại | Sửa role Bình trong `users.txt`: app **chưa** đổi; bấm Tải lại → sang Quản trị |
| 9a | Server: token sống 20 giây (bài 4 lượt 5) | Đăng nhập An, đợi 20 giây, bấm Tải lại: app **vẫn đứng ở Quản trị**, terminal 1: `GET /me -> 401` |
| 9b | App: gặp 401 thì đăng xuất | Làm lại như 9a: bấm Tải lại → về Đăng nhập |
| 10 | Refresh token: hết hạn thì app lặng lẽ xin token mới rồi gọi lại | Đợi 20 giây, bấm Tải lại → vẫn ở lại, số token đổi; terminal 1: `GET /me -> 401`, `POST /refresh -> 200`, `GET /me -> 200` |

## Từng lượt

### Lượt 1: khung server (vỏ)

`bai6\server.dart`:

```dart
import 'dart:convert';
import 'dart:io';

void send(HttpRequest req, int status, Object body) {
  print('${req.method} ${req.uri.path} -> $status');
  req.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}

Future<void> handle(HttpRequest req) async {
  send(req, 404, {'error': 'Không có đường này'});
}

void main() async {
  final server = await HttpServer.bind('localhost', 3000);
  print('Server chạy ở http://localhost:3000');
  await for (final req in server) {
    await handle(req);
  }
}
```

- `HttpServer.bind` mở cổng 3000 trên máy mình. `await for`: mỗi request tới là một vòng lặp, xong cái này mới tới cái
  sau.
- `send` trả JSON và in một dòng log. `..` (cascade) là gọi liền nhiều lệnh trên cùng `req.response`.
- Trình duyệt hỏi thêm `/favicon.ico` (icon của tab) nên log có thêm dòng đó: kệ nó.
- Cổng 3000 vì 8080 là của Firestore emulator trong EH.

### Lượt 2: khung app (vỏ)

`app\lib\auth.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

Uri _url(String path) => Uri.parse('http://localhost:3000$path');

class Auth {
  // TẠM — lượt 6: trả câu lỗi hoặc null
  Future<String> signIn(String path, String email, String password) async {
    final res = await http.post(
      _url(path),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return '${res.statusCode} ${res.body}';
  }
}

final auth = Auth();
```

`app\lib\main.dart`, thay hết nội dung cũ:

```dart
import 'package:flutter/material.dart';

import 'auth.dart';

void main() => runApp(const MaterialApp(home: LoginPage()));

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _message = '';

  Future<void> _submit(String path) async {
    final message = await auth.signIn(path, _email.text, _password.text);
    if (mounted) setState(() => _message = message);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            FilledButton(
              onPressed: () => _submit('/login'),
              child: const Text('Đăng nhập'),
            ),
            TextButton(
              onPressed: () => _submit('/register'),
              child: const Text('Đăng ký'),
            ),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
```

- `auth.dart` là bản tí hon của gói `firebase_auth`: app chỉ nói chuyện với server qua nó. `final auth = Auth();`
  giống `FirebaseAuth.instance`.
- Đăng nhập và đăng ký dùng chung `signIn`, chỉ khác đường.
- `if (mounted)`: sau `await`, màn hình có thể đã bị đóng; gọi `setState` trên màn đã đóng là lỗi.

### Lượt 3: đăng nhập ra token

Vỏ, gõ nhanh:
- Đầu file thêm `import 'dart:math';`. Dưới các dòng import: `final db = File('users.txt');`
- Đầu hàm `handle`, đọc "phương thức + đường" và body JSON của request:

```dart
  final route = '${req.method} ${req.uri.path}';
  final body = req.method == 'POST'
      ? jsonDecode(await utf8.decoder.bind(req).join())
      : {};
```

- Đầu hàm `main`, chưa có file thì tạo admin đầu tiên:

```dart
  if (!db.existsSync()) db.writeAsStringSync('an@hoc.test,123,admin\n');
```

Lõi, tự viết:
- Sổ `owner` (token → email), đặt cạnh `db`.
- `findUser(email)`: đọc từng dòng `users.txt`, tách theo dấu phẩy, trả dòng của email đó (`[email, mật khẩu, role]`)
  hoặc `null`.
- `newToken(email)`: phần phát vé và ghi sổ của `login` bài 4.
- Trong `handle`, trên dòng 404: `if (route == 'POST /login')`. Sai thì
  `return send(req, 401, {'error': 'Sai email hoặc mật khẩu'});`, đúng thì trả `{'token': ...}`.

```dart
for (final line in File('mon.txt').readAsLinesSync()) {
  final parts = line.split(','); // 'phở,50' -> [phở, 50]
  print(parts[0]); // phở
}
```

- Có `return` trước `send` để dừng hàm, không chạy xuống dòng 404.
- So cả `'POST /login'` chứ không chỉ `/login`: gõ địa chỉ trên trình duyệt là GET, không được lọt vào nhánh này.

### Lượt 4: đăng ký

Lõi: `if (route == 'POST /register')`. Email có rồi → `409` `Email đã có`. Chưa có → thêm một dòng
`email,mật khẩu,user` vào cuối `users.txt`, rồi trả token như đăng nhập.

```dart
File('mon.txt').writeAsStringSync('cơm,35\n', mode: FileMode.append);
```

- Thiếu `mode: FileMode.append` là **ghi đè** cả file, mất luôn An. Thử một lần cho thấy, rồi xoá `users.txt` và chạy
  lại server.
- Role luôn là `user`, không lấy từ `body`: lấy thì ai cũng tự đăng ký làm admin được. Admin đầu tiên do người vận hành
  tạo (dòng trong `main`), giống `npm run dev:bootstrap` của EH.
- Đăng ký xong trả token luôn. Firebase cũng vậy: tạo tài khoản xong là đã đăng nhập.

### Lượt 5a: server hỏi "tôi là ai?"

Sau 2 nhánh `/login`, `/register`, trên dòng 404, là **cái khoá**: trên khoá là cửa ai cũng vào, dưới khoá phải có
token. Vỏ, đọc token từ header `authorization: Bearer <token>`:

```dart
  final token = req.headers.value('authorization')?.replaceFirst('Bearer ', '');
```

Lõi (bài 4 lượt 3): tra sổ ra user, không có thì `401` `Cần đăng nhập`. Dưới khoá: `GET /me` trả
`{'email': ..., 'role': ...}`.
- Gọn nhất là `findUser(owner[token])`. Token bịa thì `owner[token]` ra `null`, nên đổi `findUser` nhận `String?`.
- Từ lượt này, mở một đường lạ không kèm token (như `/abc`) cũng ra `401` chứ không còn `404`: khoá đứng trước.

### Lượt 5b: app gửi token khi hỏi

Vỏ, thêm vào lớp `Auth`:

```dart
  String? token;

  Future<http.Response> get(String path) {
    return http.get(_url(path), headers: {'authorization': 'Bearer $token'});
  }
```

Lõi (vẫn TẠM): trong `signIn`, không phải 200 thì trả như cũ; 200 thì lưu token (`jsonDecode(res.body)['token']`),
gọi `get('/me')` rồi trả status + body của lần gọi đó.

### Lượt 6a: cái loa trong `auth.dart` (lõi bài 5)

Vỏ: đầu file thêm `import 'dart:async';`, và lớp `User`:

```dart
class User {
  const User(this.email, this.role);
  final String email;
  final String role;
}
```

Trong `Auth`, cái loa của bài 5:

```dart
  final _changes = StreamController<User?>.broadcast();
  Stream<User?> get userChanges => _changes.stream;
```

Dấu `_` là riêng tư: chỉ `auth.dart` được `add`, bên ngoài chỉ được nghe. Firebase cũng vậy, bạn nghe được
`userChanges()` nhưng không tự đẩy user vào đó.

Lõi:
- `reload()`: gọi `get('/me')`, được 200 thì `add` một `User` vào loa. Đây là chỗ **duy nhất** báo user vào loa.
- `signIn`: bỏ dòng TẠM. Lỗi thì trả câu lỗi (`data['error']`); được thì lưu token, `await reload()`, trả `null`.
- `signOut()`: xoá token, `add(null)`.

Vỏ, ở `_submit` của `LoginPage`: `signIn` giờ trả câu lỗi, hoặc `null` khi vào được. Đổi thành
`final error = await auth.signIn(...)` và `_message = error ?? ''`.

Đăng nhập đúng: chữ dưới nút biến mất, terminal 1 có `GET /me -> 200`, nhưng màn **không đổi**. User đã vào loa mà
chưa ai nghe, y như thử phá 2 của bài 5.

### Lượt 6b: `SessionGate` nghe loa, chọn màn (lõi bài 5)

Vỏ: trang chủ

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${user.email} · ${user.role} · token ${auth.token}'),
            TextButton(onPressed: auth.signOut, child: const Text('Đăng xuất')),
          ],
        ),
      ),
    );
  }
}
```

- `AdminPage`: chép `HomePage`, đổi tên lớp thành `AdminPage` và tiêu đề thành `Quản trị`.
- `main`: `home: LoginPage()` đổi thành `home: SessionGate()`.

Lõi: `SessionGate` là một `StatelessWidget` trả về `StreamBuilder<User?>` nghe `auth.userChanges`; trong `builder`
là khối `if/else` của bài 5 lượt 2: `null` → `LoginPage()`, admin → `AdminPage(user: user)`, còn lại →
`HomePage(user: user)`.

```dart
StreamBuilder<int>(
  stream: temps.stream,
  builder: (context, snapshot) {
    final t = snapshot.data; // null khi stream chưa báo gì
    if (t == null) return const Text('Chưa có số đo');
    return Text('$t độ');
  },
)
```

- `StreamBuilder` = `listen` của bài 5 + vẽ lại màn mỗi lần stream báo.
- Mở app chưa có tin nào thì `snapshot.data` là `null` → màn đăng nhập. Đúng ý.
- **Không ai gọi `Navigator.push`.** Đăng nhập xong, `signIn` báo user vào loa, `SessionGate` tự đổi màn. Cả "điều
  hướng theo role" chỉ là khối `if/else` đó.

### Lượt 7: khoá thật ở server (403)

**Server.** Lõi (bài 4 lượt 4): `if (route == 'GET /users')`, role không phải admin → `403` `Không có quyền`. Admin
thì trả danh sách email (vỏ):

```dart
    final emails = db.readAsLinesSync().map((line) => line.split(',')[0]);
    return send(req, 200, {'users': emails.toList()});
```

**App** (vỏ). Đặt con trỏ vào chữ `StatelessWidget` của `AdminPage`, bấm `Ctrl+.` → *Convert to StatefulWidget*.
Trong lớp State thêm:

```dart
  var _users = '';

  Future<void> _loadUsers() async {
    final res = await auth.get('/users');
    if (mounted) setState(() => _users = '${res.statusCode} ${res.body}');
  }
```

Đầu `build` thêm `final user = widget.user;` (lớp State lấy tham số của widget qua `widget.`). Trong `Column`, dưới
nút Đăng xuất:

```dart
            FilledButton(
              onPressed: _loadUsers,
              child: const Text('Người dùng'),
            ),
            Text(_users),
```

**Thử phá ngay:** trong `SessionGate`, đổi `return HomePage(user: user);` thành `return AdminPage(user: user);`.
Đăng nhập Bình: vào được màn Quản trị, nhưng bấm Người dùng ra `403 {"error":"Không có quyền"}`. Điều hướng theo role
chỉ để **dễ dùng**; khoá thật nằm ở server. Trả lại như cũ.

### Lượt 8: Tải lại, đây là `userChanges`

Vỏ, thêm vào cả `HomePage` lẫn `AdminPage`, trên nút Đăng xuất:

```dart
            TextButton(onPressed: auth.reload, child: const Text('Tải lại')),
```

Thử: đăng nhập Bình. Mở `bai6\users.txt`, sửa `binh@hoc.test,456,user` thành `...,admin`, lưu. App **chưa** đổi.
Bấm Tải lại → sang Quản trị, token vẫn số cũ.
- App giữ **bản sao** user lấy lúc đăng nhập. Server đọc `users.txt` mỗi lần nên biết ngay; bản sao chỉ mới khi app
  hỏi lại.
- `reload()` hỏi lại rồi báo user mới vào loa. Loa này báo cả khi role đổi chứ không chỉ lúc đăng nhập/đăng xuất,
  nên mới tên là `userChanges` (bài 5 lượt 3).
- Firebase để role trong token (custom claims) nên còn chậm hơn: phải xin token mới (`getIdToken(true)`) thì role mới
  vào.
- Xong thì trả Bình về `user`.

### Lượt 9a: server cho token hết hạn

Lõi (bài 4 lượt 5, giờ giả đổi thành `DateTime.now()`): sổ `expiry`; `newToken` ghi hạn = bây giờ +
`Duration(seconds: 20)`; cái khoá thấy quá hạn → `401`.

Đăng nhập An, đợi 20 giây. Màn **vẫn đứng yên**: app không biết token đã chết, nó chỉ biết khi gọi server. Bấm Tải
lại: server trả `401`, nhưng `reload()` thấy không phải 200 thì thôi, nên app vẫn ở Quản trị với một token chết. Đó là
lỗi lượt 9b sửa.

### Lượt 9b: app gặp 401 thì đăng xuất

Lõi: trong `get`, kết quả là `401` thì `signOut()`. `get` phải thành `async` để đợi kết quả rồi mới xét.

### Lượt 10: refresh token

Token 20 giây đi kèm **mọi** request nên dễ lộ; sống ngắn thì lộ cũng chỉ hại 20 giây. Nhưng bắt người dùng đăng nhập
lại mỗi 20 giây thì không ai dùng. Cách giải: lúc đăng nhập phát thêm **refresh token**, sống lâu, chỉ dùng ở **một**
chỗ là `POST /refresh` để đổi lấy token mới.

Lõi:
- Server: sổ `refreshOwner` (refresh token → email) + `newRefreshToken(email)`. `/login` và `/register` trả cả `token`
  lẫn `refreshToken`. `POST /refresh` đặt **trên** cái khoá (lúc gọi nó thì token thường đã hết hạn): tra sổ, không có
  → `401`, có → `{'token': newToken(email)}`.
- App: lưu `refreshToken` lúc `signIn`, xoá lúc `signOut`. Hàm `_refresh()` gọi `/refresh`, được thì thay `token`, trả
  `true`/`false`. Trong `get`: gọi; gặp `401` thì thử `_refresh()`; đổi được thì gọi lại **đúng request đó**; vẫn
  `401` thì `signOut()`.

**Thử phá:** tắt server (`Ctrl+C`), chạy lại, bấm Tải lại. Về màn đăng nhập, terminal 1: `GET /me -> 401`,
`POST /refresh -> 401`. Vì sao? (Gợi ý: hai cuốn sổ nằm ở đâu?)

## Vướng

- Bấm mà màn không đổi gì: nhìn terminal 2, có `ClientException with SocketException ... refused` là server chưa chạy.
- Sửa server xong mà app "không ăn": quên `Ctrl+C` chạy lại server, hoặc chưa đăng nhập lại.
- Dòng mới trong `users.txt` dính vào dòng cũ: dòng cuối file thiếu dấu xuống dòng. Xoá file, chạy lại server.

## Vỏ đã cắt (đồ thật có, bài này không)

- Mật khẩu để chữ thường. Thật: băm (hash) như bcrypt; Firebase lo phần này.
- Không HTTPS: token đi trên mạng dạng chữ thường.
- Token 8 ký tự tra sổ. Thật: token dài, thường là JWT có chữ ký (xem bắc cầu bài 4).
- Không kiểm dữ liệu vào: gửi bậy (không phải JSON) là server sập.
- Không nhớ phiên: tắt app mở lại là phải đăng nhập lại. Firebase lưu refresh token trên máy, mở app phải đọc lại
  (mất một lúc), lúc đó chưa biết là khách hay đã đăng nhập; vì vậy EH có trạng thái `unknown` và `BootPage`.
- Hai request cùng gặp `401` thì cùng xin token mới.

## Bắc cầu sang project

| Bài 6 | Firebase / EH |
|---|---|
| `users.txt` | Firebase Auth giữ email + mật khẩu đã băm; role ở custom claims và doc `users/{uid}` |
| `POST /login`, `POST /register` | `signInWithEmailAndPassword`, `createUserWithEmailAndPassword` |
| Sổ `owner` + `expiry` | Không có sổ: ID token là JWT có chữ ký, sống 1 giờ |
| Cái khoá 401 | `request.auth` rỗng → `unauthenticated` (`functions/src/auth/completeSignUp.ts` dòng 11–12) |
| `403` ở `/users` | `isAdmin()` (`firestore.rules` dòng 8–14) |
| `auth.userChanges` | `firebaseAuth.userChanges()` (`auth_remote_datasource.dart` dòng 74) |
| `SessionGate` | `_SessionGate` (`app/lib/main.dart` dòng 160) + `decideRedirect` (`route_policy.dart` dòng 32) |
| `reload()` sau khi đổi role | `getIdToken(true)` / `user.reload()` |
| Refresh hỏng → `signOut()` | `_hasLiveSession` (`auth_remote_datasource.dart` dòng 87–99): lỗi `INVALID_REFRESH_TOKEN` (refresh token chết, như `POST /refresh -> 401` của bạn) thì `signOut()` |
| Refresh token + gọi lại | SDK của Firebase tự làm, code EH không có dòng nào |
| (không có) | Nhớ phiên khi mở lại app → `AuthState.unknown` → `BootPage` (`app/lib/main.dart` dòng 170) |

Dòng "SDK tự làm" là dòng đáng nhớ nhất: phần khó nhất của auth (refresh, gọi lại) nằm trong thư viện, nên đọc code EH
không thấy. Bài này cho bạn thấy nó.

## Git

Như README, chỉ khác lúc add: `git add bai6/server.dart bai6/app`. Đừng `git add bai6/` cả thư mục: kéo theo
`users.txt` (dữ liệu, có mật khẩu).

## Xong khi

- [ ] Đi trọn vòng: đăng ký Bình → Trang chủ; An → Quản trị → Người dùng; sửa role Bình + Tải lại; đợi 20 giây bấm Tải
  lại vẫn ở lại
- [ ] Đã làm 2 thử phá (Bình vào màn Quản trị; tắt bật server)
- [ ] Nhìn bảng bắc cầu, chỉ ra được dòng code của mình ứng với từng hàng
- [ ] Trả lời được: "Walk me through what happens when a user taps Login" (từ nút tới màn hình) và "How does your app
  handle an expired token?"
