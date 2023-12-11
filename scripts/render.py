#!/usr/bin/env -S python3 -W ignore
from pathlib import Path
import os
import sys
import pkg_resources

from jinja2 import Environment, FileSystemLoader
env = Environment(loader=FileSystemLoader("scripts"))

version = os.environ["MAJOR_VERSION"]
requirements = Path(version) / "requirements.txt"

context = {
    "MAJOR_VERSION": version,
    "BASE": os.environ["BASE"],
    "PYTHON_VERSION": "{}.{}.{}".format(*sys.version_info),
}

with requirements.open() as r:
    context["PACKAGES"] = list(pkg_resources.parse_requirements(r))

template = env.get_template("packages.j2.md")

print(template.render(**context))
