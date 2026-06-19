FROM python:3.8.3-slim-buster
RUN python -m pip install --upgrade pip
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "app:app"]
