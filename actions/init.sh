#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [[ ! -e "${DRUPAL_ROOT}/index.php" ]]; then
    echo >&2 "${APP_NAME} not found in ${APP_ROOT} - copying now..."
    rsync -rlt "/usr/src/drupal/" "${APP_ROOT}/"
    echo >&2 "Complete! ${APP_NAME} has been successfully copied to ${APP_ROOT}"
fi

if [[ ! -e "${DRUPAL_ROOT}/sites/default/settings.local.php" ]]; then
    echo >&2 "settings.local.php not found in ${DRUPAL_ROOT} - symlinking now..."
    ln -f -s ../../../../common/settings.local.php ${DRUPAL_ROOT}/sites/default/settings.local.php && \
    echo >&2 "Complete! settings.local.php has been successfully symlinked"
fi

if [[ ! -e "${DRUPAL_ROOT}/sites/default/files" ]]; then
    echo >&2 "sites/default/files not found in ${DRUPAL_ROOT} - symlinking now..."
    ln -f -s ../../../../common/files ${DRUPAL_ROOT}/sites/default/files && \
    echo >&2 "Complete! sites/default/files has been successfully symlinked"
fi

if [[ ! -e "${DRUPAL_ROOT}/sites/default/local.services.yml" ]]; then
    echo >&2 "sites/default/local.services.yml not found in ${DRUPAL_ROOT} - symlinking now..."
    ln -f -s ../../../../common/local.services.yml ${DRUPAL_ROOT}/sites/default/local.services.yml && \
        echo >&2 "Complete! sites/default/local.services.yml has been successfully symlinked"
fi

