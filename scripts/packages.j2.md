# Package Versions for {{ MAJOR_VERSION }}

This python:{{ MAJOR_VERSION }} OpenSAFELY image is based on Ubuntu {{ BASE }} with Python {{ PYTHON_VERSION }}.

## Packages

It comes pre-installed with a standard set of python packages.

{% for pkg in PACKAGES -%}
 - [{{ pkg | replace("==", ": ")}}](https://pypi.org/project/{{pkg.name}}/{{pkg.specs[0][1]}}/)
{% endfor -%}

