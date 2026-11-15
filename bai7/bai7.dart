void main() {
  final prices = {'thuong': 100000, 'vip': 500000};
  final requests = {
    'App thật': {'type': 'vip', 'quantity': 2, 'totalAmount': 1000000},
    'Kẻ sửa giá': {'type': 'vip', 'quantity': 2, 'totalAmount': 2000},
    'Loại vé bịa': {'type': 'free', 'quantity': 1},
  };

  int? createBooking(Map<String, Object> request) {
    return (prices[request['type'] as String])! * (request['quantity'] as int);
  }

  print('Bảng giá: $prices');
  for (final entry in requests.entries) {
    print('${entry.key}: ${createBooking(entry.value)}');
  }
}
