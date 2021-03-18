import os
import subprocess

import pytest


def test_bare_python():
    env = os.environ.copy()
    env["ENTRYPOINT_TESTING"] = "1"
    cmd = ["/entrypoint.py"]
    ps = subprocess.run(cmd, check=True, capture_output=True, env=env)
    assert ps.stdout.strip() == b"['/usr/bin/python']"


def test_python_args():
    cmd = ["/entrypoint.py", "-c", "print('test')"]
    ps = subprocess.run(cmd, check=True, capture_output=True)
    assert ps.stdout.strip() == b"test"


def test_exec_with_args():
    cmd = ["/entrypoint.py", "bash", "-c", "echo test"]
    ps = subprocess.run(cmd, check=True, capture_output=True)
    assert ps.stdout.strip() == b"test"


def test_python_script(tmp_path):
    script = tmp_path / "test.py"
    script.write_text("import sys; print(sys.argv)")

    cmd = ["/entrypoint.py", script, "a", "-b", "--arg"]
    ps = subprocess.run(cmd, check=True, capture_output=True)
    # this means it ran: python {script} ...
    expected = f"['{script}', 'a', '-b', '--arg']".encode("utf8")
    assert ps.stdout.strip() == expected
