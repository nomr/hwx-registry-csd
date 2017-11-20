TAG:=$(shell git describe --tags | sed -e 's/^v//')
TAG_DIST=$(shell echo $(TAG) | sed -r -e 's/.*-([[:digit:]]+)-g.*/\1/')
TAG_HASH=$(shell echo $(TAG) | sed -r -e 's/^.*(g[0-9a-f]+|$$)/\1/')
PKG_NAME=NIFI-TLS
PKG_VERSION=$(shell echo $(TAG) | sed -r -e 's/\+nifi.*//')
CDH_SERVICE=nifi-tls

ifeq ($(TRAVIS), true)
  VERSION=$(TAG)
else
  VERSION=0.1.0
endif

.INTERMEDIATE: %-SHA256
.DELETE_ON_ERROR:
.PHONY: release install .cookie $(PKG_NAME)-$(VERSION).jar

all: info clean install

info:
	@echo '       Git Tag: $(TAG)'
	@[ ! -z $(TAG) ]
	@echo '      Tag dist: $(TAG_DIST)'
	@echo '      Tag hash: $(TAG_HASH)'
	@echo '  NiFi version: $(PKG_VERSION)'
	@echo '   CSD version: $(VERSION)'

clean:
	rm -rf release $(PKG_NAME)-*

release: $(PKG_NAME)-$(VERSION).jar
	([ -d /opt/cloudera/csd ] && rm -rf /opt/cloudera/csd/$(PKG_NAME)-*.jar && cp $< /opt/cloudera/csd) || true

install: $(PKG_NAME)-0.1.0.jar .cookie
	cp $< /opt/cloudera/csd
	chown cloudera-scm:cloudera-scm /opt/cloudera/csd/$<
	curl -b .cookie -s http://localhost:7180/cmf/csd/refresh | jq
	curl -b .cookie -s -X POST http://localhost:7180/api/v17/clusters/zeus/services/$(CDH_SERVICE)/commands/stop | jq || true
	curl -b .cookie -s 'http://localhost:7180/cmf/csd/uninstall?csdName=$(PKG_NAME)-0.1.0&force=true' | jq || true
	curl -b .cookie -s http://localhost:7180/cmf/csd/install?csdName=$(PKG_NAME)-0.1.0 | jq
	curl -b .cookie -s -X POST http://localhost:7180/api/v17/clusters/zeus/services/$(CDH_SERVICE)/commands/start | jq || true

uninstall:
	curl -s http://localhost:7180/cmf/csd/uninstall?csdName=$(PKG_NAME)-0.1.0 -b .cookie  | jq

.cookie:
	curl -s http://localhost:7180/cmf/login/j_spring_security_check -c .cookie -d "j_username=$(CM_USR)&j_password=$(CM_PSW)"

csd: csd/descriptor/service.sdl

$(PKG_NAME)-$(VERSION): csd $(PKG_NAME)-$(VERSION)/images/icon.png validator.jar
	rsync --exclude '*.swp' -a  $</ $@/
	cat $</descriptor/service.sdl | jq ".version=\"$(subst $(PKG_NAME)-,,$@)\"" > $@/descriptor/service.sdl

$(PKG_NAME)-$(VERSION).jar: $(PKG_NAME)-$(VERSION)
	jar cvf $@ -C $< .

$(PKG_NAME)-$(VERSION)/images/icon.png:
	@mkdir -p $(shell dirname $@)
	@rm -f tls-https.png
	wget https://www.webwatchdog.io/wp-content/uploads/2016/12/tls-https.png
	convert -resize 16x16 tls-https.png $@




# Remote dependencies
validator.jar:
	cd tools/cm_ext && mvn -q install && cd -
	ln tools/cm_ext/validator/target/validator.jar .

nifi-$(PKG_VERSION)-bin.tar.gz: nifi-$(PKG_VERSION)-bin.tar.gz-SHA256
	wget 'https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=nifi/$(PKG_VERSION)/$@' -O $@
	touch $@
	sha256sum -c $<


# Implicit rules
%-SHA256: SHA256SUMS
	grep $(subst -SHA256,,$@) SHA256SUMS > $@

%.sdl: %.yaml
	python yaml2json.py $< $@
	java -jar validator.jar -s $@
