docker:
	docker build -t touching/masterclass-fastapi-app:latest .
	docker tag touching/masterclass-fastapi-app:latest touching/masterclass-app:v0.1.0
	docker push touching/masterclass-fastapi-app:latest
	docker push touching/masterclass-fastapi-app:v0.1.0

run-docker-dev:
	docker rm masterclass-app -f
	docker run -d --name masterclass-app -p 8000:8000 masterclass-fastapi-app:latest

run-docker-prod:
	docker rm masterclass-app -f
	docker run -d -e MODE=production -e APP_TOKEN_PATH=/app/token -v $(pwd)/token:/app/token --name masterclass-app -p 8000:8000 masterclass-fastapi-app:latest