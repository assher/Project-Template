DOMAIN = 
# args: apache2 or nginx
SERVER = 
# args: mariadb, mysql, postgresql
DATABASE = 
# args: phpmyadmin, pgadmin, adminer
MANAGER = 
# args: url to repository
CODE = 
# args: url to repository
DOCS =
# args: url to your laradock repository
DOCKER = https://github.com/Laradock/laradock.git
# args: args to docs
THEME_NAME = sphinx_rtd_theme
# args: args to project folder
MAIN_BRANCH = master
DEVELOP_BRANCH = develop

prepare:
	@echo "#"
	@echo "# 📦 Preparing folder for documentation..."
	@echo "#"
	pip install -U Sphinx
	pip install -U sphinx-rtd-theme
	mkdir -p resources/docs
	cd resources/docs; sphinx-quickstart
	cd resources/docs; sed -i -e "/.*html_theme*./ s/.*/html_theme = '$(THEME_NAME)'/" conf.py
certs:
	@echo "#"
	@echo "# 🏗️  Generate certs for https://${DOMAIN}"
	@echo "#"
	mkdir -p ${SERVER}/ssl
	mkcert -cert-file ./${SERVER}/ssl/${DOMAIN}.crt -key-file ./${SERVER}/ssl/${DOMAIN}.key ${DOMAIN} *.${DOMAIN}

install_certs:
	@echo "#"
	@echo "# 🎊 Install certs for https://${DOMAIN}"
	@echo "#"
	mkcert -install

add_submodules:
	@echo "#"
	@echo "# 📦 Add submodules"
	@echo "#"
	git submodule add ${DOCKER} bin
	cd bin; cp .env.example .env;

update_submodules:
	@echo "#"
	@echo "# 📦 Update submodules"
	@echo "#"
	git submodule update --init --recursive --remote --merge

build:
	@echo "#"
	@echo "# 🐳 Building ${DOMAIN}..."
	@echo "#"
	make update_submodules
	cd bin; docker-compose build ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis docker-in-docker
	@echo "#"
	@echo "# ✅ Done"
	@echo "#"

build_no_cache:
	@echo "#"
	@echo "# 🐳 Building ${DOMAIN} without cache... "
	@echo "#"
	make update_submodules
	cd bin; docker-compose build ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis docker-in-docker --no-cache
	@echo "#"
	@echo "# ✅ Done"
	@echo "#"

start:
	make certs
	make install_certs
	make build
	if [ ! -d "www" ]; then echo "Dir no exists"; git clone ${CODE} www  fi
	cd www; git checkout ${MAIN_BRANCH}
	cd bin; docker-compose up -d ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis docker-in-docker
	@echo "#"
	@echo "# 🖥️  ${DOMAIN} is up and running. Please open https://${DOMAIN} when ready"
	@echo "#"

stop:
	cd bin; docker-compose stop ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis docker-in-docker
	@echo "#"
	@echo "# 🖥️  ${DOMAIN} is stoped."
	@echo "#"

restart:
	cd bin; docker-compose restart ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis docker-in-docker
	@echo "#"
	@echo "# 🖥️  ${DOMAIN} is restarted."
	@echo "#"

devel:
	make certs
	make install_certs
	make build
	@echo "#"
	@echo "# 🚧 Building ${DOMAIN}"
	@echo "#"
	if [ ! -d "www" ]; then echo "Dir no exists"; git clone ${CODE} www  fi
	cd www; git checkout ${DEVELOP_BRANCH}
	cd bin; docker-compose up -d ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis docker-in-docker

clean:
	@echo "#"
	@echo "# 🧹 Cleaning old container"
	@echo "#"
	cd bin; docker-compose down
	@echo "#"
	@echo "# ✅ Done"
	@echo "#"


%:
	@:

.PHONY: % certs
