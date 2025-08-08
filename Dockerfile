# Use Python 3.12 slim image
FROM python:3.12-slim

# Install system dependencies including Poppler and Google Cloud CLI
RUN apt-get update && apt-get install -y \
    poppler-utils \
    curl \
    gnupg \
    lsb-release \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create directories
RUN mkdir -p temp_uploads \
    && mkdir -p /app/gcloud-config

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Copy startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 8000

# Use custom entrypoint that configures gcloud
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "main.py"] 