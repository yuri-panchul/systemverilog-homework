# A collection of SystemVerilog exercises from the beginning to the microarchitectural job interview level

[Русский](README_ru.md)

## 1. The required software installation

The exercises in this repository use self-checking testbenches and scripts for basic verification of the student’s solutions. They work under Linux, MacOS, Windows with Git Bash and Windows WSL. The required software includes Icarus Verilog, Git and Bash. Git for Windows includes Bash. You may also need GTKWave or Surfer waveform viewer for debug and Verilator for linting. To install the necessary software, do the following:

### 1.1. Debian-derived Linux, Simply Linux or Windows WSL Ubuntu

```bash
sudo apt-get update
sudo apt-get install git iverilog gtkwave surfer verilator
```

If you use other Linux distribution, google how to install Git, Icarus Verilog, GTKWave, Surfer and Verilator.

Check the version of Icarus is at least 11 and preferrably 12.

```bash
iverilog -v
```

If not, [build Icarus Verilog from the source](https://github.com/steveicarus/iverilog).

### 1.2. Windows without WSL

Install [Git for Windows](https://gitforwindows.org/) and [Icarus Verilog for Windows](https://bleyer.org/icarus/iverilog-v12-20220611-x64_setup.exe).

### 1.3. MacOS

Use [brew](https://formulae.brew.sh/formula/icarus-verilog):

```zsh
brew install icarus-verilog
```

## 2. Cloning the repository

```
git clone https://github.com/yuri-panchul/systemverilog-homework.git
```

We recommend cloning it in a place without spaces or unusual characters in the path. While we are trying hard to write robust Bash scripts to handle all the unusual environment conditions, we do not test the package with weird directory names like "abc%^ $# \/a b".

## 3. The first exercise

```sh
cd 01_combinational_logic
```

On Linux, MacOS or Windows WSL

```sh
./run_linux_mac.sh
```

On Windows without WSL

```bat
run_windows.bat
```

You will see the following output:

```
FAIL 01_01_mux_question/testbench.sv
++ INPUT    => {d0:a, d1:b, d2:c, d3:d, sel:0}
++ EXPECTED => {ty:a}
++ ACTUAL   => {y:z}
FAIL 01_02_mux_if/testbench.sv
++ INPUT    => {d0:a, d1:b, d2:c, d3:d, sel:0}
...
```

Your goal is to get **PASS** on every exercise. To get the PASS on the first exercise, edit the file [systemverilog-homework/01_combinational_logic/01_01_mux_question/01_01_mux_question.sv](01_combinational_logic/01_01_mux_question/01_01_mux_question.sv). Re-run the script and if your solution is functionally correct, you will see:

```
PASS 01_01_mux_question/testbench.sv
FAIL 01_02_mux_if/testbench.sv
++ INPUT    => {d0:a, d1:b, d2:c, d3:d, sel:0}
...
```

Continue until you get **PASS** for every exercise.

You can see more detailed results in `log.txt`.

## 4. If you want to debug waveforms

Find the following place in the associated `testbench.sv` file and uncomment `$dumpvars`:

```v
initial
begin
    `ifdef __ICARUS__
    // Uncomment the following line
    // to generate a VCD file and analyze it using GTKwave or Surfer

    // $dumpvars;
`endif
```

Then re-run the script with `--wave` option:

```sh
./run_linux_mac.sh --wave
```

GTKWave or Surfer has to be installed.

## 5. If you want to run lint (Linux, MacOS and WSL only)

```sh
./lint_linux_mac.sh --lint
```
You can see the results in `lint.txt`. Verilator has to be installed.

## 6. Running more advanced exercises starting Homework 3

Read the article ["A new edition of SystemVerilog-Homework adds exercises that use FPU of an open-source CPU"](https://verilog-meetup.com/2025/02/11/a-new-edition-of-systemverilog-homework-adds-exercises-that-use-fpu-of-an-open-source-cpu/).

## 7. More steps

You need to read some books in parallel with doing the exercises. You can get a list of recommended literature in the article [Self-education and educating others](https://verilog-meetup.com/2024/02/03/self-education-and-educating-others/).

Once you develop a solution, especially for more challenging tasks on pipelining from Homework 4, you also need to check whether the code is synthesizable and has reasonable timing. You can use various FPGA synthesis tools for it (Xilinx, Altera, Gowin, Lattice, Efinix) or ASIC design tools (Synopsys Design Compiler, Cadence Genus, Open Lane, Caravel, Tiny Tapeout) – it is up to you. If you want to try open-source ASIC synthesis, there is an article on how to work around the pitfalls in this way: [The State of Caravel: the First Look](https://verilog-meetup.com/2025/02/11/a-new-edition-of-systemverilog-homework-adds-exercises-that-use-fpu-of-an-open-source-cpu/).

However this is not the end of the story. Your solution has to be reviewed by somebody with experience in SystemVerilog and microarchitecture: a teacher, colleague or interviewer. In any case, good luck and we hope you enjoy the experience.
