import torch 
import torch.nn as nn 
import torchvision
import torchvision.transforms as transforms
import os
import numpy as np


class MNISTNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784,64)
        self.fc2 = nn.Linear(64,64)
        self.fc3 = nn.Linear(64,10)
        self.relu = nn.ReLU()
        
    def forward(self,x):
        x = x.view(-1,784)
        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))
        x = self.fc3(x)
        return x 


transform = transforms.ToTensor()

trainset = torchvision.datasets.MNIST(
        root = './data', 
        train = True, 
        download = True, 
        transform = transform 
)

trainloader = torch.utils.data.DataLoader(
        trainset, 
        batch_size = 64, 
        shuffle = True
)

model = MNISTNet()
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr = 0.01)


epochs = 5
for epoch in range(epochs):
    running_loss = 0 
    for images, labels in trainloader: 
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward() 
        optimizer.step()
        running_loss += loss.item()
    print(f"Epoch {epoch+1}: {running_loss}")

for name, param in model.named_parameters():
    print(name, param.shape)

SCALE = 256

os.makedirs("weights", exist_ok=True)
os.makedirs("biases",exist_ok=True)

# ==================================================
# EXPORT FUNCTION
# ==================================================

SCALE_FRAC = 8                    
SCALE_WEIGHT = 1 << SCALE_FRAC      # 16384
SCALE_BIAS   = 1 << (2 * SCALE_FRAC)  # 268435456  (x*w scaling)

def export_layer_weights(weights, layer_num):
    weights_np = weights.detach().numpy()
    weights_fixed = np.round(weights_np * SCALE_WEIGHT).astype(np.int16)
    os.makedirs("weights", exist_ok=True)
    for neuron_idx, row in enumerate(weights_fixed):
        filename = f"weights/weight_file_layer_{layer_num}_neuron_{neuron_idx}.mem"
        with open(filename, "w") as f:
            for value in row:
                val = int(value)                    # ← force Python int (unlimited)
                # proper saturation for signed 16-bit Q1.14
                val = max(-32768, min(32767, val))
                binary_string = f"{val & 0xFFFF:016b}"
                f.write(binary_string + "\n")

def export_layer_biases(biases, layer_num):
    bias_np = biases.detach().numpy()
    bias_fixed = np.round(bias_np * SCALE_BIAS).astype(np.int32)
    os.makedirs("biases", exist_ok=True)
    for neuron_idx, item in enumerate(bias_fixed):
        filename = f"biases/bias_file_layer_{layer_num}_neuron_{neuron_idx}.mem"
        with open(filename, "w") as f:
            val = int(item)                         # ← force Python int
            # proper saturation for signed 32-bit
            val = max(-2147483648, min(2147483647, val))
            binary_string = f"{val & 0xFFFFFFFF:032b}"
            f.write(binary_string + "\n")
# EXPORT ALL LAYERS
# ==================================================

export_layer_weights(model.fc1.weight, 1)
export_layer_weights(model.fc2.weight, 2)
export_layer_weights(model.fc3.weight, 3)

export_layer_biases(model.fc1.bias,1)
export_layer_biases(model.fc2.bias,2)
export_layer_biases(model.fc3.bias,3)


def export_mnist_sample_to_mif(index=0):
    # 1. Load the MNIST test set (don't train on this, just grab one)
    testset = torchvision.datasets.MNIST(
        root='./data', 
        train=False, 
        download=True, 
        transform=transforms.ToTensor()
    )
    
    # 2. Get a single image and label
    image, label = testset[index] # image is [1, 28, 28] tensor
    print(f"Exporting index {index} (Label: {label})")
    
    # 3. Reshape and normalize (to 0-255 scale to match your pixelizer)
    img_data = image.squeeze().numpy() * 255.0
    
    # 4. Save to input_1.mif
    # We reuse your existing logic concept:
    # 1024 is the multiplier for your Q5.10 fixed point
    SCALE = 1 << 10 
    
    with open("input_1.mif", "w") as f:
        for row in img_data:
            for pixel in row:
                # Normalize 0-1
                normalized = pixel / 255.0
                # Convert to fixed point
                fixed = int(round(normalized * SCALE))
                # Clamp
                fixed = max(0, min(fixed, 65535))
                # Write to file
                f.write(f"{fixed & 0xFFFF:016b}\n")
    
    print("Export complete: input_1.mif created.")

# Run it
if __name__ == "__main__":
    export_mnist_sample_to_mif(index=77) # Change index for different images
