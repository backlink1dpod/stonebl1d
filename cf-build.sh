#!/bin/bash

# 1. CẤU HÌNH PHIÊN BẢN (Go 1.25 chưa ra, dùng bản mới nhất ổn định)
GO_VERSION='1.21.6'
HUGO_VERSION='0.120.4' # Bản này ổn định nhất với theme Hugoplate

echo "Node Version: $(node -v)"

# Tạo thư mục bin cục bộ (Cloudflare không cho ghi vào /usr/local/bin)
mkdir -p bin
mkdir -p go_install

# 2. CÀI ĐẶT GO (Vào thư mục local)
echo "Installing Go $GO_VERSION..."
curl -sSOL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
# Giải nén vào thư mục cục bộ
tar -C go_install -xzf go${GO_VERSION}.linux-amd64.tar.gz
# Cập nhật đường dẫn PATH để máy nhận lệnh go mới
export PATH=$PWD/go_install/go/bin:$PATH
rm -rf go${GO_VERSION}.linux-amd64.tar.gz
go version

# 3. CÀI ĐẶT HUGO EXTENDED (Vào thư mục local)
echo "Installing Hugo $HUGO_VERSION..."
curl -sSOL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz
# Giải nén binary hugo vào thư mục bin
tar -xzf hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz -C bin/ hugo
# Cập nhật đường dẫn PATH để máy nhận lệnh hugo mới
export PATH=$PWD/bin:$PATH
rm -rf hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz
hugo version

# 4. CÀI ĐẶT THƯ VIỆN (TailwindCSS)
echo "Installing dependencies..."
npm install

# --- QUAN TRỌNG: ĐÃ XÓA 'npm run project-setup' ĐỂ KHÔNG MẤT BÀI VIẾT ---

# 5. CHẠY SCRIPT THEME (Bắt buộc với Hugoplate)
echo "Generating Theme CSS..."
node scripts/themeGenerator.js

# 6. BUILD WEBSITE
echo "Building Site..."

# Tự động lấy Link của Cloudflare (Preview hoặc Production)
# CF_PAGES_URL là biến môi trường có sẵn của Cloudflare
if [ -z "$CF_PAGES_URL" ]; then
  BASE_URL="/" # Fallback nếu chạy local
else
  BASE_URL="$CF_PAGES_URL/"
fi

echo "BaseURL is: $BASE_URL"

hugo --gc --minify --baseURL "$BASE_URL"