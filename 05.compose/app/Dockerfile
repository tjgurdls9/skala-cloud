FROM python:3.11-alpine
WORKDIR /app
COPY webserver.py .
RUN pip install --no-cache-dir fastapi uvicorn pymysql
EXPOSE 8080
CMD ["python", "webserver.py"]
