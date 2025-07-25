#!/bin/bash


pip install uv
pip install --upgrade pip
uv init || true
uv sync