import torch
import torch.nn as nn
import torch.nn.functional as F

class ResidualBlock(nn.Module):
    def __init__(self, in_channels, out_channels, stride=1, downsample=None):
        super(ResidualBlock, self).__init__()
        self.conv1 = nn.Conv2d(in_channels, out_channels, kernel_size=3, stride=stride, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(out_channels)
        self.relu = nn.ReLU(inplace=True)
        self.conv2 = nn.Conv2d(out_channels, out_channels, kernel_size=3, stride=1, padding=1, bias=False)
        self.bn2 = nn.BatchNorm2d(out_channels)
        self.downsample = downsample

    def forward(self, x):
        residual = x
        out = self.relu(self.bn1(self.conv1(x)))
        out = self.bn2(self.conv2(out))
        if self.downsample:
            residual = self.downsample(x)
        out += residual
        out = self.relu(out)
        return out

class RDNet(nn.Module):
    def __init__(self, num_face=2, num_dist=2, num_mask=2):
        super(RDNet, self).__init__()

        self.in_channels = 64
        self.conv1 = nn.Conv2d(1, self.in_channels, kernel_size=3, stride=2, padding=1)
        self.bn1 = nn.BatchNorm2d(self.in_channels)
        self.relu = nn.ReLU(inplace=True)

        # Adding more depth with Residual Blocks
        self.layer1 = self._make_layer(128, stride=2)
        self.layer2 = self._make_layer(256, stride=2)
        self.layer3 = self._make_layer(512, stride=2)
        self.drop = nn.Dropout(p=0.3)

        self.adaptivePool = nn.AdaptiveAvgPool2d((1, 1))

        # Increase model capacity in fully connected layers
        self.face_fc1 = nn.Linear(512, 2048)
        self.face_fc2 = nn.Linear(2048, 2048)
        self.face_fc3 = nn.Linear(2048, 1024)
        self.face_fc4 = nn.Linear(1024, 1024)
        self.face_fc5 = nn.Linear(1024, 1024)
        self.face_fc6 = nn.Linear(1024, 1024)
        self.face_fc7 = nn.Linear(1024, 1024)
        self.face_fc8 = nn.Linear(1024, 512)
        self.face_fc9 = nn.Linear(512, 512)
        self.face_fc10 = nn.Linear(512, num_face)

        self.dist_fc1 = nn.Linear(512 + num_face, 256)
        self.dist_fc2 = nn.Linear(256, 256)
        self.dist_fc3 = nn.Linear(256, 256)
        self.dist_fc4 = nn.Linear(256, 128)
        self.dist_fc5 = nn.Linear(128, num_dist)

        self.mask_fc1 = nn.Linear(512 + num_face, 256)
        self.mask_fc2 = nn.Linear(256, 256)
        self.mask_fc3 = nn.Linear(256, 256)
        self.mask_fc4 = nn.Linear(256, 128)
        self.mask_fc5 = nn.Linear(128, num_mask)

    def _make_layer(self, out_channels, stride=1):
        downsample = None
        if stride != 1 or self.in_channels != out_channels:
            downsample = nn.Sequential(
                nn.Conv2d(self.in_channels, out_channels, kernel_size=1, stride=stride, bias=False),
                nn.BatchNorm2d(out_channels),
            )
        layer = ResidualBlock(self.in_channels, out_channels, stride, downsample)
        self.in_channels = out_channels
        return layer

    def forward(self, x):
        x = self.relu(self.bn1(self.conv1(x)))

        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)

        x = self.drop(x)
        x = self.adaptivePool(x)
        x_cnn_output = x.view(x.size(0), -1)

        x_face = F.relu(self.face_fc1(x_cnn_output))
        x_face = F.relu(self.face_fc2(x_face))
        x_face = F.relu(self.face_fc3(x_face))
        x_face = F.relu(self.face_fc4(x_face))
        x_face = F.relu(self.face_fc5(x_face))
        x_face = F.relu(self.face_fc6(x_face))
        x_face = F.relu(self.face_fc7(x_face))
        x_face = F.relu(self.face_fc8(x_face))
        x_face = F.relu(self.face_fc9(x_face))
        x_face_output = torch.sigmoid(self.face_fc10(x_face))

        x_dist_input = torch.cat((x_cnn_output, x_face_output), 1)
        x_dist = F.relu(self.dist_fc1(x_dist_input))
        x_dist = F.relu(self.dist_fc2(x_dist))
        x_dist = F.relu(self.dist_fc3(x_dist))
        x_dist = F.relu(self.dist_fc4(x_dist))
        x_dist_output = torch.sigmoid(self.dist_fc5(x_dist))

        x_mask_input = torch.cat((x_cnn_output, x_face_output), 1)
        x_mask = F.relu(self.mask_fc1(x_mask_input))
        x_mask = F.relu(self.mask_fc2(x_mask))
        x_mask = F.relu(self.mask_fc3(x_mask))
        x_mask = F.relu(self.mask_fc4(x_mask))
        x_mask_output = torch.sigmoid(self.mask_fc5(x_mask))

        return [x_face_output, x_dist_output, x_mask_output]

model = RDNet().to(device)

# Calculate total parameters and model size in bytes
param_size = sum(p.numel() * p.element_size() for p in model.parameters())
buffer_size = sum(b.numel() * b.element_size() for b in model.buffers())
total_size = param_size + buffer_size


