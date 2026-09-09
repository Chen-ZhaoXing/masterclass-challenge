docker:
	docker build -t touching/gift-registry:2.4.1 . --platform linux/amd64
	docker build -f Dockerfile.elf -t touching/elf:1.7.0 . --platform linux/amd64
	docker push touching/gift-registry:2.4.1
	docker push touching/elf:1.7.0
