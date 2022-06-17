DOMAIN = 
# args: apache2 or nginx
SERVER = 
# args: mariadb, mysql, postgresql
DATABASE = 
# args: phpmyadmin, pgadmin, adminer
MANAGER = 
# args: url to repository
CODE = 
# args: url to documentation
DOCS = 
# args: url to your laradock repository
DOCKER = https://github.com/Laradock/laradock.git
# args: args to docs
THEME_NAME = sphinx_rtd_theme
# args: args to project folder
MAIN_BRANCH = main
DEVELOP_BRANCH = develop
DOCKER_MAIN_BRANCH = main
DOCKER_DEVELOP_BRANCH = develop
USE_SUBTREE = true

prepare:
	@echo "#"
	@echo "# 📦 Preparing folder for documentation..."
	@echo "#"
	pip install -U Sphinx
	pip install -U sphinx-rtd-theme
	pip install -U myst-parser
	if [ ! -d "resources/docs" ]; then \
		if ${USE_SUBTREE}; then \
		 git subtree add --prefix resources/docs ${DOCS} ${MAIN_BRANCH} --squash; \
		else \
			git clone ${DOCS} resources/docs; \
		fi \
	fi
	
certs:
	@echo "#"
	@echo "# 🏗️  Generate certs for https://${DOMAIN}"
	@echo "#"
	mkdir -p ${SERVER}/ssl
	if [ ! -f "${SERVER}/ssl/${DOMAIN}.crt" ]; then \
		mkcert -cert-file ./${SERVER}/ssl/${DOMAIN}.crt -key-file ./${SERVER}/ssl/${DOMAIN}.key ${DOMAIN} *.${DOMAIN}; \
	fi

install_certs:
	@echo "#"
	@echo "# 🎊 Install certs for https://${DOMAIN}"
	@echo "#"
	mkcert -install

add_submodules:
	@echo "#"
	@echo "# 📦 Add submodules"
	@echo "#"
	if [ ! -f "bin/.env" ]; then git submodule add ${DOCKER} bin; cd bin; cp .env.example .env; fi
	cd bin; git checkout ${DOCKER_MAIN_BRANCH};
	git add bin; git commit -m "moved submodule to ${DOCKER_MAIN_BRANCH}"; git push;

update_submodules:
	@echo "#"
	@echo "# 📦 Update submodules"
	@echo "#"
	if [ -d "bin" ]; then git submodule update --init --recursive --remote --merge; fi

build:
	@echo "#"
	@echo "# 🐳 Building ${DOMAIN}..."
	@echo "#"
	make update_submodules
	if [ -f "bin/.env" ]; then \
		cd bin; docker-compose build ${SERVER} ${DATABASE} php-fpm ${MANAGER} redis; \
	else \
		@echo "not exist please run make add_submodules first"; \
	fi
	@echo "#"
	@echo "# ✅ Done"
	@echo "#"

build_no_cache:
	@echo "#"
	@echo "# 🐳 Building ${DOMAIN} without cache... "
	@echo "#"
	make update_submodules
	cd bin; docker-compose build --no-cache ${SERVER} ${DATABASE} php-fpm ${MANAGER} redis
	@echo "#"
	@echo "# ✅ Done"
	@echo "#"

start:
	make certs
	make install_certs
	make build
	cd bin; git checkout ${DOCKER_MAIN_BRANCH};
	git add bin; git commit -m "moved submodule to ${DOCKER_MAIN_BRANCH}"; git push;
	make update_submodules
	if [ ! -d "www" ]; then \
		if ${USE_SUBTREE}; then \
		 echo "Dir no exists"; git subtree add --prefix www ${CODE} ${MAIN_BRANCH} --squash; \
		else \
			git clone ${CODE} www; \
		fi \
	fi
	cd www; git checkout ${MAIN_BRANCH}
	cd bin; docker-compose up -d ${SERVER} ${DATABASE} php-fpm ${MANAGER} redis
	@echo "#"
	@echo "# 🖥️  ${DOMAIN} is up and running. Please open https://${DOMAIN} when ready"
	@echo "#"

stop:
	cd bin; docker-compose stop ${SERVER} ${DATABASE} php-fpm ${MANAGER} redis
	@echo "#"
	@echo "# 🖥️  ${DOMAIN} is stoped."
	@echo "#"

restart:
	cd bin; docker-compose restart ${SERVER} ${DATABASE} php-fpm ${MANAGER} redis
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
	cd bin; git checkout ${DOCKER_DEVELOP_BRANCH};
	git add bin; git commit -m "moved submodule to ${DOCKER_DEVELOP_BRANCH}"; git push;
	make update_submodules
	if [ ! -d "www" ]; then \
		if ${USE_SUBTREE}; then \
		 echo "Dir no exists"; git subtree add --prefix www ${CODE} ${DEVELOP_BRANCH} --squash; \
		else \
			git clone ${CODE} www; \
		fi \
	fi
	cd www; git checkout ${DEVELOP_BRANCH}
	cd bin; docker-compose up -d ${SERVER} ${DATABASE} php-fpm ${MANAGER} workspace redis

clean:
	@echo "#"
	@echo "# 🧹 Cleaning old container"
	@echo "#"
	if [ -d "bin" ]; \
		then cd bin; docker-compose down; \
	fi
	pip uninstall -y Sphinx
	pip uninstall -y sphinx-rtd-theme
	@echo "#"
	@echo "# ✅ Done"
	@echo "#"


%:
	@:

.PHONY: % certs
