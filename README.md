# QUẢN LÝ THÀNH VIÊN NHÓM THIÊN HÀ XANH

Ứng dụng PWA quản lý cơ cấu và thông tin thành viên nhóm trên máy tính và điện thoại, có đăng nhập Supabase cho nhóm trưởng và nhóm phó.

## Tính năng

- Quản lý một nhóm trưởng, một nhóm phó và các thành viên.
- Thông tin: họ tên, vai trò, đối tượng (Tình nguyện viên/Hội viên), lớp, khoa, số điện thoại.
- Thêm, sửa, xóa, tìm kiếm và lọc theo vai trò.
- Chế độ thẻ và danh sách.
- Gọi điện trực tiếp khi chạm số điện thoại trên mobile.
- Thống kê tổng người, số tình nguyện viên, nhóm trưởng và nhóm phó.
- Xuất CSV để mở trong Excel hoặc Google Sheets.
- Đồng bộ dữ liệu trực tuyến giữa tài khoản nhóm trưởng và nhóm phó.
- Row Level Security ngăn người chưa được cấp quyền đọc hoặc sửa dữ liệu.
- PWA, toàn màn hình và cache offline khi chạy qua HTTPS.
- Giao diện đỏ–trắng theo chủ đề vận động hiến máu.
- Chọn, thay hoặc xóa ảnh riêng cho từng thành viên; ảnh hiển thị làm ảnh bìa trên thẻ.

Ảnh được thu nhỏ tối đa 900 × 500 pixel và nén JPEG trước khi lưu vào localStorage. Nên dùng ảnh ngang, rõ mặt và tránh thêm quá nhiều ảnh dung lượng lớn vì bộ nhớ của trình duyệt có giới hạn.

Nhóm trưởng hoặc nhóm phó có thể mở chức năng sửa hồ sơ để thay đổi một người giữa **Tình nguyện viên** và **Hội viên**. Vì phiên bản hiện tại chưa có đăng nhập, ứng dụng chưa thể xác minh danh tính người đang thao tác.

## Dùng trên điện thoại

Kéo `ThienHaXanh-deploy.zip` lên https://app.netlify.com/drop. Mở URL nhận được trên điện thoại rồi chọn **Thêm vào màn hình chính**.

## Thiết lập đăng nhập

Đọc `HUONG-DAN-SUPABASE.md`, chạy `supabase-setup.sql`, tạo hai user rồi điền `supabase-config.js` trước khi triển khai.

## Lưu ý

Không đưa Supabase `service_role key` hoặc mật khẩu người dùng vào mã nguồn. Chỉ dùng `anon/publishable key` trong `supabase-config.js`.
