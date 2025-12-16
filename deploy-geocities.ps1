# 1. CẤU HÌNH
$baseURL = "https://www.geocities.ws/bl1d/"
$rcloneRemote = "geocities:/" 

# 2. BUILD HUGO
Write-Host "Dang build Hugo..." -ForegroundColor Green
hugo --minify --baseURL $baseURL --cleanDestinationDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "Loi Build! Dung lai." -ForegroundColor Red
    exit
}

# 3. UPLOAD TỐC ĐỘ CAO (Dùng Size-Only)
Write-Host "Dang dong bo (Che do Size-Only)..." -ForegroundColor Cyan

# CÁC THAM SỐ TỐI ƯU TỐC ĐỘ:
# --transfers 3: Tăng lên 3 luồng (Mức ranh giới an toàn của Geocities).
#                Nếu vẫn bị lỗi 530, hãy giảm xuống 2.
# --size-only:   Bỏ qua check mã Hash (rất lâu) và bỏ qua check Ngày giờ (Hugo luôn làm mới ngày giờ).
#                Chỉ so sánh dung lượng file. File nào dung lượng khác thì mới upload.
#                -> Đây là chìa khóa để sync NHANH.
# --checkers 4:  Tăng tốc độ quét danh sách file.

.\rclone.exe sync ./public $rcloneRemote --progress --transfers 3 --checkers 4 --size-only --timeout 30s

Write-Host "XONG! Website cua ban tai: $baseURL" -ForegroundColor Green