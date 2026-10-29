# Estágio 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copia tudo primeiro para garantir o contexto do módulo
COPY . .

# Garante a resolução e integridade das dependências
RUN go mod tidy && go mod download

# Compila o binário estático
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o auth-service .

# Estágio 2: Execução
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/auth-service .

EXPOSE 8001

CMD ["./auth-service"]