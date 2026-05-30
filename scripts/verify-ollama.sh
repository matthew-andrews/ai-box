#!/usr/bin/env bash
set -e
echo "Testing connectivity..."
curl -sf "$OLLAMA_HOST/api/tags" >/dev/null
echo "Installed models:"
ollama list
echo
echo "Running models:"
ollama ps
echo
echo "Verification successful."
