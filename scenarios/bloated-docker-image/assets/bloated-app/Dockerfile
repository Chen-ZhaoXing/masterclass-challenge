# The rogue elves built this image as fast as possible.
# It works, but it breaks almost every North Pole Container Standard!
FROM python:3.13

# We copy everything at once because it's easier!
COPY . /app
WORKDIR /app

# Install everything into the main system
RUN pip install -r requirements.txt

# Start the application
EXPOSE 8000
CMD ["fastapi", "run", "src/app.py", "--host", "0.0.0.0", "--port", "8000"]