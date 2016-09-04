#!/bin/bash
# create multiresolution windows icon
ICON_DST=../../src/qt/res/icons/NoLimitCoin.ico

convert ../../src/qt/res/icons/NoLimitCoin-16.png ../../src/qt/res/icons/NoLimitCoin-32.png ../../src/qt/res/icons/NoLimitCoin-48.png ${ICON_DST}
