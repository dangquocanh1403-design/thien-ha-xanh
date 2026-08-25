# Thiết lập admin và duyệt tài khoản

## A. Nếu chưa từng cấu hình Supabase

1. Tạo project tại https://supabase.com.
2. Mở **SQL Editor**, sao chép toàn bộ `supabase-setup.sql` và bấm **Run**.

## B. Nếu đã dùng phiên bản đăng nhập cũ

1. Chạy toàn bộ `supabase-admin-upgrade.sql` trước.
2. Sau đó chạy toàn bộ `supabase-setup.sql` mới.

Hai bước này giữ lại dữ liệu thành viên cũ.

## 1. Tạo tài khoản admin đầu tiên

1. Vào **Authentication → Users → Add user → Create new user**.
2. Nhập email và mật khẩu admin; bật **Auto Confirm User** nếu có.
3. Mở tài khoản vừa tạo và sao chép **User UID**.
4. Trong **SQL Editor**, thay thông tin rồi chạy:

```sql
insert into public.manager_profiles(user_id, display_name, email, role, status)
values('UUID_ADMIN', 'Tên quản trị viên', 'admin@email.com', 'admin', 'approved');
```

Admin phải được khởi tạo thủ công đúng một lần. Không có nút tự đăng ký admin để tránh người lạ tự lấy quyền quản trị.

## 2. Kết nối website

1. Mở **Project Settings → API** trong Supabase.
2. Sao chép **Project URL** và **anon/publishable key**.
3. Mở `supabase-config.js`, thay hai giá trị mẫu.
4. Không dùng `service_role key` trong website.
5. Nén và triển khai lại website lên Netlify.

## 3. Nhóm trưởng và nhóm phó đăng ký

1. Mở website, chọn **Đăng ký**.
2. Nhập họ tên, email, mật khẩu và chọn vai trò.
3. Nếu Supabase yêu cầu xác nhận email, mở email và bấm liên kết xác nhận.
4. Tài khoản lúc này có trạng thái **Chờ duyệt** và chưa xem được dữ liệu.
5. Admin đăng nhập, bấm **Duyệt tài khoản**, sau đó chọn **Duyệt**.
6. Nhóm trưởng/nhóm phó đăng nhập lại và sử dụng app.

Admin cũng có thể **Khóa** hoặc **Từ chối** tài khoản. Quy tắc RLS trong cơ sở dữ liệu ngăn tài khoản chưa duyệt đọc hoặc sửa danh sách thành viên.
