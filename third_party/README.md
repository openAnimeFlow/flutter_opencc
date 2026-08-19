# third_party

`third_party/opencc/` is a pinned OpenCC source checkout used only for
maintainer builds and is intentionally ignored by Git.

To fetch the exact source used by this package:

```text
git clone --depth 1 --branch ver.1.4.1 --recurse-submodules --shallow-submodules https://github.com/BYVoid/OpenCC.git third_party/opencc
```

The pinned tag is also recorded in `opencc.version`.
