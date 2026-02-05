FROM python:3.12.12-alpine
WORKDIR /app
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/python /app/
EXPOSE 8080
CMD ["python3.12", "service.py"]