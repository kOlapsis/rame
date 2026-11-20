FROM nginx:1.27-alpine
ARG VERSION=dev
LABEL org.opencontainers.image.title="Balade à la rame" \
      org.opencontainers.image.version="${VERSION}"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html three.module.min.js Water.js Sky.js /usr/share/nginx/html/
RUN sed -i "s/__VERSION__/${VERSION}/g" /usr/share/nginx/html/index.html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
