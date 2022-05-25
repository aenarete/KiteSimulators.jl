## Installation of Julia

### Windows
Please download and install Julia as explained at https://julialang.org/downloads/ .
Choose the 64-bit (installer). Make sure to check the option "Add julia to path" when running the installer.

Alternatively you can try https://github.com/PetrKryslUCSD/VSCode_Julia_portable , which comes with the IDE VSCode
and git included.

### Linux

Copy and past the following line to install the latest stable version of Julia:
```
bash -ci "$(curl -fsSL https://raw.githubusercontent.com/abelsiqueira/jill/master/jill.sh)"
```
If you want to be able to easily switch between different versions of Julia consider to install
the Python version of jill, see https://github.com/johnnychen94/jill.py
```bash
pip install jill
jill install
```

### Mac
Please download and install Julia as explained at https://julialang.org/downloads/

The jill installers will most likely also work on Mac and allow eays switching of different Julia versions (see Linux section).

Continue with [README](../README.md)