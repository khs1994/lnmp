* https://github.com/containerd/cri/blob/master/docs/config.md
* https://github.com/containerd/containerd/blob/master/docs/ops.md
* https://github.com/containerd/containerd/blob/master/docs/man/containerd-config.toml.5.md

```bash
$ containerd config default > config.default.toml
```

```bash
$ diff -u cri-containerd/1.4/config.default.toml cri-containerd/1.5/config.default.t
oml
```