
train_cost = []
train_accu = []

learning_rate = 0.000001
criterion = torch.nn.CrossEntropyLoss()    # Softmax is internally computed.
optimizer = torch.optim.Adam(params=model.parameters(), lr=learning_rate)

training_epochs = 80
total_batch = len(data_train) // batch_size

print('Batch size is : {}'.format(batch_size))
print('Total number of batches is : {0:2.0f}'.format(total_batch))
print('Total number of epochs is : {0:2.0f}'.format(training_epochs))

import torch
import time

# Assuming `train_accu` and `train_cost` are defined earlier
train_accu = []
train_cost = []

for epoch in range(training_epochs):
    avg_cost = 0
    total_batches = 0
    for i, (batch_X, batch_Y, sample_ids) in enumerate(data_train_loader):
        total_batches += 1

        face_Y, dist_Y, mask_Y = [], [], []
        for Y_i in batch_Y:
            underline_idx = Y_i.find("_")
            face_Y.append(int(Y_i[underline_idx - 1]))
            dist_Y.append(int(Y_i[underline_idx + 1]))
            mask_Y.append(int(Y_i[underline_idx + 3]))

        X = batch_X.to(device)
        face_Y = torch.LongTensor(face_Y).to(device)
        dist_Y = torch.LongTensor(dist_Y).to(device)
        mask_Y = torch.LongTensor(mask_Y).to(device)

        optimizer.zero_grad()

        output = model(X)
        cost_face = criterion(output[0], face_Y)
        cost_dist = criterion(output[1], dist_Y)
        cost_mask = criterion(output[2], mask_Y)
        cost = cost_face - 0.015 * cost_dist - 0.01 * cost_mask

        cost.backward()
        optimizer.step()

        prediction = output[0].argmax(dim=1)
        accuracy = (prediction == face_Y).float().mean().item()

        train_accu.append(accuracy)
        train_cost.append(cost.item())

        if i % 1 == 0:
            print(f"Epoch= {epoch+1},	 batch = {i},	 cost = {cost.item():2.4f},	 accuracy = {accuracy}")

        avg_cost += cost.item() / total_batches

    print(f"[Epoch: {epoch + 1:>4}], averaged cost = {avg_cost:.9}")
    print(total_batches)

print('Learning Finished!')
