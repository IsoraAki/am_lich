# Âm Lịch

Ứng dụng Flutter dùng Cubit, hiển thị lịch âm Việt Nam theo UTC+7.

- Lịch ngày dạng lịch treo tường, ngày âm lớn, Can Chi, giờ hoàng đạo.
- Lịch tháng âm hoặc dương, mặc định âm lịch, ghi nhớ chế độ đã chọn.
- Tháng nhuận và ngày hoàng đạo, hắc đạo theo hệ 12 thần truyền thống.
- Widget màn hình chính cho Android và iOS 17 trở lên, tự tính ngày hiện tại khi ứng dụng đóng.

## Chạy và kiểm tra

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Android hỗ trợ nút **Thêm tiện ích màn hình chính** trong màn Lịch ngày. Nếu launcher hỗ trợ, nút mở hộp thoại ghim widget. Có thể thêm thủ công bằng cách nhấn giữ màn hình chính, chọn Tiện ích và Âm Lịch.

Trên iPhone, nhấn giữ màn hình chính, chọn Sửa, Thêm tiện ích và Âm Lịch. Khi build cho thiết bị iOS thật, chọn signing team cho cả target Runner và LunarWidget trong Xcode.

## Dữ liệu lịch

Ứng dụng hỗ trợ ngày dương từ 1900 đến hết 2199. Các phép tính thiên văn dùng [vnlunar](https://pub.dev/packages/vnlunar), dựa trên thuật toán của Hồ Ngọc Đức. Phần xác định điểm Sóc tìm hai phía quanh chu kỳ ước tính để tránh lỗi ngày âm 0 ở ranh giới tháng.

Widget Android và iOS dùng cùng bảng đầu tháng âm, hoạt động độc lập với tiến trình Flutter. Tạo lại bảng sau khi thay đổi phép đổi lịch bằng lệnh sau.

```sh
dart run tool/generate_widget_calendar.dart
```

Ngày hoàng đạo, hắc đạo và giờ hoàng đạo dùng quy tắc khởi Thanh Long và hệ 12 thần được mô tả tại [GioHoangDao.vn](https://giohoangdao.vn/index.php/phuong-phap-tinh.html). Tháng nhuận dùng quy tắc của tháng cùng số.

Font Be Vietnam Pro được đóng gói cùng ứng dụng, giấy phép tại `assets/fonts/OFL.txt`.

## Bản Android phát hành

Application ID là `com.isora.am_lich`. Bản release dùng upload key alias `amlich`, đọc cấu hình từ `android/key.properties` và keystore từ `android/app/amlich.jks`. Hai tệp này được bỏ qua bởi Git.

```sh
flutter build appbundle --release
```

AAB được tạo tại `build/app/outputs/bundle/release/app-release.aab`. Sao lưu keystore và cấu hình ký để tiếp tục phát hành các phiên bản sau. Trên máy build khác, khôi phục hai tệp vào đúng vị trí trước khi build release.
