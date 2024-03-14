@echo off

for /d %%d in (*) do (
    echo %%d
    cd %%d

    if exist run_using_iverilog_under_windows.bat (
        call run_using_iverilog_under_windows.bat
    ) else (
        call run_all_using_iverilog_under_windows.bat
    )

    cd ..
)
