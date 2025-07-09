FROM python:3.12.10

WORKDIR /app

ARG src="Certificate Name.crt"
ARG target="/usr/local/share/ca-certificates/Certificate Name.crt"
COPY $(src) $(target)
RUN update-ca-certificates
RUN apt-get install -y \
  gcc \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/.
RUN pip install --no-cache-dir -r /tmp/requirements.txt
COPY . .
CMD ["python", "app.py"]
