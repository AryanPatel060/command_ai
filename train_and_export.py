import os
import torch
import torch.nn as nn

# Standardized vocabulary matching C++
VOCAB_CHARS = " -abcdefghijklmnopqrstuvwxyz0123456789./_:-+=@#$%^&*()<>{}[]\"'"
char2idx = {ch: i for i, ch in enumerate(VOCAB_CHARS)}
vocab_size = len(VOCAB_CHARS)

# 1. Load dataset from commands.txt
commands_file = "commands.txt"
if os.path.exists(commands_file):
    with open(commands_file, "r") as f:
        dataset = [line.strip().lower() for line in f if line.strip()]
else:
    dataset = ["git status", "git commit -m", "ls -la"]

class CharLSTM(nn.Module):
    def __init__(self, vocab_size, hidden_dim=64):
        super().__init__()
        self.embed = nn.Embedding(vocab_size, 16)
        self.lstm = nn.LSTM(16, hidden_dim, batch_first=True)
        self.fc = nn.Linear(hidden_dim, vocab_size)

    def forward(self, x):
        x = self.embed(x)
        out, _ = self.lstm(x)
        return self.fc(out[:, -1, :])

model = CharLSTM(vocab_size)
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

# 2. Train model on command patterns
print(f"Training model on {len(dataset)} commands from {commands_file}...")
for epoch in range(120):
    for cmd in dataset:
        for i in range(1, len(cmd)):
            input_seq = torch.tensor([[char2idx.get(c, 0) for c in cmd[:i]]], dtype=torch.long)
            target = torch.tensor([char2idx.get(cmd[i], 0)], dtype=torch.long)
            
            optimizer.zero_grad()
            output = model(input_seq)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()

# 3. Export model to ONNX
model.eval()
dummy_input = torch.tensor([[char2idx['g'], char2idx['i']]], dtype=torch.long)
torch.onnx.export(
    model, dummy_input, "command_lstm.onnx",
    input_names=["input_seq"], output_names=["output_logits"],
    dynamic_axes={"input_seq": {1: "seq_length"}}
)
print("Model saved successfully as command_lstm.onnx")