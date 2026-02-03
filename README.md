# Tình Yêu Quotes (Flutter)

Ứng dụng nhỏ hiển thị các câu quotes về tình yêu (Landing page). Dự án Flutter này chứa giao diện tiếng Việt và chức năng chuyển câu tiếp theo / trước.

Hướng dẫn nhanh để push lên GitHub

1. (Chỉ lần đầu) khởi tạo git nếu chưa có:

```powershell
cd c:\Users\PC\lovesense_app
git init
git add .
git commit -m "Initial commit"
```

2a. Tạo repository và push bằng GitHub CLI (`gh`):

```powershell
gh repo create HoangThiThaoNhi/lovesense_app --public --source=. --remote=origin --push
```

2b. Hoặc thêm remote và push bằng HTTPS:

```powershell
git branch -M main
git remote add origin https://github.com/HoangThiThaoNhi/lovesense_app.git
git push -u origin main
```

Nếu bị lỗi xác thực với HTTPS, tạo một Personal Access Token (PAT) trên GitHub và dùng dạng URL: `https://<USERNAME>:<TOKEN>@github.com/...` hoặc cấu hình SSH.

Chạy app trên thiết bị/emulator:

```powershell
flutter devices
flutter run -d <deviceId>
```

Nếu bạn muốn, mình có thể hướng dẫn từng bước (đăng nhập `gh`, tạo PAT, cấu hình SSH) — nói mình biết bạn muốn dùng phương pháp nào (`gh`/HTTPS/SSH).
# lovesense_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
