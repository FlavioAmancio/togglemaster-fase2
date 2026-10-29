# Estágio 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY . .

RUN go mod tidy && go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o evaluation-service .

# Estágio 2: Execução
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/evaluation-service .

EXPOSE 8004

CMD ["./evaluation-service"]