import torch
import torch.nn as nn

# 1. Standardized vocabulary matching C++
VOCAB_CHARS = " -abcdefghijklmnopqrstuvwxyz0123456789"
char2idx = {ch: i for i, ch in enumerate(VOCAB_CHARS)}
vocab_size = len(VOCAB_CHARS)  # 38

dataset = [
    "git status", "git commit -m", "git checkout", 
    "cd Documents", "ls -la", "docker ps", "sta"
]

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

# 2. Train model briefly so it learns patterns
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

for epoch in range(100):
    for cmd in dataset:
        for i in range(1, len(cmd)):
            input_seq = torch.tensor([[char2idx.get(c, 0) for c in cmd[:i]]], dtype=torch.long)
            target = torch.tensor([char2idx.get(cmd[i], 0)], dtype=torch.long)
            
            optimizer.zero_grad()
            output = model(input_seq)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()

# 3. Export with full vocabulary size
model.eval()
dummy_input = torch.tensor([[char2idx['g'], char2idx['i']]], dtype=torch.long)
torch.onnx.export(
    model, dummy_input, "command_lstm.onnx",
    input_names=["input_seq"], output_names=["output_logits"],
    dynamic_axes={"input_seq": {1: "seq_length"}}
)
print(f"Model exported successfully with vocab size {vocab_size}!")