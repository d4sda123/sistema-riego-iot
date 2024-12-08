FROM python:3.12-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y python3-dev default-libmysqlclient-dev build-essential pkg-config

WORKDIR /flask

COPY requirements.txt /flask/

RUN pip3 install --upgrade pip && pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["python", "app.py"]