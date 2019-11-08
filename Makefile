IMAGE_REPO := "docker.pantheon.tech"

pantheon-dev-image:
	docker build --tag="${IMAGE_REPO}/ydk-dev" -f pantheon/dev.Dockerfile .

pantheon-prod-image:
	docker build --tag="${IMAGE_REPO}/ydk" -f pantheon/prod.Dockerfile .
