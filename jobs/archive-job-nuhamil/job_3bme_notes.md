# job-3bme 脚本使用

如果用 mpi 的话，先设置一个 node 跑一段时间再取消，需要生成一些 mpi 运行读取的文件

## 参数设置

### LECs

5 个 LECs 按顺序 c1，c3，c4，cD，cE。拟合新参数的技巧是直接分别生成 5 个这参数为 1 的文件然后变动参数线性叠加起来。

### 正规子

``lambda_3nf_nonlocal`` 设置的是三体力正规子的 $\Lambda$，由核力本身决定，EM1.8/2.0 这种是 cutoff 设为 2 $\mathrm{fm}^{-1}$，需要换算为动量；而 lnl 等核力直接设置动量值。

NuHamil 程序是写了三体力的分波分解的，但处理 nonlocal 正规子会出现数值问题，因此直接读 Hebeler 的分波文件。

### SRG 参数

#### lambda
选择 SRG 到哪个 $\lambda$，不是正规子的 $\Lambda$。
#### 3-body SRG space
也就是 N3max，是 SRG 中的截断。可以为不同分波分别设置，比如 1/2 到 7/2 用大一些的 40，高分波低一些，推荐全用 46，即 ``ramp_space = "ramp46"``。但即使是裸核力也有影响。
### J3max
对结果的影响不如 N3max 大，推荐 15。

## 三体力格式

目前用的是 me3j.gz，压缩更好的是 ``ext_3bme = ".stream.bin"``，生成 emax =18，e3max=28 用。IMSRG 可以直接读。
### no2b
``only_no2b_elements`` 选择是 full 三体力还是 no2b 的三体力。IMSRG 也可以直接读。full 三体力只能到 E3max=16。
### 数值精度
``params['lab_3bme_precision']`` 开启的话是 float 的一半内存，不推荐。

## hw-conversion

不 SRG 时用 ``hw_temp = None``，SRG 时用 ``hw_temp = 30``，在 30 下做 SRG 并转到更小的 hw

## 动量空间矩阵元输入

### 两体力
三体力的项各核力都一样，原则上不依赖于两体力，只是拟合时需要与两体力一起拟合。然而 SRG 时会有诱导的三体力，因此要输入两体力在分波表象下的动量空间矩阵元 ``input_nn_file``，算其诱导的三体力与裸三体力加在一起。``params["genuine_3bf"] = True`` 就是加在一起，如果为 false 只有诱导的三体力。

通常分波表象的两体力动量 kmax=8，撒点 N=100，Jmax=8，但是对于比较硬的核力比如 local，kmax 要加大到 20，相应 N 要提升到 200。此时需要设置
```
params["nmesh2"] = 200

params["pmax2"] = 20.0
```
第二个参数影响不大，大一些也没事。

### 三体力
NuHamil 能自己进行分波分解，但是转分波表象过慢且有 nonlocal 正规子的数值问题，需要读取 Hebeler 已经转到分波表象的文件 ``input_3n_files``。
