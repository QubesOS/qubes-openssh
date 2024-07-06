.DEFAULT_GOAL = get-sources
.SECONDEXPANSION:

DIST ?= fc37
VERSION := $(shell cat version)p1

FEDORA_SOURCES := https://src.fedoraproject.org/rpms/openssh/raw/f$(subst fc,,$(DIST))/f/sources
SRC_FILES := \
            openssh-$(VERSION).tar.gz \
            openssh-$(VERSION).tar.gz.asc \
            pam_ssh_agent_auth-0.10.4.tar.gz \


BUILDER_DIR ?= ../..
SRC_DIR ?= qubes-src

URLS := \
            https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$(VERSION).tar.gz.asc \
            https://github.com/jbeverly/pam_ssh_agent_auth/archive/pam_ssh_agent_auth-0.10.4.tar.gz \

ALL_FILES := $(notdir $(URLS:%.asc=%)) $(notdir $(filter %.asc, $(URLS)))
ALL_URLS := $(URLS:%.asc=%) $(filter %.asc, $(URLS))

UNTRUSTED_SUFF := .UNTRUSTED

SHELL := bash

.PHONY: get-sources verify-sources clean clean-sources

keyring-file := gpgkey-736060BA.gpg

ifeq ($(FETCH_CMD),)
$(error "You can not run this Makefile without having FETCH_CMD defined")
endif

%: %.sha512
	@$(FETCH_CMD) $@$(UNTRUSTED_SUFF) -- $(filter %/$@,$(URLS))
	@sha512sum --status -c <(printf "$$(cat $<)  -\n") <$@$(UNTRUSTED_SUFF) || \
		{ echo "Wrong SHA512 checksum on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

$(filter %.asc, $(ALL_FILES)): %:
	@$(FETCH_CMD) $@ $(filter %$@,$(ALL_URLS))

%: %.asc $(keyring-file)
	@$(FETCH_CMD) $@$(UNTRUSTED_SUFF) $(filter %$@,$(ALL_URLS))
	@gpgv --keyring ./$(keyring-file) $< $@$(UNTRUSTED_SUFF) 2>/dev/null || \
		{ echo "Wrong signature on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

get-sources: $(ALL_FILES)
	@true

verify-sources:
	@true

clean:
	@true

clean-sources:
	rm -f $(ALL_FILES) *$(UNTRUSTED_SUFF)

# This target is generating content locally from upstream project
# # 'sources' file. Sanitization is done but it is encouraged to perform
# # update of component in non-sensitive environnements to prevent
# # any possible local destructions due to shell rendering
# .PHONY: update-sources
update-sources:
	@$(BUILDER_DIR)/$(SRC_DIR)/builder-rpm/scripts/generate-hashes-from-sources $(FEDORA_SOURCES)
