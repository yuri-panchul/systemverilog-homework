# Сборник задач на SystemVerilog для Школы Синтеза Цифровых Схем

> **Ни дня без строчки на Верилоге**
>
> Сборник задач увеличивающейся сложности
>
> Юрий Панчул, 2021-2023


## Ссылки

* [Школа Синтеза Цифровых Схем](https://engineer.yadro.com/chip-design-school/)
* [Занятие первое: введение в маршрут проектирования и упражнения с комбинационной логикой](https://youtu.be/DFcvEO-gP0c)

<!-- Some markdown video embedding tricks from https://stackoverflow.com/questions/4279611/how-to-embed-a-video-into-github-readme-md -->

[![](https://img.youtube.com/vi/DFcvEO-gP0c/hqdefault.jpg)](https://youtu.be/DFcvEO-gP0c)


## Инструкция по установке

Задачи можно решать с любым симулятором верилога, который поддерживает SystemVerilog. А также c бесплатным симулятором Icarus Verilog, который хотя и не поддерживает весь SystemVerilog, но поддерживает Verilog 2005 с некоторыми элементами SystemVerilog, достаточных для решения наших задач. Icarus Verilog что используют с GTKWave, программой для работы с временными диаграммами. Для первых десяти задач GTKWave нам не понадобится, но его стоит установить вместе с Icarus Verilog на будущее.

<p><img src="https://habrastorage.org/r/w1560/getpro/habr/upload_files/5c1/69d/934/5c169d9349c4352399b6cd962cdaa645.png">
<img src="https://habrastorage.org/r/w1560/getpro/habr/upload_files/219/8b5/8d9/2198b58d9b1daa7345c07d2770ca2763.png">
</p>

### Установка на Linux

Под Ubuntu и Simply Linux можно установить Icarus Verilog и GTKWave с помощью команды:

`sudo apt-get install verilog gtkwave`

---
#### Замечание:

Если у вас старая версия дистрибутива Linux (Ubuntu), то при установке Icarus
Verilog вы получите старую версию, которая не поддерживает `always_comb`,
`always_ff` и многие другие конструкции SystemVerilog. Как решить эту проблему:
1. **Проверка версии iverilog**
    ```bash
    iverilog -v
    ```

    Если версия iverilog меньше 11, переходим к пункту 2.

2. **Установка предварительных пакетов**
    ```bash
    sudo apt-get install build-essential bison flex gperf readline-common libncurses5-dev nmon autoconf
    ```

3. **Скачивание последней версии iverilog**

   На сегодняшний момент (12.10.2023) последняя версия iverilog: 12.0
   Переходим по [ссылке](https://sourceforge.net/projects/iverilog/files/iverilog/12.0/) и скачиваем архив.

4. **Сборка iverilog**
    - Распакуйте архив:
        ```bash
        tar -xzf verilog-12.0.tar.gz
        ```

    - Войдите в разархивированную папку:
        ```bash
        cd verilog-12.0
        ```

    - Сконфигурируйте iverilog:
        ```bash
        ./configure --prefix=/usr
        ```

    - Протестируйте сборку Icarus
        ```bash
        make check
        ```
        В результате, в терминале появится несколько надписей `Hello, world!`

    - Установите Icarus
        ```bash
        sudo make install
        ```
---

### Установка на Windows

Версию Icarus Verilog для Windows можно загрузить [с данного сайта](https://bleyer.org/icarus/)

[Видео инструкция по установке Icarus Verilog на Windows](https://youtu.be/5Kync4z5VOw)


[![](https://img.youtube.com/vi/5Kync4z5VOw/hqdefault.jpg)](https://www.youtube.com/watch?v=5Kync4z5VOw)

При установке не забудьте добавить пути к исполняемым файлам icarus/gtkwave в PATH, т.к это может вызвать ошибку при запуске.
Поставьте галочку напротив Add executable folder(s) to the user PATH при установке или сделайте это [вручную](https://remontka.pro/add-to-path-variable-windows/)

### Установка на Apple Mac

Icarus можно поставить даже на Apple Mac, что необычно для EDA инструментация (EDA - Electronic Design Automation). Это можно сделать в консоли с помощью программы brew:

`brew install icarus-verilog`

[Видео инструкция по установке Icarus Verilog на MacOS](https://youtu.be/jUYkYoYr8hs)


[![](https://img.youtube.com/vi/jUYkYoYr8hs/hqdefault.jpg)](https://www.youtube.com/watch?v=jUYkYoYr8hs)


## Выполнение и проверка заданий

Для проверки задач под Linux и MacOS, необходимо открыть консоль в папке с заданиями и запустить скрипт `./run_all_using_iverilog_under_linux_or_macos_brew.sh`. Он создаст файл _log.txt_ с результатами компиляции и симуляции всех задач набора.

Для проверки задач под Windows необходимо открыть консоль в папке с заданиями и запустить пакетный файл `run_all_using_iverilog_under_windows.bat`. Он так же создаст файл _log.txt_ с результатами проверки.

После того, как тест для всех задачек покажет **PASS**, вы можете передать его на проверку преподавателю.

## Рекомендуемая литература, которая поможет в решении задач

<!-- Особенность формата Markdown что списки нумеруются автоматически, поэтому для форматирования "как список" используют последовательность "1." -->

1. [Харрис Д.М., Харрис С.Л., «Цифровая схемотехника и архитектура компьютера: RISC-V»](https://dmkpress.com/catalog/electronics/circuit_design/978-5-97060-961-3). К ней есть [версия для планшета для предыдущего издания](https://silicon-russia.com/public_materials/2018_01_15_latest_harris_harris_ru_barabanov_version/digital_design_rus-25.10.2017.pdf) (на основе архитектуры MIPS), а к той есть более короткие [слайды для лекций](http://www.silicon-russia.com/public_materials/2016_09_01_harris_and_harris_slides/DDCA2e_LectureSlides_Ru_20160901.zip).
![](https://habrastorage.org/r/w1560/getpro/habr/upload_files/26c/817/9c3/26c8179c34c52fa937cd2200f789c3d0.png)

1. [Романов А.Ю., Панчул Ю.В. и коллектив авторов. «Цифровой синтез. Практический курс»](https://dmkpress.com/catalog/electronics/circuit_design/978-5-97060-850-0/)
