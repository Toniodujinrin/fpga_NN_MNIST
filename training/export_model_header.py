import argparse
from pathlib import Path


LAYERS = ((1, 64, 784), (2, 64, 64), (3, 10, 64))


def read_signed_binary(path: Path, width: int) -> list[int]:
    values = []
    for line in path.read_text(encoding="ascii").splitlines():
        raw = int(line.strip(), 2)
        if raw & (1 << (width - 1)):
            raw -= 1 << width
        values.append(raw)
    return values


def format_array(name: str, c_type: str, values: list[int]) -> str:
    lines = []
    for offset in range(0, len(values), 12):
        lines.append("    " + ", ".join(str(value) for value in values[offset:offset + 12]))
    return f"static const {c_type} {name}[{len(values)}] = {{\n" + ",\n".join(lines) + "\n};\n"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Convert model .mem files to a Nios C header")
    parser.add_argument(
        "--output",
        type=Path,
        default=project_root / "software/app/model_data.h",
    )
    args = parser.parse_args()

    weights = []
    biases = []
    for layer, neurons, inputs in LAYERS:
        for neuron in range(neurons):
            path = project_root / f"weights/weight_file_layer_{layer}_neuron_{neuron}.mem"
            values = read_signed_binary(path, 16)
            if len(values) != inputs:
                raise ValueError(f"{path} contains {len(values)} weights, expected {inputs}")
            weights.extend(values)

    for layer, neurons, _ in LAYERS:
        for neuron in range(neurons):
            path = project_root / f"biases/bias_file_layer_{layer}_neuron_{neuron}.mem"
            values = read_signed_binary(path, 32)
            if len(values) != 1:
                raise ValueError(f"{path} must contain one bias")
            biases.extend(values)

    text = """#ifndef MODEL_DATA_H
#define MODEL_DATA_H

#include <stdint.h>

"""
    text += format_array("model_weights", "int16_t", weights) + "\n"
    text += format_array("model_biases", "int32_t", biases)
    text += "\n#endif\n"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="ascii")
    print(f"Wrote {len(weights)} weights and {len(biases)} biases to {args.output}")


if __name__ == "__main__":
    main()
