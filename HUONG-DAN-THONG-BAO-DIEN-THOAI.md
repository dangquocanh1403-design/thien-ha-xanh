# Bật thông báo trực tiếp trên điện thoại

## 1. Tạo OneSignal Web App

1. Đăng ký tại https://onesignal.com và tạo một Web App.
2. Chọn **Custom Code** và nhập Site URL: `https://thien-ha-xanh.onrender.com`.
3. Trong Web Settings > Advanced Push Settings, đặt:
   - Service worker path: `/push/onesignal/`
   - Filename: `OneSignalSDKWorker.js`
   - Scope: `/push/onesignal/`
4. Sao chép **OneSignal App ID** và **REST API Key** trong Keys & IDs.

## 2. Cấu hình website

Mở `push-config.js`, thay `PASTE_ONESIGNAL_APP_ID_HERE` bằng OneSignal App ID rồi tải lại project lên GitHub/Render.

## 3. Cấu hình Supabase Edge Function

Cài Supabase CLI, đăng nhập rồi chạy tại thư mục project:

```powershell
supabase login
supabase link --project-ref tqaqydbazsvfkbqvsrqn
supabase secrets set ONESIGNAL_APP_ID="APP_ID_CUA_BAN" ONESIGNAL_REST_API_KEY="REST_API_KEY_CUA_BAN"
supabase functions deploy send-push-notification
```

Không đưa REST API Key vào `push-config.js`, GitHub hoặc bất kỳ file website nào.

## 4. Thành viên bật thông báo

- Android: mở app, vào **Thông báo**, bấm **Bật thông báo** và chọn **Cho phép**.
- iPhone/iPad 16.4+: thêm website vào Màn hình chính, mở app từ biểu tượng vừa thêm, sau đó bấm **Bật thông báo**.

Khi nhóm trưởng hoặc nhóm phó đăng một thông báo mới, thông báo trong app được lưu trước rồi Edge Function gửi push đến mọi thiết bị đã đăng ký.
