# Stage 1 — run tests
FROM node:22-alpine AS test
WORKDIR /app
COPY package.json ./
RUN npm install
COPY js/ ./js/
COPY tests/ ./tests/
RUN npm test

# Stage 2 — serve static files
FROM nginx:alpine AS serve
COPY --from=test /app /dev/null
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/
COPY js/ /usr/share/nginx/html/js/
