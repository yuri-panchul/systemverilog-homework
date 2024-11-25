#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

#-----------------------------------------------------------------------------

if ! [ -d import/original/cvw ]
then
    mkdir -p import/original
    cd       import/original

    git clone --depth 1 https://github.com/openhwgroup/cvw.git
    cd ../..
fi

rm    -rf import/preprocessed
mkdir -p  import/preprocessed/cvw

cp -r  \
   import/original/cvw/config/rv32gc/config.vh  \
   import/original/cvw/config/shared/BranchPredictorType.vh  \
   import/original/cvw/config/shared/config-shared.vh  \
   import/original/cvw/src/fpu/*/*  \
   import/original/cvw/src/fpu/*.*  \
   import/original/cvw/src/generic/*.* \
   import/original/cvw/src/generic/flop/*.* \
   import/preprocessed/cvw

cd import/preprocessed/cvw

sed -i 's/import cvw::\*;  #(parameter cvw_t P) //g' *
sed -i 's/module fmalza #(WIDTH, NF) /module fmalza #(parameter WIDTH = 0, NF = 0) /g' fmalza.sv
sed -i 's/#(P) //g' *
sed -i 's/P\./  /g' *

exit



script_path="$0"
script=$(basename "$script_path")
script_dir=$(dirname "$script_path")

run_dir="$PWD"
cd "$script_dir"

pkg_src_root=$(readlink -e .)
pkg_src_root_name=$(basename "$pkg_src_root")

#-----------------------------------------------------------------------------

error ()
{
    # Note: this printf fails if the arguments contain filenames
    # with "%" characters inside.
    #
    # The alternative would be to put:
    #
    #     printf "\n$script: ERROR: %s\n" "$*" 1>&2
    #
    # But this does not work well too,
    # it prints "\n" as "\n" instead of a newline.

    printf "\n$script: ERROR: $*\n" 1>&2
    exit 1
}

#-----------------------------------------------------------------------------

f=$(git diff --name-status --diff-filter=R HEAD "$pkg_src_root")

if [ -n "${f-}" ]
then
    error "there are renamed files in the tree."                            \
          "\nYou should check them in before preparing a release package."  \
          "\nSpecifically:\n\n$f"
fi

f=$(git ls-files --others --exclude-standard "$pkg_src_root")

if [ -n "${f-}" ]
then
    error "there are untracked files in the tree."             \
          "\nYou should either remove or check them in"        \
          "before preparing a release package."                \
          "\nSpecifically:\n\n$f"                              \
          "\n\nYou can also see the file list by running:"     \
          "\n    (cd \"$pkg_src_root\" ; git clean -d -n)"     \
          "\n\nAfter reviewing (be careful!),"                 \
          "you can remove them by running:"                    \
          "\n    (cd \"$pkg_src_root\" ; git clean -d -f)"     \
          "\n\nNote that \"git clean\" without \"-x\" option"  \
          "does not see the files from the .gitignore list."
fi

f=$(git ls-files --others "$pkg_src_root")

if [ -n "${f-}" ]
then
    error "there are files in the tree, ignored by git,"                   \
          "based on .gitignore list."                                      \
          "\nThis repository is not supposed to have the ignored files."   \
          "\nYou need to remove them before preparing a release package."  \
          "\nSpecifically:\n\n$f"                                          \
          "\n\nYou can also see the file list by running:"                 \
          "\n    (cd \"$pkg_src_root\" ; git clean -d -x -n)"              \
          "\n\nAfter reviewing (be careful!),"                             \
          "you can remove them by running:"                                \
          "\n    (cd \"$pkg_src_root\" ; git clean -d -x -f)"
fi

f=$(git ls-files --modified "$pkg_src_root")

if [ -n "${f-}" ]
then
    error "there are modified files in the tree."                           \
          "\nYou should check them in before preparing a release package."  \
          "\nSpecifically:\n\n$f"
fi

#-----------------------------------------------------------------------------

# Search for the text files with DOS/Windows CR-LF line endings

# -r     - recursive
# -l     - file list
# -q     - status only
# -I     - Ignore binary files
# -U     - don't strip CR from text file by default
# $'...' - string literal in Bash with C semantics ('\r', '\t')

if [ "$OSTYPE" = linux-gnu ] && grep -rqIU $'\r$' "$pkg_src_root"/*
then
    grep -rlIU $'\r$' "$pkg_src_root"/*

    error "there are text files with DOS/Windows CR-LF line endings." \
          "You can fix them by doing:" \
          "\ngrep -rlIU \$'\\\\r\$' \"$pkg_src_root\"/* | xargs dos2unix"
fi

# For some reason "--exclude=\*.mk" does not work here

exclude_space_ok="--exclude-dir=urgReport --exclude=*.xdc"
exclude_tabs_ok="$exclude_space_ok --exclude=*.mk"

if grep -rqI $exclude_tabs_ok $'\t' "$pkg_src_root"/*
then
    grep -rlI $exclude_tabs_ok $'\t' "$pkg_src_root"/*

    error "there are text files with tabulation characters." \
          "\nTabs should not be used." \
          "\nDevelopers should not need to configure the tab width" \
          " of their text editors in order to be able to read source code." \
          "\nPlease replace the tabs with spaces" \
          "before checking in or creating a package." \
          "\nYou can find them by doing:" \
          "\ngrep -rlI $exclude_tabs_ok \$'\\\\t' \"$pkg_src_root\"/*" \
          "\nYou can fix them by doing the following," \
          "but make sure to review the fixes:" \
          "\ngrep -rlI $exclude_tabs_ok \$'\\\\t' \"$pkg_src_root\"/*" \
          "| xargs sed -i 's/\\\\t/    /g'"
fi

if grep -rqI $exclude_space_ok '[[:space:]]\+$' "$pkg_src_root"/*
then
    grep -rlI $exclude_space_ok '[[:space:]]\+$' "$pkg_src_root"/*

    error "there are spaces at the end of line, please remove them." \
          "\nYou can fix them by doing:" \
          "\ngrep -rlI $exclude_space_ok '[[:space:]]\\\\+\$' \"$pkg_src_root\"/*" \
          "| xargs sed -i 's/[[:space:]]\\\\+\$//g'"
fi

#-----------------------------------------------------------------------------

# A workaround for a find problem when running bash under Microsoft Windows

find_to_run=find
true_find=/usr/bin/find

if [ -x "$true_find" ]
then
    find_to_run="$true_find"
fi

#-----------------------------------------------------------------------------

tgt_pkg_dir=$(mktemp -d)
package=${pkg_src_root_name}_$(date '+%Y%m%d')
package_path="$tgt_pkg_dir/$package"

mkdir "$package_path"

cp -r "$pkg_src_root"/* "$pkg_src_root"/.gitignore "$pkg_src_root"/.lint_rules.vlt "$package_path"
rm -rf "$package_path"/old
rm -rf "$package_path"/01_prepare_public_package.bash
rm -rf "$package_path"/02_update_public_homework.bash

# TODO - remove this later
rm -rf "$package_path"/0x_gearboxes "$package_path"/0x_interconnect

$find_to_run "$package_path" -name '*.sv'  \
    | xargs -n 1 sed -i '/START_SOLUTION/,/END_SOLUTION/d'

$find_to_run "$package_path" -name '*.svh'  \
    | xargs -n 1 sed -i '/START_SOLUTION/,/END_SOLUTION/d'

#-----------------------------------------------------------------------------

if ! command -v zip &> /dev/null
then
    printf "$script: cannot find zip utility"

    if [ "$OSTYPE" = "msys" ]
    then
        printf "\n$script: download zip for Windows from https://sourceforge.net/projects/gnuwin32/files/zip/3.0/zip-3.0-setup.exe/download"
        printf "\n$script: then add zip to the path: %s" '%PROGRAMFILES(x86)%\GnuWin32\bin'
    fi

    exit 1
fi

#-----------------------------------------------------------------------------

rm -rf "$run_dir/$pkg_src_root_name"_*.zip

cd "$tgt_pkg_dir/$package"
zip -r "$run_dir/$package.zip" .
