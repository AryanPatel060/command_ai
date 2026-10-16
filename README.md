# CommandAI — On-Device Terminal Autocomplete

**CommandAI** is a lightweight, local AI autocomplete engine for Zsh. It uses a character-level LSTM neural network trained in PyTorch, exported to ONNX, and executed in high-performance C++ using ONNX Runtime.

## 🌟 Key Features

* **Non-blocking Native Tab Completion:** `Tab` retains 100% default Zsh and Git autocompletion (branches, filenames, options).
* **Fast C++ Inference:** Runs predictions using ONNX Runtime C++ API directly within the terminal line editor (`ZLE`).
* **Clean Visual Ghost Text:** Renders suggestions inline using Zsh native `region_highlight` without ANSI color corruption.
* **Single-Command Retraining:** Add custom commands to a text file and retrain the model with `make model && make install`.
* **Zero Cloud Dependencies:** Runs completely offline on your local CPU.

## ⌨️ Recommended Terminal Workflow

| Action | Shortcut / Key | Description |
| :--- | :--- | :--- |
| **Accept AI Suggestion** | `Right Arrow` (`→`) or `Ctrl+F` | Appends the gray ghost text to your active prompt. |
| **Native Zsh Completion** | `Tab` | Triggers standard Git branch, flag, or file/folder completion. |
| **Dismiss Suggestion** | `Esc` | Clears the visible ghost text suggestion. |
| **Trigger Suggestion** | *Automatic* | Suggestions update in real-time as you type. |

## 📂 Project Structure

```
autocommand/
├── commands.txt          # Raw dataset: list of shell commands (one per line)
├── train_and_export.py   # PyTorch LSTM trainer & ONNX exporter
├── main.cpp              # C++ ONNX Runtime inference engine
├── Makefile              # Automation script for building and installing
├── install.sh            # Automated installer script
└── README.md             # Project documentation
```

## 🛠️ Prerequisites

Ensure your system has the following tools installed:

1. **C++ Compiler:** `g++` with C++17 support.
2. **Python 3:** With `torch` and `onnx` packages installed in your active environment:
   ```bash
   pip install torch onnx
   ```
3. **ONNX Runtime C++ Library:** Extracted into `$HOME/onnxruntime/` containing `include/` and `lib/` subdirectories.

## 🚀 Installation & Setup

### 1. Clone or Open Project Directory

```bash
cd ~/autocommand
```

### 2. Core Project Files

* **`commands.txt`**: List of custom CLI commands (one per line) used to train the LSTM model.
* **`train_and_export.py`**: Python script that trains the character-level model on `commands.txt` and exports `command_lstm.onnx`.
* **`main.cpp`**: High-performance C++ program that loads the `.onnx` model and outputs character completions instantly.
* **`Makefile`**: Handles model training, C++ compilation, and installing binaries into `~/bin/` and `~/.autocommand/`.
* **`install.sh`**: One-click installer script that runs `make` and binds the ghost-text widgets inside `~/.zshrc`.

### 3. Build & Install

Run the automated installer script:

```bash
chmod +x install.sh
./install.sh
source ~/.zshrc
```

## 🔄 How to Update Commands & Retrain

When you want to add new commands or retrain the model on updated workflows:

1. Edit `commands.txt` and append your new command strings:
   ```bash
   nano commands.txt
   ```

2. Re-train and publish the updated model in a single command:
   ```bash
   make model && make install
   ```

3. Your terminal will immediately start serving predictions from the newly trained model!

## ⚡ Troubleshooting

* **Error loading `.onnx.data` file:** Ensure `cp command_lstm.onnx* $(HOME)/.autocommand/` is used in your `Makefile` so binary companion weights are included.
* **`Tab` key conflict:** `Tab` is left untouched so native Zsh completion works out of the box. Use `Right Arrow` or `Ctrl+F` to accept AI ghost text.