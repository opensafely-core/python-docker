import subprocess
from importlib import import_module
from pathlib import Path

import pytest
from pkg_resources import Requirement, get_provider


def get_module_names(pkg_name):
    """Load pkg metadata to find out its importable module name(s)."""
    modules = set()
    provider = get_provider(Requirement.parse(pkg_name))
    # top level package name is typically all we need
    if provider.has_metadata("top_level.txt"):
        modules |= set(provider.get_metadata_lines("top_level.txt"))
    else:
        # badly packaged dependency, make an educated guess
        modules.add(pkg_name.replace("-", "_"))

    if provider.has_metadata("namespace_packages.txt"):
        modules |= set(provider.get_metadata_lines("namespace_packages.txt"))

    # _ prefixed modules are typically C modules and not directly importable
    return [n for n in modules if n[0] != "_"]


def generate_import_names(req_path):
    """Generate list of expected modules to be able to import."""
    with req_path.open() as fp:
        for line in fp:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            name, _, _ = line.partition("==")
            for module in get_module_names(name):
                yield name, module


@pytest.mark.parametrize(
    "name, module", generate_import_names(Path("requirements.txt"))
)
@pytest.mark.filterwarnings("ignore")
def test_import_package(name, module):
    try:
        import_module(module)
    except ImportError as exc:
        pytest.fail(f"could not import {module} from package {name}: {exc}")
