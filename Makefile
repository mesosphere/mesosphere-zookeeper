NAME      ?= mesosphere-zookeeper
SHELL     := /bin/bash
EMPTY     :=
SPACE     := $(EMPTY) $(EMPTY)
PKG_VER   ?= 3.4.6
REL_MAJOR ?= 0
REL_MINOR ?= 1
REL_PATCH ?= $(shell date -u +'%Y%m%d%H%M%S')
ITEMS     := $(REL_MAJOR) $(REL_MINOR) $(REL_PATCH)
PKG_REL   := $(subst $(SPACE),.,$(strip $(ITEMS)))
ZK_URL    ?= http://mirror.cogentco.com/pub/apache/zookeeper/stable/zookeeper-$(PKG_VER).tar.gz 
SRC_TGZ    = $(notdir $(ZK_URL))
CONTENTS  := opt/mesosphere/zookeeper/bin opt/mesosphere/zookeeper/lib \
	opt/mesosphere/zookeeper/zookeeper-$(PKG_VER).jar usr etc

TOP       := $(CURDIR)
CACHE      = $(TOP)/tmp/cache
TOOR       = $(TOP)/tmp/toor
PKG        = $(TOP)/pkg

.PHONY: help
help:
	@echo "To build snapshot packages"
	@echo "  make all"
	@echo "  => pkg/mesosphere-zookeeper-3.4.6-0.1.20141128174217.centos7.x86_64.rpm"
	@echo "To make a release build:"
	@echo "  make REL_MAJOR=1 REL_MINOR=0 REL_PATCH=0 all"
	@echo "  => pkg/mesosphere-zookeeper-3.4.6-1.0.0.centos7.x86_64.rpm"
	@exit 0

FPM_OPTS := -t rpm -s dir -n $(NAME) -v $(PKG_VER) \
	-d 'java >= 1.6' \
	--conflicts zookeeper \
	--conflicts zookeeper-server \
	--architecture native \
	--url "http://www.mesosphere.com" \
	--license Apache-2.0 \
	--description "High-performance coordination service for distributed applications" \
	--maintainer "Mesosphere Package Builder <support@mesosphere.io>" \
	--vendor "Mesosphere, Inc."

$(CACHE):
	mkdir -p $(CACHE)

$(TOOR):
	mkdir -p $(TOOR)

$(PKG):
	mkdir -p $(PKG)

fetch: $(CACHE)
	cd $(CACHE); wget -N $(ZK_URL)

extract: fetch $(TOOR)
	mkdir -p "$(TOOR)"/opt/mesosphere/zookeeper
	cd "$(TOOR)"/opt/mesosphere/zookeeper && tar xzf "$(CACHE)/$(SRC_TGZ)" --strip=1

clean:
	rm -rf tmp

distclean: clean
	rm -rf $(PKG)

.PHONY: all
all: centos7

.PHONY: centos7
centos7: extract $(PKG)
centos7: $(TOOR)/usr/lib/systemd/system/$(NAME).service
centos7: $(TOOR)/etc/zookeeper/conf/zoo.cfg
	cd $(PKG) && fpm -C $(TOOR) \
		--config-files etc \
		--after-install $(TOP)/postinst --iteration $(PKG_REL).centos7 \
		$(FPM_OPTS) $(CONTENTS)

$(TOOR)/etc/zookeeper/conf/zoo.cfg: zoo.cfg extract $(TOOR)
	mkdir -p $(TOOR)/etc/zookeeper/conf
	cp -rp $(TOOR)/opt/mesosphere/zookeeper/conf/* $(TOOR)/etc/zookeeper/conf/
	cp zoo.cfg "$@"

$(TOOR)/usr/lib/systemd/system/$(NAME).service: zookeeper.service
	mkdir -p "$(dir $@)"
	cp zookeeper.service "$@"

.PHONY: prep-ubuntu
prep-ubuntu:
	sudo apt-get -y install ruby-dev rpm
	sudo gem install fpm
