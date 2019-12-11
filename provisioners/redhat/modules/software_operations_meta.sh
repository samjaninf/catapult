source "/catapult/provisioners/redhat/modules/catapult.sh"

# set a variable to the .cnf
dbconf="/catapult/provisioners/redhat/installers/temp/${1}.cnf"

domain=$(catapult websites.apache.$5.domain)
domain_valid_db_name=$(catapult websites.apache.$5.domain | tr "." "_" | tr "-" "_")
software=$(catapult websites.apache.$5.software)
software_auto_update=$(catapult websites.apache.$5.software_auto_update)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

softwareroot=$(provisioners software.apache.${software}.softwareroot)

# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc

# set website software site email address
# set website software admin credentials, email address, and role
if ([ ! -z "${software}" ]); then
    echo -e "* setting ${software} site email address..."
    echo -e "* setting ${software} admin account credentials, email address, and role..."
fi

if [ "${software}" = "concrete58" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}" && concrete/bin/concrete5 c5:exec /catapult/provisioners/redhat/installers/software/concrete58/password_reset.php $(catapult environments.${1}.software.admin_password) --no-interaction
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}Users (uName, uEmail, uIsActive)
        VALUES ('admin', '$(catapult company.email)', '1')
        ON DUPLICATE KEY UPDATE uName='admin', uEmail='$(catapult company.email)', uIsActive='1';
    "

elif [ "${software}" = "drupal6" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set site_mail $(catapult company.email)

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users (uid, pass, mail, status)
        VALUES ('1', MD5('$(catapult environments.${1}.software.drupal.admin_password)'), '$(catapult company.email)', '1')
        ON DUPLICATE KEY UPDATE name='admin', mail='$(catapult company.email)', pass=MD5('$(catapult environments.${1}.software.drupal.admin_password)'), status='1';
    "
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users_roles (uid, rid)
        VALUES ('1', '3')
        ON DUPLICATE KEY UPDATE rid='3';
    "

elif [ "${software}" = "drupal7" ]; then
    
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set site_mail $(catapult company.email)

    password_hash=$(cd "/var/www/repositories/apache/${domain}/${webroot}" && php ./scripts/password-hash.sh $(catapult environments.${1}.software.drupal.admin_password))
    password_hash=$(echo "${password_hash}" | awk '{ print $4 }' | tr -d " " | tr -d "\n")
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users (uid, pass, mail, status)
        VALUES ('1', '${password_hash}', '$(catapult company.email)', '1')
        ON DUPLICATE KEY UPDATE name='admin', mail='$(catapult company.email)', pass='${password_hash}', status='1';
    "
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users_roles (uid, rid)
        VALUES ('1', '3')
        ON DUPLICATE KEY UPDATE rid='3';
    "

elif [ "${software}" = "drupal8" ]; then
    
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.site mail --value="$(catapult company.email)"

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush user-create "admin" --mail="$(catapult company.email)" --password="$(catapult environments.${1}.software.drupal.admin_password)"
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush user-password 1 --password="$(catapult environments.${1}.software.drupal.admin_password)"
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush user-add-role "administrator" --uid=1

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        UPDATE users_field_data SET name='admin', mail='$(catapult company.email)', status='1' WHERE uid='1';
    "

elif [ "${software}" = "elgg1" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users_entity (username, password_hash, email, banned, admin)
        VALUES ('admin', MD5('$(catapult environments.${1}.software.admin_password)'), '$(catapult company.email)', 'no', 'yes')
        ON DUPLICATE KEY UPDATE username='admin', password_hash=MD5('$(catapult environments.${1}.software.admin_password)'), email='$(catapult company.email)', banned='no', admin='yes';
    "

elif [ "${software}" = "elgg2" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users_entity (username, password_hash, email, banned, admin)
        VALUES ('admin', MD5('$(catapult environments.${1}.software.admin_password)'), '$(catapult company.email)', 'no', 'yes')
        ON DUPLICATE KEY UPDATE username='admin', password_hash=MD5('$(catapult environments.${1}.software.admin_password)'), email='$(catapult company.email)', banned='no', admin='yes';
    "

elif [ "${software}" = "joomla3" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        UPDATE ${software_dbprefix}users
        SET username='admin', email='$(catapult company.email)', password=MD5('$(catapult environments.${1}.software.admin_password)'), block='0'
        WHERE name='Super User';
    "

elif [ "${software}" = "mediawiki1" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}user (user_id, user_name, user_email)
        VALUES ('1', 'Admin', '$(catapult company.email)')
        ON DUPLICATE KEY UPDATE user_name='Admin', user_email='$(catapult company.email)';
    "
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php maintenance/changePassword.php --userid="1" --password="$(catapult environments.${1}.software.admin_password)"
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}user_groups (ug_user, ug_group)
        VALUES ('1', 'sysop')
        ON DUPLICATE KEY UPDATE ug_user=ug_user, ug_group=ug_group;
    "

elif [ "${software}" = "moodle3" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        UPDATE ${software_dbprefix}user
        SET username='admin', password=MD5('$(catapult environments.${1}.software.admin_password)'), suspended='0', email='$(catapult company.email)'
        WHERE id='2';
    "

elif [ "${software}" = "silverstripe3" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        UPDATE ${software_dbprefix}Member
        SET FirstName='Default Admin', Email='$(catapult company.email)', Password='$(catapult environments.${1}.software.admin_password)', PasswordEncryption='none', LockedOutUntil='NULL'
        WHERE ID='1';
    "
    # a hack to encrypt the plain text password that we just set, wahoo!
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php framework/cli-script.php dev/tasks/EncryptAllPasswordsTask

elif [ "${software}" = "suitecrm7" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users (id, user_name, user_hash, is_admin)
        VALUES ('1', 'admin', MD5('$(catapult environments.${1}.software.admin_password)'), '1')
        ON DUPLICATE KEY UPDATE user_name='admin', user_hash=MD5('$(catapult environments.${1}.software.admin_password)'), is_admin='1';
    "

elif [ "${software}" = "wordpress4" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "UPDATE ${software_dbprefix}options SET option_value='$(catapult company.email)' WHERE option_name = 'admin_email';"
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users (id, user_login, user_pass, user_nicename, user_email, user_status, display_name)
        VALUES ('1', 'admin', MD5('$(catapult environments.${1}.software.wordpress.admin_password)'), 'admin', '$(catapult company.email)', '0', 'admin')
        ON DUPLICATE KEY UPDATE user_login='admin', user_pass=MD5('$(catapult environments.${1}.software.wordpress.admin_password)'), user_nicename='admin', user_email='$(catapult company.email)', user_status='0', display_name='admin';
    "
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php71 --allow-root user add-role 1 administrator

elif [ "${software}" = "wordpress5" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "UPDATE ${software_dbprefix}options SET option_value='$(catapult company.email)' WHERE option_name = 'admin_email';"
    
    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        INSERT INTO ${software_dbprefix}users (id, user_login, user_pass, user_nicename, user_email, user_status, display_name)
        VALUES ('1', 'admin', MD5('$(catapult environments.${1}.software.wordpress.admin_password)'), 'admin', '$(catapult company.email)', '0', 'admin')
        ON DUPLICATE KEY UPDATE user_login='admin', user_pass=MD5('$(catapult environments.${1}.software.wordpress.admin_password)'), user_nicename='admin', user_email='$(catapult company.email)', user_status='0', display_name='admin';
    "
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php72 --allow-root user add-role 1 administrator

elif [ "${software}" = "xenforo2" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} -e "
        UPDATE xf_user_authenticate
        SET data = BINARY
            CONCAT(
                CONCAT(
                    CONCAT('a:3:{s:4:\"hash\";s:40:\"', SHA1(CONCAT(SHA1('$(catapult environments.${1}.software.admin_password)'), SHA1('salt')))),
                    CONCAT('\";s:4:\"salt\";s:40:\"', SHA1('salt'))
                ),
                '\";s:8:\"hashFunc\";s:4:\"sha1\";}'
            ),
        scheme_class = 'XenForo_Authentication_Core'
        WHERE user_id = 1;
    "

fi


# set website performance settings
if ([ ! -z "${software}" ]); then
    echo -e "* setting ${software} performance settings..."
fi

if [ "${software}" = "concrete58" ]; then

    if [ "$1" = "dev" ]; then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.assets 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.blocks 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.enabled 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.full_page_lifeteime default --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.overrides 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.pages 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.theme_css 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.theme.compress_preprocessor_output 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.theme.generate_less_sourcemap 1 --allow-as-root
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.assets 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.blocks 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.enabled 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.full_page_lifeteime default --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.overrides 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.pages all --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.cache.theme_css 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.theme.compress_preprocessor_output 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.theme.generate_less_sourcemap 0 --allow-as-root
    fi

elif [ "${software}" = "drupal6" ]; then

    if [ "$1" = "dev" ]; then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set block_cache 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache_lifetime 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_cache_maximum_age 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_compression 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_css 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_js 0
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set block_cache 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache 2
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache_lifetime 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_cache_maximum_age 900
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_compression 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_css 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_js 1
    fi

elif [ "${software}" = "drupal7" ]; then

    if [ "$1" = "dev" ]; then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set block_cache 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache_lifetime 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_cache_maximum_age 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_compression 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_css 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_js 0
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set block_cache 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set cache_lifetime 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_cache_maximum_age 900
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set page_compression 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_css 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set preprocess_js 1
    fi

elif [ "${software}" = "drupal8" ]; then

    # https://www.drupal.org/node/2598914
    if [ "$1" = "dev" ]; then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.performance cache.page.max_age 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.performance css.preprocess 0
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.performance js.preprocess 0
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.performance cache.page.max_age 900
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.performance css.preprocess 1
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.performance js.preprocess 1
    fi
fi


# run website software database operations
if ([ ! -z "${software}" ]); then
    echo -e "* running ${software} log cleanup, cron, database migrations, and cache rebuilds..."
fi

if [ "${software}" = "codeigniter2" ]; then

    result=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php index.php migrate)
    if echo $result | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $result
    fi

elif [ "${software}" = "codeigniter3" ]; then
    
    result=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php index.php migrate)
    if echo $result | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $result
    fi

elif [ "${software}" = "concrete58" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 migrations:migrate --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job index_search --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job index_search_all --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job check_automated_groups --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job generate_sitemap --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job process_email --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job remove_old_page_versions --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job update_gatherings --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job update_statistics --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job fill_thumbnails_table --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:job deactivate_users --no-interaction
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:clear-cache --no-interaction --allow-as-root

elif [ "${software}" = "drupal6" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes core-cron
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes cache-clear all

elif [ "${software}" = "drupal7" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes core-cron
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes cache-clear all

elif [ "${software}" = "drupal8" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes core-cron
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes cache-rebuild

elif [ "${software}" = "elgg1" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "elgg2" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "expressionengine3" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "joomla3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/garbagecron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/update_cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/finder_indexer.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/deletefiles.php

elif [ "${software}" = "laravel5" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan key:generate
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan migrate
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan cache:clear
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan clear-compiled
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan optimize

elif [ "${software}" = "mediawiki1" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/update.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/runJobs.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/rebuildall.php

elif [ "${software}" = "moodle3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/purge_caches.php

elif [ "${software}" = "silverstripe3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php framework/cli-script.php dev/tasks/MigrationTask
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php framework/cli-script.php dev/build "flush=1"

elif [ "${software}" = "suitecrm7" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cron.php

elif [ "${software}" = "wordpress4" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php71 --allow-root core update-db
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php71 --allow-root cache flush
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php71 --allow-root w3-total-cache flush all

elif [ "${software}" = "wordpress5" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php72 --allow-root core update-db
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php72 --allow-root cache flush
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli-php72 --allow-root w3-total-cache flush all

elif [ "${software}" = "xenforo1" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "xenforo2" ]; then

    # @todo need to enable development mode
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-dev:recompile
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-dev:recompile-phrases
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-dev:recompile-style-properties
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-dev:recompile-templates
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-rebuild:forums
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-rebuild:search
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-rebuild:threads
    #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cmd.php xf-rebuild:users
    : #no-op

elif [ "${software}" = "zendframework2" ]; then

    echo "nothing to perform, skipping..."

fi

touch "/catapult/provisioners/redhat/logs/software_operations_meta.$(catapult websites.apache.$5.domain).complete"
