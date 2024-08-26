# Collection of SystemVerilog tasks for the School of Digital Circuit Synthesis

> **Not a day without a line in Verilog**
>
> Collection of tasks of increasing complexity
>
> Yuri Panchul, 2021-2023

## Links

* [School of Digital Circuit Synthesis](https://engineer.yadro.com/chip-design-school/)
* [Lesson one: introduction to the design flow and exercises with combinational logic](https://youtu.be/DFcvEO-gP0c)

<!-- Some markdown video embedding tricks from https://stackoverflow.com/questions/4279611/how-to-embed-a-video-into-github-readme-md -->

[![](https://img.youtube.com/vi/DFcvEO-gP0c/hqdefault.jpg)](https://youtu.be/DFcvEO-gP0c)


## Installation instructions

The tasks can be solved with any Verilog simulator that supports SystemVerilog. And also with the free Icarus Verilog simulator, which, although it does not support all of SystemVerilog, does support Verilog 2005 with some SystemVerilog elements, sufficient for solving our tasks. Icarus Verilog is used with GTKWave, a program for working with timing diagrams. We will not need GTKWave for the first ten tasks, but it is worth installing it together with Icarus Verilog for the future.

<p><img src="https://habrastorage.org/r/w1560/getpro/habr/upload_files/5c1/69d/934/5c169d9349c4352399b6cd962cdaa645.png">
<img src="https://habrastorage.org/r/w1560/getpro/habr/upload_files/219/8b5/8d9/2198b58d9b1daa7345c07d2770ca2763.png">
</p>

### Installation on Linux

Under Ubuntu and Debain based Linux you can install Icarus Verilog and GTKWave with the command:

`sudo apt-get install verilog gtkwave`

---
#### Note:

If you have an old version of Linux distribution (Ubuntu), then when you install Icarus Verilog you will get an old version that does not support `always_comb`, `always_ff` and many other SystemVerilog constructs. How to solve this problem:

1. **Checking iverilog version** 
    ```bash
    iverilog -v
    ```
    If the iverilog version is less than 11, go to point 3.
    

2. **Installation of preliminary packages**
    ```bash
    sudo apt-get install build-essential bison flex gperf readline-common libncurses5-dev nmon autoconf
    ```

3. **Download the latest version of iverilog**

    To date (8.25.2024) the latest version of Iverilog: 12.0
    Go [here](https://sourceforge.net/projects/iverilog/files/iverilog/12.0/) and download the archive.

4. **Assembly iverilog**
    - Extract the archive:
        ```bash
        tar -xzf verilog-12.0.tar.gz
        ```

    - Enter into the verilog folder:
        ```bash
        cd verilog-12.0
        ```

    - Configure iverilog:
        ```bash
        ./configure --prefix=/usr
        ```

    - Run the make checks
        ```bash
        make check
        ```
        As a result, several inscriptions of `HELLO, World!` Will appear in the terminal

    - Install icarus
        ```bash
        sudo make install
        ```
---
### Verilator

Additionally, to check the code for some syntactic and stylistic errors, you can install Verilator (versions 5.002+).

For Ubuntu 23.04 and above:

`sudo apt-get install verilator`

For earlier versions of Ubuntu or other distributions, you can install Verilator along with [OSS CAD Suite] (https://github.com/yossyshq/oss-cad-suite-build?tab=Readme-ov-v-v-ville#installation)

To check, add the option`--lint` to the script:
`./run_all_using_iverilog_under_linux_or_macos_brew.sh --lint`

The result will appear in the file `lint.txt`

---
### Installation on Windows

The Icarus Verilog version for Windows can be downloaded [from this site] (https://bleyer.org/icarus/)

[Video Instructions for the installation of icarus verilog on Windows](https://youtu.be/5kync4z5vow)


[![](https://img.youtube.com/vi/5Kync4z5VOw/hqdefault.jpg)](https://www.youtube.com/watch?v=5Kync4z5VOw)

### Installation on Apple Mac

Icarus can even be put on Apple Mac, which is unusual for EDA tools (EDA - Electronic Design Automation). This can be done in the console using the Brew:

`brew install icarus-verilog`

[Video Instructions for the installation of icarus verilog on macos](https://youtu.be/juykyoyr8hs)

[![](https://img.youtube.com/vi/jUYkYoYr8hs/hqdefault.jpg)](https://www.youtube.com/watch?v=jUYkYoYr8hs)


## Execution and checking tasks

To check the tasks for Linux and MacOS, you need to open the console in the folder and start the script `./run_all_using_iverilog_under_linux_or_macos_brew.sh`. It will create a file _log.txt_ with the results of compilation and simulation of all set tasks.

To check the tasks for Windows, you need to open the console in the task folder and run the bat file `run_all_using_iverilog_under_windows.bat`. This will also create a file _log.txt_ with the results of the check.

After the test for all tasks will show **PASS**.

## Recommended literature that will help in solving problems

1. [Harris D.M., Harris S.L., “Digital circuitry and computer architecture: RISC-V”](https://dmkpress.com/catalog/electronics/circuit_design/978-5-97060-961-3). There is [a version for a tablet for a previous edition](https://silicon-russia.com/public_materials/2018_01_15_latest_harris_harris_ru_barabanov_version/digital_design_rus-25.10.2017.pdf) (based on MIPS architecture), but there are shorter [slides for lectures](http://www.silicon-russia.com/public_materials/2016_09_01_harris_and_harris_slides/DDCA2e_LectureSlides_Ru_20160901.zip).
![](https://habrastorage.org/r/w1560/getpro/habr/upload_files/26c/817/9c3/26c8179c34c52fa937cd2200f789c3d0.png)

2. [Романов А.Ю., Панчул Ю.В. и коллектив авторов. «Цифровой синтез. Практический курс»](https://dmkpress.com/catalog/electronics/circuit_design/978-5-97060-850-0/)
