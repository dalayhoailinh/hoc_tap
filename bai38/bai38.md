# Bài 38 (thí nghiệm Flutter): URL là nguồn sự thật

**Lõi một câu:** với GoRouter, màn hình là **hàm của URL**: mọi thứ một trang cần để dựng lại mình phải nằm **trên
đường dẫn** (`/events/42`), vì người dùng có thể tới thẳng URL đó từ một link, một lần F5, một thông báo, lúc app
chưa có gì trong tay. Và một hàm `redirect` chạy **trước mỗi lần đổi URL** để quyết ai được vào đâu.

## Chuẩn bị (một lần)

```powershell
cd D:\dev\hoc\bai38
flutter create --empty --platforms=windows app
cd app
flutter pub add go_router
flutter run -d windows
```

Chỉ sửa `lib/main.dart`. Lưu xong bấm `R` (route không nạp nóng được bằng `r`).

Trên máy tính không có "bấm link từ ngoài vào", nên bài này đóng vai nó bằng cách đổi `initialLocation`: đó là URL
app nhận được lúc vừa mở, **khi chưa có nút nào được bấm**.

## Các lượt

| Lượt | Viết thêm | Chạy thấy |
|---|---|---|
| 1 | **Vỏ** bên dưới: hai route `/` và `/detail`; nút đưa dữ liệu sự kiện qua `extra` | Mở app: `mở: Trang chủ \| URL: /`. Bấm **Xem sự kiện 42**: `mở: Sự kiện 42 \| URL: /detail` |
| 2 | Đổi `initialLocation` thành `'/detail'` (người dùng mở thẳng link đó) | Màn hình đỏ: `type 'Null' is not a subtype of type 'Map<String, int>' in type cast` |
| 3 | Id lên đường dẫn: route `/events/:eventId`, trang đọc `state.pathParameters['eventId']`; nút đổi thành `context.go('/events/42')`; `initialLocation: '/events/7'` | Mở app: `mở: Sự kiện 7 \| URL: /events/7`. Bấm nút: tiêu đề thành `Sự kiện 42` |
| 4 | Thêm route `/tickets`, `/login`. Hàm thuần `decideRedirect(signedIn, location)`: chưa đăng nhập mà vào `/tickets` thì về `/login?redirect=<đường dẫn cũ>`. Nối vào `redirect:`. `initialLocation: '/tickets'` | `mở: Đăng nhập \| URL: /login?redirect=%2Ftickets` |
| 5a | Biến `loggedIn` (một `ValueNotifier<bool>`), nút **Đăng nhập hoặc đăng xuất** đảo nó. `decideRedirect`: đã đăng nhập mà đang ở `/login` thì đi tới `redirect` (không có thì `/`) | Bấm nút: **không có gì xảy ra**, vẫn đứng ở Đăng nhập ← router không biết `loggedIn` vừa đổi |
| 5b | Thêm `refreshListenable: loggedIn` | Bấm nút: `mở: Vé của tôi \| URL: /tickets`. **Không ai gọi `go`.** |
| 6 | Dòng `Quay lại được: ${context.canPop()}` trên trang; hai nút **go sự kiện 42** và **push sự kiện 42**; nút **Về trang chủ** | Từ trang chủ bấm `push`: `Quay lại được: true`. Về trang chủ, bấm `go`: `Quay lại được: false` |

Lượt 1 → 2 là lỗ R3 của EH: `extra` là một object nằm **trong RAM của lần bấm đó**. Đi bằng nút thì có; tới bằng URL
thì không ai đưa. Trên web, F5 là tới bằng URL.

Lượt 5b là bài 6 lượt 6b với công cụ thật: đăng nhập xong, `loggedIn` đổi, router hỏi lại `redirect`, và tự đưa bạn
về đúng trang bạn định vào lúc đầu.

## Từng lượt

### Lượt 1 (vỏ)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Screen('Trang chủ', state.uri),
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) {
        final event = state.extra as Map<String, int>;
        return Screen('Sự kiện ${event['id']}', state.uri);
      },
    ),
  ],
);

void main() => runApp(MaterialApp.router(routerConfig: router));

class Screen extends StatefulWidget {
  const Screen(this.title, this.uri, {super.key});
  final String title;
  final Uri uri;

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  @override
  void initState() {
    super.initState();
    debugPrint('mở: ${widget.title} | URL: ${widget.uri}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          TextButton(
            onPressed: () => context.go('/detail', extra: {'id': 42}),
            child: const Text('Xem sự kiện 42'),
          ),
        ],
      ),
    );
  }
}
```

- `GoRoute(path, builder)`: "URL khớp `path` thì dựng trang này". `state` mang mọi thứ về URL hiện tại.
- `MaterialApp.router(routerConfig: router)`: từ đây **router** quyết trang nào hiện, không phải `home:`.
- Dòng `mở:` in trong `initState`, tức là mỗi lần một trang **được tạo mới** (bài 32).

### Lượt 3: tham số trên đường dẫn

```dart
GoRoute(
  path: '/users/:userId',
  builder: (context, state) => Text('Người dùng ${state.pathParameters['userId']}'),
)
```

`:userId` là một chỗ trống; `/users/9` thì `pathParameters['userId']` là chuỗi `'9'`.

Để ý lúc bấm nút ở lượt 3: tiêu đề đổi thành `Sự kiện 42` nhưng **không có dòng `mở:` mới**. Cùng một route, Flutter
giữ State cũ và chỉ đưa widget mới (bài 32 lượt 4, bài 34). Trang thật mà tải dữ liệu trong `initState` thì sẽ vẫn
hiện **sự kiện 7** dưới tiêu đề 42. Thử phá 1 sửa chuyện này.

### Lượt 4: `redirect`

```dart
String? decideRedirect(bool signedIn, Uri location) {
  // null: ở lại. Chuỗi: đi tới đó.
}
```

Viết nó là **hàm thuần** nằm ngoài router (bài 8): nhận trạng thái đăng nhập và URL, trả `null` hoặc URL mới. Nối
vào router bằng một dòng: `redirect: (context, state) => decideRedirect(loggedIn.value, state.uri),` (lượt 4 chưa có
`loggedIn` thì tạm đưa `false`).

Gói đường dẫn cũ vào tham số: `'/login?redirect=${Uri.encodeComponent(location.toString())}'`. `encodeComponent` đổi
`/` thành `%2F` để nó không bị hiểu là một phần của đường dẫn.

### Lượt 5: router nghe ai

```dart
final loggedIn = ValueNotifier(false);
```

`ValueNotifier` là cái hộp một giá trị, ai nghe thì được báo khi `value` đổi (một Cubit bé xíu). Đọc tham số
`redirect` trên URL: `location.queryParameters['redirect']`.

`refreshListenable: loggedIn` nghĩa là "mỗi lần cái này báo đổi, **chạy lại `redirect`** cho URL đang đứng".

### Lượt 6: `go` và `push`

- `context.go('/x')`: **đổi URL** thành `/x`. Chồng trang được dựng lại theo URL đó.
- `context.push('/x')`: **đặt thêm** trang `/x` lên trên trang hiện tại; có nút quay lại về trang cũ.

## Thử phá

1. Ở lượt 3, cho trang một key theo URL: sửa constructor thành
   `Screen(this.title, this.uri) : super(key: ValueKey(uri));` (bỏ `const` ở các chỗ gọi nếu bị báo). Bấm nút: giờ
   **có** dòng `mở: Sự kiện 42 | URL: /events/42`. URL đổi → key đổi → State mới (bài 34).
2. Ở lượt 5b, trong `decideRedirect` trả `'/login'` trơn (bỏ phần `?redirect=`). Đăng nhập xong bạn về đâu? Trang chủ,
   không phải Vé của tôi. Người dùng bấm vào một link vé, đăng nhập xong lại bị thả về trang chủ.

## Bắc cầu sang project

| Bài 38 | EH |
|---|---|
| `decideRedirect` hàm thuần | `app/lib/core/routes/route_policy.dart` dòng 32–40, cùng tên. Bản thật nhận thêm vai trò, nền tảng |
| Khách vào trang cần đăng nhập → `/login?redirect=` | Cùng file dòng 42–52, `_forGuest`: `Uri.encodeComponent(location.toString())` y hệt |
| Đăng nhập xong về `redirect` | Dòng 67–69: `_safeReturnTarget(location, role) ?? homeFor(role)`. "Safe": chỉ về nếu vai trò đó được phép vào |
| `redirect:` + `refreshListenable:` | `app/lib/core/routes/app_router.dart` dòng 37–38: `redirect: _redirect, refreshListenable: _StreamRefresh(_authBloc.stream)` |
| `loggedIn` | `AuthBloc` (bài 29): router nghe stream state của nó |
| Lượt 2: `extra` mất khi vào bằng URL | Lỗ R3 trong `05_sua_v1.md`: `/booking/select` cần `EventEntity`, `/booking/payment` cần `BookingEntity` qua `extra`; F5 là bị đẩy về `/` |
| Lượt 3: id trên đường dẫn | `/events/:eventId/booking` (đã về), `/booking/:bookingId/payment` (gd4) |
| Thử phá 1 | ADR 11: trang đọc theo id có `key: ValueKey(id)` |
| Bảng test của `decideRedirect` | `app/test/core/routes/route_policy_test.dart`: khoảng 50 ca, chạy không cần thiết bị |

- **Deep link thật** (bấm `https://…/events/42` trên điện thoại mở thẳng app): hệ điều hành đưa URL đó cho app lúc
  khởi động, GoRouter nhận nó đúng như `initialLocation` của bạn. Phần khai báo với Android/iOS "link này thuộc app
  tôi" là cấu hình, không phải code Dart. Trên web, mọi URL đều là deep link.
- **`go` hay `push` trong EH:** trang cùng cấp (đổi tab, về trang chủ) dùng `go`; trang sâu đè lên (chi tiết sự kiện
  trên app) dùng `push`. Kế hoạch ghi một bẫy: `redirect` chỉ thấy trang gốc dưới các trang `push`.
- **Vì sao URL web của EH không có `#`:** `usePathUrlStrategy()` trong `main.dart`. Không liên quan logic route; chỉ
  là cách trình duyệt viết địa chỉ.

## Xong khi

- [ ] Thấy lượt 2 (màn hình đỏ) và lượt 5a (bấm đăng nhập không có gì xảy ra)
- [ ] Lượt 5b: đăng nhập xong tự về `/tickets`
- [ ] Đã thử phá cả 2 cách
- [ ] Nói lại câu lõi bằng lời của mình, kèm câu trả lời: "How does GoRouter handle deep links?" (ba ý: URL đủ để
  dựng trang, `redirect` chạy trước, `?redirect=` đưa về chỗ cũ)
