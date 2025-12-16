<#
    SCRIPT DEPLOY TỔNG HỢP - HUGO MULTI-PLATFORM
    Hỗ trợ: Azure, B2, Bitbucket, GCS, Geocities, AWS S3, Scaleway
#>

# ==============================================================================
# 1. KHU VỰC CẤU HÌNH CHUNG (SỬA THÔNG TIN CỦA BẠN TẠI ĐÂY)
# ==============================================================================

# --- AZURE ---
$Azure_BaseURL = "https://mz12.z11.web.core.windows.net/"
$Azure_Remote  = "azure-blog:$web"

# --- BACKBLAZE B2 ---
$B2_BucketName = "stonebl1d"
$B2_BaseURL    = "https://f005.backblazeb2.com/file/stonebl1d/" 
$B2_Remote     = "b2-blog:stonebl1d"

# --- BITBUCKET ---
$BB_RepoURL    = "https://bitbucket.org/backlinknen/backlinknen.bitbucket.io.git"
$BB_BaseURL    = "https://backlinknen.bitbucket.io/"

# --- GOOGLE CLOUD STORAGE (GCS) ---
$GCS_BucketName = "stonebl1d"
$GCS_RemoteName = "gcs-blog"
$GCS_BaseURL    = "https://storage.googleapis.com/$GCS_BucketName/"

# --- GEOCITIES ---
$Geo_BaseURL    = "https://www.geocities.ws/bl1d/"
$Geo_Remote     = "geocities:/"

# --- AWS S3 ---
$AWS_BucketName = "stonebl1d"
$AWS_BaseURL    = "http://$AWS_BucketName.s3-website-us-east-1.amazonaws.com/"
$AWS_Remote     = "aws-blog:$AWS_BucketName"

# --- SCALEWAY ---
$SCW_BucketName = "bl1d"
$SCW_BaseURL    = "https://${SCW_BucketName}.s3-website.nl-ams.scw.cloud/"
$SCW_Remote     = "scw-blog:$SCW_BucketName"

# --- CLOUDFLARE R2 ---
$R2_BucketName = "stonebl1d"  # <--- Tên Bucket R2 của bạn
# Link Public (lấy trong R2 -> Settings -> Public Access -> R2.dev subdomain hoặc Custom Domain)
$R2_BaseURL    = "https://pub-c0c6ff3c85c24a12a7398d153f805a1b.r2.dev/" 
$R2_Remote     = "r2-blog:$R2_BucketName" # Tên remote trong rclone config

# ==============================================================================
# 2. HÀM HỖ TRỢ (CORE FUNCTIONS)
# ==============================================================================

function Build-Hugo {
    param ( [string]$Url )
    Write-Host "`n[HUGO] Dang build cho domain: $Url" -ForegroundColor Green
    
    # Xóa thư mục public cũ để tránh rác
    if (Test-Path ".\public") { Remove-Item -Path ".\public" -Recurse -Force -ErrorAction SilentlyContinue }

    # Chạy lệnh build
    hugo --minify --baseURL $Url --cleanDestinationDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "LOI: Hugo build that bai! Dung quy trinh." -ForegroundColor Red
        return $false
    }
    return $true
}

# ==============================================================================
# 3. CÁC HÀM DEPLOY RIÊNG BIỆT
# ==============================================================================

function Deploy-Azure {
    if (-not (Build-Hugo $Azure_BaseURL)) { return }
    Write-Host "[AZURE] Dang upload..." -ForegroundColor Cyan
    .\rclone.exe sync ./public $Azure_Remote --progress --transfers 32 --checksum
    Write-Host "XONG AZURE!" -ForegroundColor Green
}

function Deploy-B2 {
    if (-not (Build-Hugo $B2_BaseURL)) { return }
    Write-Host "[B2] Dang upload..." -ForegroundColor Cyan
    # B2 dùng --fast-list và --delete-excluded
    .\rclone.exe sync ./public $B2_Remote --progress --transfers 32 --checksum --fast-list --delete-excluded
    Write-Host "XONG BACKBLAZE B2!" -ForegroundColor Green
}

function Deploy-Bitbucket {
    Write-Host "[BITBUCKET] Bat dau quy trinh Git..." -ForegroundColor Cyan
    # Bitbucket logic khác biệt: Build xong init git luôn
    if (-not (Build-Hugo $BB_BaseURL)) { return }
    
    Push-Location .\public
    try {
        git init
        git branch -m master 
        git remote add origin $BB_RepoURL 2>$null # Bỏ qua lỗi nếu remote đã tồn tại
        git add .
        git commit -m "Deploy update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        git push -u origin master --force
    }
    finally {
        Pop-Location
    }
    Write-Host "XONG BITBUCKET!" -ForegroundColor Green
}

function Deploy-GCS {
    # Check ACL config riêng cho GCS
    $configDump = .\rclone.exe config show $GCS_RemoteName
    if ($configDump -match "acl") {
        Write-Host "LOI GCS: Phat hien cau hinh ACL cu! Kiem tra lai rclone.conf." -ForegroundColor Red
        return
    }

    if (-not (Build-Hugo $GCS_BaseURL)) { return }
    Write-Host "[GCS] Dang upload..." -ForegroundColor Cyan
    # GCS cần set header Cache-Control
    .\rclone.exe sync .\public "$GCS_RemoteName`:$GCS_BucketName" --progress --transfers 32 --checksum --header "Cache-Control: public, max-age=3600"
    Write-Host "XONG GCS!" -ForegroundColor Green
}

function Deploy-Geocities {
    if (-not (Build-Hugo $Geo_BaseURL)) { return }
    Write-Host "[GEOCITIES] Dang upload (FTP Optimized)..." -ForegroundColor Cyan
    # Geocities dùng size-only và giảm transfers để tránh lỗi FTP 530
    .\rclone.exe sync ./public $Geo_Remote --progress --transfers 3 --checkers 4 --size-only --timeout 30s
    Write-Host "XONG GEOCITIES!" -ForegroundColor Green
}

function Deploy-S3 {
    if (-not (Build-Hugo $AWS_BaseURL)) { return }
    Write-Host "[AWS S3] Dang upload..." -ForegroundColor Cyan
    .\rclone.exe sync ./public $AWS_Remote --progress --transfers 32 --checksum
    Write-Host "XONG AWS S3!" -ForegroundColor Green
}

function Deploy-Scaleway {
    if (-not (Build-Hugo $SCW_BaseURL)) { return }
    Write-Host "[SCALEWAY] Dang upload..." -ForegroundColor Cyan
    .\rclone.exe sync ./public $SCW_Remote --progress --transfers 32 --checksum
    Write-Host "XONG SCALEWAY!" -ForegroundColor Green
}

function Deploy-R2 {
    if (-not (Build-Hugo $R2_BaseURL)) { return }
    Write-Host "[CLOUDFLARE R2] Dang upload..." -ForegroundColor Cyan
    
    # R2 hỗ trợ checksum rất tốt, upload cực nhanh
    .\rclone.exe sync ./public $R2_Remote --progress --transfers 32 --checksum

    Write-Host "XONG CLOUDFLARE R2!" -ForegroundColor Green
}
# ==============================================================================
# 4. MENU CHÍNH
# ==============================================================================

Clear-Host
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "   HUGO MULTI-DEPLOYMENT TOOL v2.0" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "1. Deploy Azure"
Write-Host "2. Deploy Backblaze B2"
Write-Host "3. Deploy Bitbucket (Git)"
Write-Host "4. Deploy Google Cloud (GCS)"
Write-Host "5. Deploy Geocities (FTP)"
Write-Host "6. Deploy AWS S3"
Write-Host "7. Deploy Scaleway"
Write-Host "8. Deploy Cloudflare R2"
Write-Host "------------------------------------------"
Write-Host "A. DEPLOY ALL (Chay tat ca 1-7)" -ForegroundColor Magenta
Write-Host "Q. Thoat"
Write-Host "==========================================" -ForegroundColor Yellow

$choice = Read-Host "Nhap lua chon cua ban (VD: 1, A)"

switch ($choice) {
    "1" { Deploy-Azure }
    "2" { Deploy-B2 }
    "3" { Deploy-Bitbucket }
    "4" { Deploy-GCS }
    "5" { Deploy-Geocities }
    "6" { Deploy-S3 }
    "7" { Deploy-Scaleway }
    "8" { Deploy-R2 }
    "A" { 
        # Chạy lần lượt tất cả
        Deploy-Azure
        Deploy-B2
        Deploy-Bitbucket
        Deploy-GCS
        Deploy-Geocities
        Deploy-S3
        Deploy-Scaleway
        Deploy-R2
        Write-Host "`n--- DA CHAY XONG TOAN BO ---" -ForegroundColor Magenta
    }
    "a" { 
        # Xử lý trường hợp nhập chữ thường
        Deploy-Azure
        Deploy-B2
        Deploy-Bitbucket
        Deploy-GCS
        Deploy-Geocities
        Deploy-S3
        Deploy-Scaleway
        Write-Host "`n--- DA CHAY XONG TOAN BO ---" -ForegroundColor Magenta
    }
    "Q" { exit }
    "q" { exit }
    Default { Write-Host "Lua chon khong hop le!" -ForegroundColor Red }
}

Write-Host "`nBam phim bat ky de thoat..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")