IMAGENAME := $(shell basename `git rev-parse --show-toplevel`)
SHA := $(shell git rev-parse --short HEAD)
targz_file := $(shell cat FILEPATH)
timestamp := $(shell date +"%Y%m%d%H%M")
VERSION :=$(shell cat VERSION)
NAMESPACE=grembold
#REGISTRY_URL=hub.docker.com

default: download dockerbuild push

loadS3_and_extract:
	aws s3 cp s3://$(AWS_BUCKET)/$(targz_file) >./binary.tar.gz
	mkdir contents/
	tar xzf binary.tar.gz -C content/
	ls -la content/

download:
	if [ -d "content" ]; then rm -r content; fi
	curl -L https://github.com/gohugoio/hugo/releases/download/v$(VERSION)/hugo_$(VERSION)_Linux-ARM.tar.gz > ./binary.tar.gz
	mkdir content/
	tar xzf binary.tar.gz -C content/
	cd content
# mv hugo*/hugo* ./hugo
	ls -la content/

dockerbuild:
	docker rmi -f $(NAMESPACE)/$(IMAGENAME):$(VERSION)_bak || true
	docker tag $(NAMESPACE)/$(IMAGENAME) $(NAMESPACE)/$(IMAGENAME):$(VERSION)_bak || true
	docker rmi -f $(NAMESPACE)/$(IMAGENAME):$(VERSION) || true
	docker build -t $(NAMESPACE)/$(IMAGENAME):$(VERSION) .

testimg:
	docker rm -f new-$(IMAGENAME) || true
	docker run -d --name new-$(IMAGENAME) $(NAMESPACE)/$(IMAGENAME):latest
	docker inspect -f '{{.NetworkSettings.IPAddress}}' new-$(IMAGENAME)
	docker logs -f new-$(IMAGENAME)

push:
	# push VERSION
	docker tag $(NAMESPACE)/$(IMAGENAME):latest $(NAMESPACE)/$(IMAGENAME):$(VERSION)
	docker push $(NAMESPACE)/$(IMAGENAME):$(VERSION)
	docker rmi $(NAMESPACE)/$(IMAGENAME):$(VERSION) || true
	# push commit SHA
	docker tag $(NAMESPACE)/$(IMAGENAME):latest $(NAMESPACE)/$(IMAGENAME):$(SHA)
	docker push $(NAMESPACE)/$(IMAGENAME):$(SHA)
	docker rmi $(NAMESPACE)/$(IMAGENAME):$(SHA) || true
	# push timestamp
	docker tag $(NAMESPACE)/$(IMAGENAME):latest $(NAMESPACE)/$(IMAGENAME):$(timestamp)
	docker push $(NAMESPACE)/$(IMAGENAME):$(timestamp)
	docker rmi $(NAMESPACE)/$(IMAGENAME):$(timestamp) || true
	# push latest
	docker tag $(NAMESPACE)/$(IMAGENAME):latest $(NAMESPACE)/$(IMAGENAME):latest
	docker push $(NAMESPACE)/$(IMAGENAME):latest
	docker rmi $(NAMESPACE)/$(IMAGENAME):latest || true
                        	
