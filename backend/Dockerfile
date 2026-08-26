FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app_sqlite.py .
COPY templates/ ./templates/

EXPOSE 6001

CMD ["python", "app_sqlite.py"]
