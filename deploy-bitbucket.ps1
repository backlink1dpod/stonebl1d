# 1. CẤU HÌNH
# Link repo Bitbucket của bạn (Lưu ý: Phải là .git)
$repoURL = "https://bitbucket.org/backlinknen/backlinknen.bitbucket.io.git"
# Domain web của bạn
$baseURL = "https://backlinknen.bitbucket.io/"

# 2. XÓA FILE CŨ & BUILD HUGO
Write-Host "1. Dang xoa folder public cu..." -ForegroundColor Cyan
if (Test-Path -Path ".\public") {
    Remove-Item -Path ".\public" -Recurse -Force
}

Write-Host "2. Dang build Hugo..." -ForegroundColor Green
hugo --minify --baseURL $baseURL

if ($LASTEXITCODE -ne 0) {
    Write-Host "Loi Build! Dung lai." -ForegroundColor Red
    exit
}

# 3. CHUYỂN VÀO FOLDER PUBLIC VÀ PUSH GIT
Write-Host "3. Dang day code len Bitbucket..." -ForegroundColor Cyan

# Di chuyển vào trong thư mục public
Push-Location .\public

# Khởi tạo Git ngay trong folder public
git init
git branch -m master 

# Thêm remote (Nếu lỗi đã tồn tại thì bỏ qua)
try {
    git remote add origin $repoURL
} catch {}

# Add tất cả file và Commit
git add .
git commit -m "Deploy website update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

# Force Push (Ghi đè lên branch master trên Bitbucket)
# Dùng --force để đảm bảo code trên server giống hệt dưới local
git push -u origin master --force

# Quay trở lại thư mục gốc
Pop-Location

Write-Host "XONG! Website da duoc day len: $baseURL" -ForegroundColor Green