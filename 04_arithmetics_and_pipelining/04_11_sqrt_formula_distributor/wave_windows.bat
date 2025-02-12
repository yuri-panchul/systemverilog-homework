@echo off

if not exist "C:\Program Files\Git\bin\bash.exe" (
    echo "Starting from Homework 3, this Windows batch script invokes"
    echo "a Bash shell interpreter from the Git for Windows package."
    echo "This is necessary for more flexible checking of the results."
    echo "Please install Git for Windows from https://gitforwindows.org/ and re-run this batch again."

    exit /b
)

"C:\Program Files\Git\bin\bash.exe" run_linux_mac.sh --wave
