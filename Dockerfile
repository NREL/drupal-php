ARG BUILD_APP_NAME
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

FROM wodby/php:7.1
ARG BUILD_APP_NAME
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

RUN echo "Building php image containing the Drupal app: $BUILD_APP_NAME"

ENV DRUSH_LAUNCHER_VER="0.6.0" \
    DRUPAL_CONSOLE_LAUNCHER_VER="1.8.0" \
    DRUSH_LAUNCHER_FALLBACK="/home/wodby/.composer/vendor/bin/drush" \
    \
    PHP_REALPATH_CACHE_TTL="3600" \
    PHP_OUTPUT_BUFFERING="16384" \

    DRUSH_PATCHFILE_URL="https://bitbucket.org/davereid/drush-patchfile.git" \

    DOCROOT_SUBDIR="web" \
    env_var_name=$buildtime_variable \
    APP_NAME=${BUILD_APP_NAME} \
    PHP_EXPOSE="Off" \
    PHP_DISPLAY_STARTUP_ERRORS="Off" \
    PHP_DISPLAY_ERRORS="Off" \
    PHP_ERROR_REPORTING="Off" \
    AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \ 
    AWS_DEFAULT_REGION="us-west-2" \
    AWS_DEFAULT_OUTPUT=json

USER root

RUN set -ex; \
    \
    su-exec wodby composer global require drush/drush:^8.0; \
    \
    # Drush launcher
    drush_launcher_url="https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VER}/drush.phar"; \
    wget -O drush.phar "${drush_launcher_url}"; \
    chmod +x drush.phar; \
    mv drush.phar /usr/local/bin/drush; \
    \
    # Drush extensions
    su-exec wodby mkdir -p /home/wodby/.drush; \
    drush_patchfile_url="https://bitbucket.org/davereid/drush-patchfile.git"; \
    su-exec wodby git clone "${drush_patchfile_url}" /home/wodby/.drush/drush-patchfile; \
    drush_rr_url="https://ftp.drupal.org/files/projects/registry_rebuild-7.x-2.5.tar.gz"; \
    wget -qO- "${drush_rr_url}" | su-exec wodby tar zx -C /home/wodby/.drush; \
    \
    # Drupal console
    console_url="https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VER}/drupal.phar"; \
    curl "${console_url}" -L -o drupal.phar; \
    mv drupal.phar /usr/local/bin/drupal; \
    chmod +x /usr/local/bin/drupal; \
    \
    mv /usr/local/bin/actions.mk /usr/local/bin/php.mk && \
    mkdir /usr/src/drupal && \
    chown www-data:www-data /usr/src/drupal && \
    apk add --update git openssh-client && \
    apk add --no-cache \
            groff \
            py-pip \
            make && \
    # Install python tools
    pip install --no-cache-dir \
    awscli && \
    aws s3 cp s3://drupal-configuration/.ssh/id_rsa /tmp/id_rsa && \
    chmod 600 /tmp/id_rsa && \
    eval $(ssh-agent) && \
    echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    ssh-add /tmp/id_rsa && \
    git clone git@github.com:NREL/${BUILD_APP_NAME}.git -b master --single-branch --recursive /usr/src/drupal && \
    su-exec www-data composer clear-cache && \
    apk del git openssh-client && \
    rm /tmp/id_rsa && \
    # Change overridden target name to avoid warnings.
    sed -i 's/git-checkout:/php-git-checkout:/' /usr/local/bin/php.mk; \
    \
    mkdir -p "${FILES_DIR}/config"; \
    chown www-data:www-data "${FILES_DIR}/config"; \
    chmod 775 "${FILES_DIR}/config"; \
    \
    # Clean up
    su-exec wodby composer clear-cache; \
    su-exec wodby drush cc drush

USER wodby

COPY templates /etc/gotpl/
COPY bin /usr/local/bin
COPY init /docker-entrypoint-init.d/
COPY actions /usr/local/bin

# This line need to be there in AWS.
VOLUME ["/var/www/html"]
