# Solution for UiAutomator's "Could not detect idle state" Cpulimit/Cython

## pip install cythonuiautomatorstruct

### Tested against Windows 10 / Python 3.11 / Anaconda / ADB / Bluestacks 5

### Important!

The module will be compiled when you import it for the first time. Cython and a C++ compiler must be installed!

```python
from cythonuiautomatorstruct import yield_uiautomator_dump, pretty_print_struct_array

import shutil

adb_path = shutil.which("adb")
device_serial = "127.0.0.1:5560"
for r in yield_uiautomator_dump(
    shell_exe=[adb_path, "-s", device_serial, "shell"],
    appname="com.kiwibrowser.browser",
    pid=-1,
    cpu_limit=10,
    include_children=True,
    lazy=True,
    dump_timeout=10,
    nice_level="-20", # max priority for uiautomator 
    outfile="/sdcard/window_dump.xml",
    use_cpulimit=True,
    run_as_shell=True,
    debug=True,
    su_prefix_for_input="su -c '",
    su_sufix_for_input="'",
    cpulimit_path="/data/data/com.termux/files/usr/bin/cpulimit",  # https://github.com/opsengine/cpulimit, limits the cpu usage of the target process 
    su_prefix_for_cpulimit="su -c '",
    su_suffix_for_cpulimit="'",
):
    pretty_print_struct_array(r)

```