FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY app.py .

# Run the application as anon-root user for security best practices
RUN useradd -m appuser && chown -R appuser /app
USER appuser

CMD ["python", "app.py"]