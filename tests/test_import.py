import subprocess
from importlib import import_module
from pathlib import Path

import pytest

# map pypi package names to an importable module name
MAPPINGS = {
    "attrs": "attr",
    "google-api-core": "google.api_core",
    "google-auth": "google.auth",
    "google-cloud-bigquery": "google.cloud.bigquery",
    "google-cloud-core": "google.cloud",
    "google-resumable-media": "google.resumable_media",
    "googleapis-common-protos": "google.api",
    "ipython": "IPython",
    "opensafely-cohort-extractor": "cohortextractor",
    "opensafely-jobrunner": "jobrunner",
    "opensafely-matching": "osmatching",
    "pillow": "PIL",
    "pip-tools": "piptools",
    "presto-python-client": "prestodb",
    "protobuf": "google.protobuf",
    "pyopenssl": "OpenSSL",
    "python-dateutil": "dateutil",
    "pyyaml": "yaml",
    "pyzmq": "zmq",
    "ruamel.yaml.clib": None,
}


# generate list of expected packages to be able to install
def generate_import_name(req_path):
    with req_path.open() as fp:
        for line in fp:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            name, _, _ = line.partition("==")
            mapped_name = MAPPINGS.get(name, name.replace("-", "_"))
            if mapped_name:
                yield name, mapped_name


@pytest.mark.parametrize("name, module", generate_import_name(Path("requirements.txt")))
@pytest.mark.filterwarnings("ignore")
def test_import_package(name, module):
    try:
        import_module(module)
    except ImportError as exc:
        pytest.fail(f"could not import {module} from package {name}: {exc}")
