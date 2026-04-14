#!/bin/bash
#
# Downloads and exports a HuggingFace multilingual NER model to ONNX format.
# Requires Python 3.8+ with pip.
#
# Output: data/opennlpmodels-onnx/ner-multilingual/
#   model.onnx        - The ONNX model
#   vocab.txt          - Vocabulary file for WordPiece tokenizer
#   id2labels.json     - Label index to entity type mapping
#
set -e

MODEL_NAME="Davlan/xlm-roberta-base-ner-hrl"
OUTPUT_DIR="data/opennlpmodels-onnx/ner-multilingual"

# Skip if already exported
if [ -f "$OUTPUT_DIR/model.onnx" ]; then
    echo "ONNX model already exists at $OUTPUT_DIR/model.onnx — skipping."
    exit 0
fi

# Check Python3
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required. Install Python 3.8+ and try again."
    exit 1
fi

echo "=== Installing Python dependencies ==="
python3 -m pip install --quiet --upgrade pip
python3 -m pip install --quiet "optimum>=1.17" "optimum[onnxruntime]" "transformers" "onnx" "onnxruntime" "sentencepiece"

echo "=== Exporting $MODEL_NAME to ONNX ==="
mkdir -p "$OUTPUT_DIR"

# Export model to ONNX via optimum-cli
python3 -m optimum.exporters.onnx \
    --model "$MODEL_NAME" \
    --task token-classification \
    "$OUTPUT_DIR/"

# Rename the output model if needed (optimum may produce model.onnx directly)
if [ ! -f "$OUTPUT_DIR/model.onnx" ] && [ -f "$OUTPUT_DIR/onnx/model.onnx" ]; then
    mv "$OUTPUT_DIR/onnx/model.onnx" "$OUTPUT_DIR/model.onnx"
fi

# Extract vocab.txt and id2labels.json from the HuggingFace model
python3 -c "
import json
from transformers import AutoTokenizer, AutoConfig

print('Extracting vocab and labels...')
config = AutoConfig.from_pretrained('$MODEL_NAME')
tokenizer = AutoTokenizer.from_pretrained('$MODEL_NAME')

# Save id2labels mapping
id2labels = {int(k): v for k, v in config.id2label.items()}
with open('$OUTPUT_DIR/id2labels.json', 'w') as f:
    json.dump(id2labels, f, indent=2)
print(f'  id2labels.json: {len(id2labels)} labels')

# Save vocabulary (one token per line, ordered by ID)
vocab = tokenizer.get_vocab()
sorted_vocab = sorted(vocab.items(), key=lambda x: x[1])
with open('$OUTPUT_DIR/vocab.txt', 'w') as f:
    for token, idx in sorted_vocab:
        f.write(token + '\n')
print(f'  vocab.txt: {len(sorted_vocab)} tokens')
print('Done.')
"

echo ""
echo "=== ONNX model exported to $OUTPUT_DIR ==="
ls -lh "$OUTPUT_DIR/model.onnx" "$OUTPUT_DIR/vocab.txt" "$OUTPUT_DIR/id2labels.json"
