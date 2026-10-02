# v1: 가장 단순한 형태. 큰 베이스 이미지 + 전체 복사 + 전체 설치(dev 포함)
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
