#!/usr/bin/env bash

pandoc --pdf-engine=wkhtmltopdf \
--pdf-engine-opt=--enable-local-file-access \
--css=../pdf.css \
--metadata title="Verilog Interview 41-45. $(date '+%Y-%m-%d')" \
*.md \
-o mock_interview_41_55_$(date '+%Y%m%d').pdf
