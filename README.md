# MatonOS store source contract

The AIDL interface and JSON formats between the MatonOS Software Centre and its
source plugins (F-Droid, Flatpak, ...). This repository is the only copy: the
store and every plugin include it as a git submodule and build `aidl/` as an
AIDL source directory. See [SOURCE-PLUGINS.md](SOURCE-PLUGINS.md).
