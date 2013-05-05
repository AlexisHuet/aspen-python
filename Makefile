PYTHON=python


# Core Executables
# ================
# We satisfy dependencies using local tarballs, to ensure that we can build 
# without a network connection. They're kept in our repo in ./vendor.

ASPEN_DEPS=Cheroot-4.0.0beta.tar.gz mimeparse-0.1.3.tar.gz tornado-1.2.1.tar.gz

TEST_DEPS=coverage-3.5.3.tar.gz nose-1.1.2.tar.gz nosexcover-1.0.7.tar.gz snot-0.6.tar.gz

env/bin/aspen: env/bin/pip
	for f in $(ASPEN_DEPS) ; do \
		./env/bin/pip install ./vendor/$$f ;\
	done
	./env/bin/python setup.py develop

env/bin/nosetests: env/bin/pip
	for f in $(TEST_DEPS) ; do \
		./env/bin/pip install ./vendor/$$f ;\
	done

env/bin/pylint: env/bin/pip
	./env/bin/pip install pylint

env/bin/pip:
	$(PYTHON) ./vendor/virtualenv-1.7.1.2.py \
		--distribute \
		--unzip-setuptools \
		--prompt="[aspen] " \
		--never-download \
		--extra-search-dir=./vendor/ \
		env/

env: env/bin/pip

env-clean:
	find . -name \*.pyc -delete
	rm -rf env smoke-test


# Doc / Smoke
# ===========

docs: env/bin/aspen
	./env/bin/aspen -a:5370 -wdoc/ -pdoc/.aspen --changes_reload=1

doc: docs

smoke: env/bin/aspen
	@mkdir smoke-test && echo "Greetings, program!" > smoke-test/index.html
	./env/bin/aspen -w smoke-test


# Testing
# =======

test: env/bin/aspen env/bin/nosetests
	./env/bin/nosetests -sx tests/

nosetests.xml coverage.xml: env/bin/aspen env/bin/nosetests
	./env/bin/nosetests \
		--with-xcoverage \
		--with-xunit tests \
		--cover-package aspen 

pylint.out: env/bin/pylint
	./env/bin/pylint --rcfile=.pylintrc aspen | tee pylint.out

analyse: pylint.out coverage.xml nosetests.xml
	@echo done!

testing-clean:
	rm -rf .coverage coverage.xml nosetests.xml pylint.out


# Build
# =====

build:
	python setup.py bdist_egg

build-clean:
	python setup.py clean -a
	rm -rf dist


# Jython
# ======

vendor/jython-installer.jar:
	#@wget "http://downloads.sourceforge.net/project/jython/jython/2.5.2/jython_installer-2.5.2.jar?r=http%3A%2F%2Fwiki.python.org%2Fjython%2FDownloadInstructions&ts=1336182239&use_mirror=superb-dca2" -O ./vendor/jython-installer.jar
	@wget "http://search.maven.org/remotecontent?filepath=org/python/jython-installer/2.5.3/jython-installer-2.5.3.jar" -O ./vendor/jython-installer.jar

jython_home: vendor/jython-installer.jar
	@java -jar ./vendor/jython-installer.jar -s -d jython_home

jenv/bin/pip: jython_home
	PATH=`pwd`/jython_home/bin:$$PATH jython ./vendor/virtualenv-1.7.1.2.py \
		--python=jython \
		--distribute \
		--unzip-setuptools \
		--prompt="[aspen] " \
		--never-download \
		--extra-search-dir=./vendor/ \
		jenv/
	# always required for jython since it's ~= python 2.5
	./jenv/bin/pip install simplejson


jenv/bin/aspen: jenv/bin/pip
	for f in $(ASPEN_DEPS) ; do \
		./jenv/bin/pip install ./vendor/$$f ;\
	done
	./jenv/bin/jython setup.py develop

jenv/bin/nosetests: jenv/bin/pip
	for f in $(TEST_DEPS) ; do \
		./jenv/bin/pip install ./vendor/$$f ;\
	done

jython-nosetests.xml: jenv/bin/nosetests jenv/bin/aspen
	./jenv/bin/jython ./jenv/bin/nosetests --with-xunit tests --xunit-file=jython-nosetests.xml --cover-package aspen

jython-test: jython-nosetests.xml

jython-clean:
	rm -rf jenv vendor/jython-installer.jar jython_home jython-nosetests.xml
	find . -name \*.class -delete


# Clean
# =====

clean: env-clean testing-clean jython-clean build-clean


