FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && pip install --no-cache-dir "werkzeug<3.0"

COPY . .

EXPOSE 8005

CMD ["gunicorn", "--bind", "0.0.0.0:8005", "app:app"]