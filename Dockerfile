# ---- build Flutter web ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter config --enable-web \
 && flutter build web --release

# ---- serve with nginx on $PORT ----
FROM nginx:alpine
# replace default config to listen on 8080 (Cloud Run)
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
