docker:
	docker build -t newbieshine/gift-registry:2.4.1 . --platform linux/amd64
	docker build -f Dockerfile.elf -t newbieshine/elf:1.7.0 . --platform linux/amd64
	docker push newbieshine/gift-registry:2.4.1
	docker push newbieshine/elf:1.7.0
