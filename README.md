# musubi-tuner-collab

Google Colab notebooks for LoRA training with [musubi-tuner](https://github.com/kohya-ss/musubi-tuner) by kohya-ss.

---

## Notebooks

### FLUX.2\[klein\] 9B — LoRA Training *(primary)*

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/sruckh/musubi-tuner-collab/blob/main/musubi_tuner_flux2_klein_9b_colab.ipynb)

Train a LoRA for **FLUX.2-klein-9B** (Black Forest Labs) — a fast, high-quality image generation and editing model.

| | |
|---|---|
| **Model** | [black-forest-labs/FLUX.2-klein-9B](https://huggingface.co/black-forest-labs/FLUX.2-klein-9B) |
| **Task** | Image generation / image editing |
| **GPU** | A100 40 GB recommended |
| **Access** | Gated — HuggingFace token required |
| **Inference steps** | 4 (distilled) |

**Requirements before opening:**
1. Accept license at [FLUX.2-klein-9B](https://huggingface.co/black-forest-labs/FLUX.2-klein-9B) and [FLUX.2-dev](https://huggingface.co/black-forest-labs/FLUX.2-dev)
2. Create a [HuggingFace token](https://huggingface.co/settings/tokens) with Read access
3. Add it to Colab Secrets as `HF_TOKEN`

---

### Multi-Architecture — LoRA Training

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/sruckh/musubi-tuner-collab/blob/main/musubi_tuner_lora_colab.ipynb)

Train a LoRA for **Wan2.1** (T2V 1.3B / 14B, I2V) or **HunyuanVideo**.

| Architecture | Task | Min VRAM |
|---|---|---|
| Wan2.1 T2V 1.3B | Image or video LoRA | 12 GB (T4) |
| Wan2.1 T2V/I2V 14B | Image or video LoRA | 24 GB |
| HunyuanVideo | Image or video LoRA | 16 GB (fp8 + swap) |

---

## Quick Start

1. Click an **Open in Colab** badge above
2. **Runtime → Change runtime type → GPU** (A100 for FLUX.2, T4 for Wan2.1 1.3B)
3. Follow the numbered sections top-to-bottom
4. Edit **Section 6 — Configuration** for your dataset and training preferences

## Dataset Format

Each notebook expects images with matching caption text files:

```
dataset/
├── image001.jpg
├── image001.txt    ← "a photo of sks person smiling"
├── image002.png
├── image002.txt
└── ...
```

Upload to Google Drive — paths are configured in each notebook.

## Model Storage

All model weights are downloaded to Google Drive and reused across Colab sessions.
Approximate storage requirements:

| Model | Size |
|---|---|
| FLUX.2-klein-9B (DiT + TE + AE) | ~34 GB |
| Wan2.1 1.3B (DiT + VAE + T5) | ~15 GB |
| Wan2.1 14B (DiT + VAE + T5) | ~40 GB |

## Credits

- **musubi-tuner** — [kohya-ss](https://github.com/kohya-ss/musubi-tuner)
- **FLUX.2** — [Black Forest Labs](https://blackforestlabs.ai/)
- **Wan2.1** — [Wan-Video](https://github.com/Wan-Video/Wan2.1)
- **HunyuanVideo** — [Tencent](https://github.com/Tencent/HunyuanVideo)

## License

Notebooks in this repository are released under the Apache License 2.0.
Model weights are subject to their respective licenses — see each model's Hugging Face page.
