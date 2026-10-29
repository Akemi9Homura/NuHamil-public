# job-nuhamil 留档

本目录下的文件于 2026-10-28 从已废弃的计算目录仓库 `Akemi9Homura/job-nuhamil`（私有，由 `hhurongzhe/job-nuhamil` 的 ef63f4b 复制而来，2026-10-25 起不再使用）**原样迁入，只作留档，内容没有任何修改**。

- 来源版本：该仓库最后一个提交 28a8393（2026-06-02，"Add 3BME usage notes"）。点7 `/tns/mengziyan/job-nuhamil` 工作区里的同名文件与它相同（md5 核对）。
- 这里的文件不再维护。现行的编译、环境和作业模板见上一级的 `jobs/README.md`。

| 本目录 | 原位置 | 内容 |
|---|---|---|
| `job_3bme_notes.md` | `README.md` | 三体力作业 `job_3bme.py` 的参数笔记：LEC、正规子、SRG 空间、格式、hw 换算、动量空间输入 |
| `job-phase/` | `job-phase/` | 相移计算与画图脚本，以及 `Nijmegen.csv`。这是原仓库里改过的版本，上游原版在 `exe/phase-shift-analysis/` |
| `tools/clean.py` | `tools/clean.py` | 清理计算目录的小工具：先列出当前目录下 `script/`、`result/`、`workspace/`（含 `cfp/`、`ops/`）里的文件，确认后删除 |

## 原样保留带来的限制

相移脚本不能从这里直接运行：
- `calc_phase_shift.py` 写死了 Mac 路径 `/Users/mac/Desktop/job-NuHamil`；
- 两个画图脚本依赖本仓库里没有的 `lib.ini_plot`，并按相对路径 `phase-shift-analysis/Nijmegen.csv` 读数据。

`Nijmegen.csv` 与 `exe/phase-shift-analysis/` 里的相同。

## 原仓库其余内容的去向

| 原位置 | 现在 |
|---|---|
| `job-nbme/job_2bme.py` | `jobs/job_2bme.py`，只把 `HOME` 改为自动选点7或 wm2 |
| `job-nbme/job_3bme.py` | `jobs/job_3bme.py`，相同 |
| `sourceme.sh` | `jobs/sourceme_point7.sh`，按点7 环境重写 |
| `input_nn_files/*.bin` | 与本仓库 `input_nn_files/` 逐字节相同 |
| `NuHamil.exe` | 不再使用：它是 Mac arm64 程序。点7 的程序见 `jobs/README.md` |
