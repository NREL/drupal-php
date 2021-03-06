-include /usr/local/bin/php.mk
-include /usr/local/bin/drupal-php.mk

.PHONY: init cache-clear cache-rebuild

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Required parameter is missing: $1$(if $2, ($2))))

is_hash ?= 0
target ?= all

ifeq ("$(DOCROOT_SUBDIR)", "")
	DRUPAL_ROOT=$(APP_ROOT)
else
	DRUPAL_ROOT=$(APP_ROOT)/$(DOCROOT_SUBDIR)
endif

DRUPAL_SITE_DIR=$(DRUPAL_ROOT)/sites/$(DRUPAL_SITE)

default: cache-clear

git-checkout:
	$(call check_defined, target)
	chmod 755 $(DRUPAL_SITE_DIR) || true
	git-checkout.sh $(target) $(is_hash)

cache-clear:
	drush -r $(DRUPAL_ROOT) cache-clear $(target)

cache-rebuild:
	drush -r $(DRUPAL_ROOT) cache-rebuild
init:
	DRUPAL_ROOT=$(DRUPAL_ROOT) init.sh
