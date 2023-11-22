import os
import subprocess
from importlib import import_module
from pathlib import Path
import re

import pytest
from pkg_resources import Requirement, get_provider


# packages that have no way to detect their importable name
BAD_PACKAGES = {
    "beautifulsoup4": "bs4",
    "protobuf": None, # AARRRRGG
    "qtpy": None,  # required dependency of jupyter-lab
}

def get_module_names(pkg_name):
    """Load pkg metadata to find out its importable module name(s)."""
    # remove any extras
    pkg_name = re.sub(r'\[.*\]', '', pkg_name)
    modules = set()
    provider = get_provider(Requirement.parse(pkg_name))
    # top level package name is typically all we need
    if pkg_name in BAD_PACKAGES:
        name = BAD_PACKAGES[pkg_name]
        if name is None:  # unimportably package
            return []
        modules.add(BAD_PACKAGES[pkg_name])
    elif provider.has_metadata("top_level.txt"):
        first_line = list(provider.get_metadata_lines("top_level.txt"))[0]
        modules.add(first_line)
    else:
        # badly packaged dependency, make an educated guess
        name = pkg_name
        if pkg_name.endswith("-cffi"):
            name = pkg_name[:-5]
        elif pkg_name.endswith("-py"):
            name = pkg_name[:-3]
        
        modules.add(name.replace("-", "_"))

    if provider.has_metadata("namespace_packages.txt"):
        modules |= set(provider.get_metadata_lines("namespace_packages.txt"))

    # _ prefixed modules are typically C modules and not directly importable
    return [n for n in modules if n[0] != "_"]


def generate_import_names(major_version):
    """Generate list of expected modules to be able to import."""
    req_path = Path(major_version) / "requirements.txt"
    with req_path.open() as fp:
        for line in fp:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            name, _, _ = line.partition("==")
            for module in get_module_names(name):
                yield name, module


@pytest.mark.parametrize(
    "name, module", generate_import_names(os.environ["MAJOR_VERSION"])
)
@pytest.mark.filterwarnings("ignore")
def test_import_package(name, module):
    try:
        import_module(module)
    except ImportError as exc:
        pytest.fail(f"could not import {module} from package {name}: {exc}")
