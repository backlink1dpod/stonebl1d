# 1. Sử dụng Node.js làm nền tảng chính (để chắc chắn có npm)
FROM node:20-slim

# 2. Cài đặt các công cụ cần thiết: Git, Go và Hugo
RUN apt-get update && apt-get install -y \
    git \
    golang-go \
    wget \
    ca-certificates

# 3. Tải và cài đặt Hugo Extended (Phiên bản mới)
ARG HUGO_VERSION=0.121.2
RUN wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
    && dpkg -i hugo.deb \
    && rm hugo.deb

# 4. Thiết lập thư mục làm việc
WORKDIR /app

# 5. Copy toàn bộ code vào
COPY . .

# 6. Cài đặt dependency và Build
# Lệnh này sẽ chạy npm install và sau đó chạy lệnh build của bạn
RUN npm install
RUN npm run build

# 7. Cài đặt một server siêu nhẹ để chạy web (vì Docker cần một process chạy liên tục)
RUN npm install -g serve

# 8. Mở cổng 80 và chạy web từ thư mục public
ENV PORT=80
EXPOSE 80
CMD ["serve", "-s", "public", "-l", "80"]