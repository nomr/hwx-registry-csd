TAG:=$(shell git describe --tags | sed -e 's/^v//')
TAG_DIST=$(shell echo $(TAG) | sed -r -e 's/.*-([[:digit:]]+)-g.*/\1/')
TAG_HASH=$(shell echo $(TAG) | sed -r -e 's/^.*(g[0-9a-f]+|$$)/\1/')
NIFI_VERSION=$(shell echo $(TAG) | sed -r -e 's/\+nifi.*//')
VERSION=$(TAG)

.INTERMEDIATE: %-SHA256
.DELETE_ON_ERROR:
.PHONY: release

all: info release

info:
	@echo '       Git Tag: $(TAG)'
	@[ ! -z $(TAG) ]
	@echo '      Tag dist: $(TAG_DIST)'
	@echo '      Tag hash: $(TAG_HASH)'
	@echo '  NiFi version: $(NIFI_VERSION)'
	@echo '   CSD version: $(VERSION)'

clean:
	rm -rf release NIFI-*

release: NIFI-$(VERSION).jar


NIFI-$(VERSION): csd validator.jar NIFI-$(VERSION)/images/icon.png
	rsync -a $</ $@/
	cat $</descriptor/service.sdl | jq ".version=\"$(VERSION)\"" > $@/descriptor/service.sdl
	java -jar validator.jar -s $@/descriptor/service.sdl || (rm -rf $@ && false)

# Remote dependencies
validator.jar:
	cd tools/cm_ext && mvn -q install && cd -
	ln tools/cm_ext/validator/target/validator.jar .

nifi-$(NIFI_VERSION)-bin.tar.gz: nifi-$(NIFI_VERSION)-bin.tar.gz-SHA256
	wget 'https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=nifi/$(NIFI_VERSION)/$@' -O $@
	touch $@
	sha256sum -c $<

%/icon.ico:
	@mkdir -p $(shell dirname $@)
	wget https://nifi.apache.org/assets/images/nifi16.ico -O $@


# Implicit rules
%-SHA256: SHA256SUMS
	grep $(subst -SHA256,,$@) SHA256SUMS > $@

%.jar: %
	jar cvf $@ $<

%.png: %.ico
	convert $< $@
