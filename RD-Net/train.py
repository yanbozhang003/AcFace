import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader

class Trainer:
    def __init__(self, model, data_loader, device):
        self.model = model
        self.data_loader = data_loader
        self.device = device
        self.train_cost = []
        self.train_accu = []

        self.learning_rate = 0.000001
        self.criterion = nn.CrossEntropyLoss()
        self.optimizer = optim.Adam(self.model.parameters(), lr=self.learning_rate)
        self.training_epochs = 80

    def train(self):
        total_batch = len(self.data_loader.dataset) // self.data_loader.batch_size
        print('Batch size is : {}'.format(self.data_loader.batch_size))
        print('Total number of batches is : {0:2.0f}'.format(total_batch))
        print('Total number of epochs is : {0:2.0f}'.format(self.training_epochs))

        for epoch in range(self.training_epochs):
            avg_cost = 0
            total_batches = 0
            for i, (batch_X, batch_Y, sample_ids) in enumerate(self.data_loader):
                total_batches += 1

                face_Y, dist_Y, mask_Y = self._prepare_labels(batch_Y)

                X = batch_X.to(self.device)
                face_Y = torch.LongTensor(face_Y).to(self.device)
                dist_Y = torch.LongTensor(dist_Y).to(self.device)
                mask_Y = torch.LongTensor(mask_Y).to(self.device)

                self.optimizer.zero_grad()

                output = self.model(X)
                cost = self._compute_cost(output, face_Y, dist_Y, mask_Y)

                cost.backward()
                self.optimizer.step()

                accuracy = self._compute_accuracy(output, face_Y)
                self.train_accu.append(accuracy)
                self.train_cost.append(cost.item())

                if i % 1 == 0:  # Adjust this if you want less frequent output
                    print(f"Epoch= {epoch+1},\t batch = {i},\t cost = {cost.item():2.4f},\t accuracy = {accuracy}")

                avg_cost += cost.item() / total_batches

            print(f"[Epoch: {epoch + 1:>4}], averaged cost = {avg_cost:.9}")

        print('Learning Finished!')

    def _prepare_labels(self, batch_Y):
        face_Y, dist_Y, mask_Y = [], [], []
        for Y_i in batch_Y:
            underline_idx = Y_i.find("_")
            face_Y.append(int(Y_i[underline_idx - 1]))
            dist_Y.append(int(Y_i[underline_idx + 1]))
            mask_Y.append(int(Y_i[underline_idx + 3]))
        return face_Y, dist_Y, mask_Y

    def _compute_cost(self, output, face_Y, dist_Y, mask_Y):
        cost_face = self.criterion(output[0], face_Y)
        cost_dist = self.criterion(output[1], dist_Y)
        cost_mask = self.criterion(output[2], mask_Y)
        return cost_face - 0.015 * cost_dist - 0.01 * cost_mask

    def _compute_accuracy(self, output, face_Y):
        prediction = output[0].argmax(dim=1)
        accuracy = (prediction == face_Y).float().mean().item()
        return accuracy
