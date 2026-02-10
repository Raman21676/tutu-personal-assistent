# Local AI Models

This directory contains the local LLM models for TuTu.

## Included Model

**SmolLM2-360M-Instruct-Q4_K_M.gguf**
- Size: ~258 MB
- Parameters: 360M
- Quantization: Q4_K_M (4-bit)
- Format: GGUF (llama.cpp compatible)
- License: Apache 2.0

## Download

The model is bundled with the app release. If you need to download it separately:

```bash
# Download from HuggingFace
wget https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/SmolLM2-360M-Instruct-Q4_K_M.gguf
```

## Additional Models

You can add more GGUF models to this directory:
- SmolLM2-1.7B-Instruct (~1GB)
- Phi-2 (~1.6GB)
- TinyLlama-1.1B (~600MB)

Place any `.gguf` file here and it will be available in the Model Manager.

## Git LFS

Due to file size limits, models are tracked with Git LFS:

```bash
# Install Git LFS
git lfs install

# Track model files
git lfs track "*.gguf"
```
