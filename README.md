# <img src="README.assets/cpu.png" width="40" align=center /> RISCV-CPU 2023

## 实现框架

* Memory Controller
* Instruction Fetcher, Instruction Cache, Predictor
* Decoder(Despatcher)
* Reservation Station
* Reorder Buffer
* Load Store Buffer
* Register File
* ALU

主要架构特点为 Instruction Fetcher 放在 Instruction Cache 和 Memory Controller 中间，其实实际效率可能没什么提升，大概只是自己当时的想法罢了

## 运行效率

​	没有 Instruction Cache 的情况下，频率为 100 MHz，WNS 为 +1 ns 左右

​	使用大小为 256 的 Instruction Cache 的情况下，频率为 83.3MHz，WNS 为 -0.5 ns 左右，效率已经达到了正常水平，具体测试点运行时间待更新

​	使用大小为 512 的 Instruction Cache 的情况下，尚未测试，待更新

## 一些 bug

​	模拟时问题太杂了，参考 commit 记录

​	上板时组合逻辑中的 reg 没有赋初值导致存在 latch