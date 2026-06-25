FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# System updates aur required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Globally packages install karenge
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir hermes-agent python-telegram-bot aiohttp

WORKDIR /app
COPY . .

# Render ke port mapping ke liye default port
EXPOSE 10000

CMD ["python", "main.py"]
