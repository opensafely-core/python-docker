#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

executable = os.environ.get("ACTION_EXEC", "python")
exe_path = shutil.which(executable)
args = sys.argv[1:]

if len(sys.argv) > 1:
    path = shutil.which(sys.argv[1])
    # special case - the user has provided their own valid executable as the
    # first argument, so switch to executing that
    if path is not None:
        exe_path = path
        args = sys.argv[2:]


if os.environ.get("ENTRYPOINT_TESTING"):
    print([exe_path] + args)
else:
    os.execve(exe_path, [exe_path] + args, os.environ)
