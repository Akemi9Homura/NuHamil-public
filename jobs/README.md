# 点7 上的 NuHamil：编译、环境与计算目录

2026-10-25 整理。

## 分工

| 位置 | 内容 | git |
|---|---|---|
| 本仓库（`Akemi9Homura/NuHamil-public`，点7 `/tns/mengziyan/NuHamil-public`） | 源码（跟 `Takayuki-Miyagi/NuHamil-public` 同步），以及 `jobs/` 下的点7 编译脚本、运行环境、作业模板 | 是，唯一的仓库 |
| 计算目录 `/tns/mengziyan/job-nuhamil` | `NuHamil.exe` 和 `BINARY_INFO`、`sourceme.sh`（即 `jobs/sourceme_point7.sh`）、`input_nn_files`（指向本仓库同名目录的符号链接）、`workspace/`（NN 相对坐标缓存等）、`result/<任务>/` | 否 |
| `remote_control/<课题>/nuhamil/script/` | 各课题自己的作业生成脚本，例如 lfor-M1 的 `gen_m1_2bc.py` | 跟 remote_control |

- 计算目录原来是一个 git 仓库（`Akemi9Homura/job-nuhamil`，私有，由 `hhurongzhe/job-nuhamil` 的 ef63f4b 复制而来），2026-10-25 起不再往里提交。
- 它里面的 `job-nbme/`、`job-phase/` 脚本还在原处，可以照常运行；作业模板以本仓库 `jobs/` 下的为准。
- 它在本仓库没有对应的部分（三体力笔记、相移脚本、`clean.py`）已原样留档在 `jobs/archive-job-nuhamil/`，说明见其中的 `README.md`。
- `hhurongzhe/job-nuhamil` 之后的更新依赖他自己的 NuHamil 版本（如 `cached_lambdas` 参数），不合并。

## 编译

在点7 登录节点上运行：

```bash
cd /tns/mengziyan/NuHamil-public
bash jobs/build_point7.sh          # 默认输出 exe/NuHamil_point7.exe（已被 git 忽略）
```

- 脚本先把源码树复制到临时目录再编译，不动仓库里的 `obj/`、`mod/`、`exe/`（里面的 `exe/NuHamil.exe` 是 c366c85 的 Intel MPI 版）。
- 编译时加载 `gsl/2.7.1 hdf5/1.14.1 openblas/0.3.10` 三个 module。module 名写的是 0.3.10，实际库是 `/opt/library/openblas` 下的 0.3.26（ZEN）。
- 用 `LFLAGS` 把 BLAS 和 LAPACK 都换成 OpenBLAS，并写入 rpath。脚本结束时会检查链接结果：如果还链接着通用的 `libblas.so`、`liblapack.so`，就报错退出。
- **为什么不能直接 `make`**：Makefile 默认链接 `-lblas -llapack`。
  - 在 Debian/Ubuntu 上，它们一般经 alternatives 指向 OpenBLAS，所以本地 WSL 没问题。
  - 在点7 上，它们落到 `/opt/library/lapack-3.11.0`，即 Netlib 参考 BLAS：单线程、没有优化。
  - 两体算符变换到实验室系（TMTrans）是一个串行循环，每次调用 `dgemm`，整个阶段的速度就由 BLAS 决定。M1 两体流 emax 8 上，TMTrans 从 110 s（参考 BLAS）降到 18 s（OpenBLAS），结果逐项一致（差约 1e-16）。
- 本仓库 Makefile 里点7 需要的三处改动已经提交：`-lgslcblas`、`-ffree-line-length-0`、`-I/opt/library/hdf5-1.14.1/include`。它们在别的机器上无害。

## 安装到计算目录

```bash
cd /tns/mengziyan/job-nuhamil
cp -p NuHamil.exe NuHamil.exe.<旧版本标记>        # 旧版本保留，NuHamil.exe.* 已被忽略
cp /tns/mengziyan/NuHamil-public/exe/NuHamil_point7.exe NuHamil.exe.new
mv -f NuHamil.exe.new NuHamil.exe                  # 原子替换，正在跑的作业不受影响
```

然后更新同目录的 `BINARY_INFO`。要写的内容：
- 安装时间、sha256、版本号（日志里打印的 `# Version is …`）；
- 源码提交和未提交的改动；
- 编译命令、编译器、链接的库；
- 验证结果；
- 旧版本的去向。

验证的最低要求：用一个小算例（如 M1 两体流 emax 4）对比新旧程序的输出。

## 运行环境与线程

- 作业脚本先 `source /tns/mengziyan/job-nuhamil/sourceme.sh`。
  - 它不做 `module purge`，因为默认环境提供 gsl、hdf5。
  - 它设置 `LD_LIBRARY_PATH`；其中 lapack-3.11.0 只供旧备份程序使用。
  - 它设置 OpenMP 线程数等于 Slurm 分到的核数，并设 `OPENBLAS_NUM_THREADS=1`。
- **OpenBLAS 线程**：点7 的 OpenBLAS 是 pthread 版，不是 OpenMP 版。
  - `OPENBLAS_NUM_THREADS=1` 时，BLAS 在调用它的线程里执行，任何地方都安全，包括 OpenMP 并行区（三体力代码）。
  - 在 OpenMP 并行区里以多线程调用时，库自己会警告 "may hang"。
  - 只有当 BLAS 调用都在 OpenMP 并行区之外时，才在 `source` 之后把它设成核数。已验证的路径：两体算符的生成（`M1_2BC`、`M1_2BC_intr`、`M1_2BC_Sachs`，`bare`）。NN 两体矩阵元、三体力尚未验证，保持 1。
- 输出重定向到文件时有缓冲，日志要到结束才写出。看运行状态用 `srun --jobid=<作业号> --overlap ps …`，或读 `/proc/<pid>/status`、`/proc/<pid>/io`。

## 作业模板

`jobs/job_2bme.py`（NN 两体矩阵元）和 `jobs/job_3bme.py`（三体力）。
- 按存在的家目录自动选择点7 或 wm2 的路径。
- 生成的脚本写在当前目录的 `./script/`、`./result/`，并 `source sourceme.sh`，所以要在计算目录里运行：

```bash
cd /tns/mengziyan/job-nuhamil
python3 /tns/mengziyan/NuHamil-public/jobs/job_3bme.py
```

改参数时，先把模板复制到课题目录（`remote_control/<课题>/nuhamil/script/`）再改，或者改模板本身并提交。

wm2：模板里有 wm2 的路径，但 wm2 上还没有按本文编译和配置环境。
