FROM nginx:1.24.0-alpine
WORKDIR /app
COPY nginx-service.conf /etc/nginx/conf.d/default.conf
RUN apk add --no-cache shadow \
    && usermod -u 1001 nginx \
    && chown -R nginx:nginx /app \
    && chmod -R 755 /app \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid
USER nginx
EXPOSE 8000
