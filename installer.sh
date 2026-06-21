#!/bin/bash

echo "Building LangProxy..."

go mod tidy
go build -o LangProxy .

chmod +x LangProxy

echo "[OK] Build complete"
echo "Run: ./LangProxy"
