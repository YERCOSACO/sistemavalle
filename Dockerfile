FROM dart:3.7.2

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .
RUN dart pub get --offline

ENV HOST=0.0.0.0
ENV MOBILE_UPLOAD_DIRECTORY=/var/data/mobile-comprobantes

EXPOSE 8080

CMD ["dart", "run", "bin/server.dart"]
