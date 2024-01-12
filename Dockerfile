FROM python:3.10
WORKDIR /app
COPY app.py .
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
ENV TC_DYNAMO_TABLE=Candidates
CMD ["python3", "app.py"]
