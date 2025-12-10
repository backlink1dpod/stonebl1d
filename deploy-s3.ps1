# 1. CẤU HÌNH DOMAIN & BUCKET
$bucketName = "stonebl1d" # <--- Thay tên bucket AWS chính xác vào đây
# Link Static Website của AWS S3 (Vùng us-east-1)
$baseURL = "http://$bucketName.s3-website-us-east-1.amazonaws.com/"

# 2. BUILD WEBSITE
Write-Host "Dang build Hugo..." -ForegroundColor Green
# --cleanDestinationDir: Xóa file rác cũ
# --minify: Nén code
hugo --minify --baseURL $baseURL --cleanDestinationDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "Loi Build! Dung lai." -ForegroundColor Red
    exit
}

# 3. UPLOAD LÊN AWS S3
Write-Host "Dang dong bo len AWS S3 (Chi file thay doi)..." -ForegroundColor Cyan

# GIẢI THÍCH:
# aws-blog:$bucketName : Remote và tên Bucket.
# --checksum : AWS S3 hỗ trợ MD5 rất tốt, rclone check cái này cực nhanh để bỏ qua file trùng.
# --transfers 32 : Mở 32 luồng upload song song.

.\rclone.exe sync ./public "aws-blog:$bucketName" --progress --transfers 32 --checksum

Write-Host "XONG! Website cua ban tai: $baseURL" -ForegroundColor Green