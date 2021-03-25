UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	OS:= darwin
endif
ifeq ($(UNAME_S),Linux)
	OS:= linux
endif
UNAME_M:= $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
	ARCH:= amd64
endif

VERSION:= $(shell cat VERSION)
SW:= feron
TARGET:= src/$(SW)
RELEASE_DIR:= ./releases
OUTPUT:= $(RELEASE_DIR)/$(SW)-$(VERSION)-$(OS)-$(ARCH)

.PHONY: all clean version help

help: ## Show this help
	@echo
	@printf '\033[34mtargets:\033[0m\n'
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
		sort |\
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

all: clean releases ## Build everything

releases: version $(TARGET) pack docker ## Build releases
	docker run --rm -v ${PWD}/releases:/app --entrypoint "sh" $(SW):$(VERSION) -c "cp /usr/local/bin/$(SW) /app/$(SW)-$(VERSION)-linux-amd64"

docker: ## Build docker image
	docker build -t $(SW):$(VERSION) .
	docker tag $(SW):$(VERSION) $(SW):latest

clean: ## Clean build directories and files
	@rm -f $(RELEASE_DIR)/*
	@echo >&2 "cleaned up"

version: ## Replace version in code with content of VERSION
	@sed -i "" 's/^version:.*/version: $(VERSION)/g' shard.yml
	@sed -i "" 's/^VERSION.*/VERSION = "$(VERSION)"/g' $(TARGET).cr
	@echo "Version set to $(VERSION)"

$(TARGET): % : $(filter-out $(TEMPS), $(OBJ)) %.cr
	@crystal build src/$(SW).cr -o $(OUTPUT) --progress
	@find $(RELEASE_DIR) -name "*.dwarf" -delete
	@echo "compiled binaries places to \"./releases\" directory"

pack:
	@find $(RELEASE_DIR) -type f -name "$(SW)-$(VERSION)-$(OS)-$(ARCH)" | xargs upx
