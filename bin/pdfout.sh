#!/bin/sh
#
# This script is invoked from the controller (gallery_controller.rb)
# No check because the controller checks it.

LIBREOFFICE=`which libreoffice`

$LIBREOFFICE --nologo --headless --nofirststartwizard --convert-to pdf --outdir public/pdf public/$1
