CRYSTAL_BIN ?= $(shell which crystal)
PREFIX ?= /usr/local
SHARD_BIN ?= ../../bin

build:
	$(CRYSTAL_BIN) build --no-debug -o bin/neph src/bin/neph_bin.cr $(CRFLAGS)
clean:
	rm -f ./bin/neph
install: build
	mkdir -p $(PREFIX)/bin
	cp ./bin/neph $(PREFIX)/bin
bin: build
	mkdir -p $(SHARD_BIN)
	cp ./bin/neph $(SHARD_BIN)
test: build
	$(CRYSTAL_BIN) spec
	./bin/neph
man: build
	./bin/neph man
