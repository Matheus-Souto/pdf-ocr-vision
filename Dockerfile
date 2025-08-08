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

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create upload directory
RUN mkdir -p temp_uploads

# Expose port
EXPOSE 8000

# Default command - but can be overridden for setup
CMD ["python", "main.py"] 