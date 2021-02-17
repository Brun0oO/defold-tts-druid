# Contribution guide

If you have some improvements to bring the project, feel free to open a pull request.

Please stick to the indentation style used throughout the project (K&R-like).


## Compiling the bridge library

Most of the extension is implemented in a separately-compiled bridge library.
When changing something, the bridge library must be recompiled for all the
platforms affected by the change.

### macOS & iOS
For both iOS and macOS, you'll need to install Xcode, open it, then accept the
license agreement and let it install the command line tools. Then:

```bash
cd bridge
make -f Makefile.osx
make -f Makefile.ios
```

### Linux
to be implemented !

### Windows
to be implemented !

### Android
to be implemented !

### HTML5
to be implemented !