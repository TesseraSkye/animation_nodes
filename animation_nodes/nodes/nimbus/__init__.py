import os
import sys
from os.path import dirname, join, abspath, basename
# temporarily sets main package at current location, so that it can be itterated.
parent_dir = dirname(abspath(__file__))
main_package = parent_dir
# Iterates until it finds nimbus_vis or has run 10 times #10 subdirs max
iter = 0

while basename(main_package) != "animation_nodes" and iter in range(10):
    main_package = dirname(main_package)
    iter = iter + 1

library = join(main_package, "nimbus_libs")

if not library in sys.path:
    sys.path.append(library)
    print(library + " appended to sys path")
