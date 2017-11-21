#!/bin/bash
echo "[Options:OpenCL]" >> $HOME/john.conf && \
echo "AutotuneLWS = 1" >> $HOME/john.conf && \
cp -r /usr/share/johntheripper/kernels/ $HOME/