#!/usr/bin/env bash

pandoc --pdf-engine=wkhtmltopdf \
--pdf-engine-opt=--enable-local-file-access \
--css=pdf.css \
--metadata title="Verilog Interview 01-05. $(date '+%Y-%m-%d')" \
*.md \
-o mock_interview_01_05_$(date '+%Y%m%d').pdf
