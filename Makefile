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

.PHONY: all clean version

all: clean releases

releases: version $(TARGET) pack docker
	docker run -it --rm -v ${PWD}/releases:/app --entrypoint "sh" $(SW):$(VERSION) -c "cp /$(SW) /app/$(SW)-$(VERSION)-linux-amd64"

docker:
	docker build -t $(SW):$(VERSION) .
	docker tag $(SW):$(VERSION) $(SW):latest

clean:
	@rm -f $(RELEASE_DIR)/*
	@echo >&2 "cleaned up"

version:
	@sed -i "" 's/^VERSION.*/VERSION="$(VERSION)"/g' $(TARGET).cr
	@echo "Version set to $(VERSION)"

$(TARGET): % : $(filter-out $(TEMPS), $(OBJ)) %.cr
	@crystal build src/$(SW).cr -o $(OUTPUT) --progress
	@find $(RELEASE_DIR) -name "*.dwarf" -delete
	@echo "compiled binaries places to \"./releases\" directory"

pack:
	@find $(RELEASE_DIR) -type f -name "$(SW)-$(VERSION)-$(OS)-$(ARCH)" | xargs upx
