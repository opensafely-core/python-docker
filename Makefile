
requirements.txt: requirements.in .venv/bin/pip-compile
	.venv/bin/pip-compile requirements.in

.venv/bin/pip-compile: | .venv
	.venv/bin/pip install pip-tools

.venv:
	virtualenv -p python3 .venv




