from pathlib import Path
import subprocess

import pytest

os_release = Path("/etc/os-release").read_text()

@pytest.mark.skipif('VERSION_ID="20.04"' not in os_release, reason="20.04 only")
def test_esm():
    output = subprocess.check_output(["dpkg-query", "-W", "-f='${Package}\t${Version}\n'", "libssl1.1"], text=True)
    assert "esm" in output
