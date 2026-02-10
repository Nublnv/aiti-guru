# SERVICE
FROM python:3.12.12-alpine AS service
WORKDIR /app
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/python /app/python
COPY src/conf /app/conf
EXPOSE 8080
CMD ["python3.12", "python/service.py"]

# DATABASE
FROM postgres AS postgres
COPY db/01_init.sql /docker-entrypoint-initdb.d
