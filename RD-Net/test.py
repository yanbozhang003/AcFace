
import torch
import numpy as np
from sklearn.metrics import precision_score, recall_score, f1_score

class Tester:
    def __init__(self, model, data_loader, device, args):
        self.model = model
        self.data_loader = data_loader
        self.device = device
        self.args = args

    def test(self):
        self.model.load_state_dict(torch.load(self.args.model_path))
        self.model.eval()

        acc_list = []
        cost_list = []
        incorrect_samples = []
        predictions = []
        true_labels = []

        criterion = torch.nn.CrossEntropyLoss()

        for i, (test_X, test_Y, sample_ids) in enumerate(self.data_loader):
            face_Y, dist_Y, mask_Y = [], [], []
            for Y_i in test_Y:
                underline_idx = Y_i.find("_")
                face_Y.append(int(Y_i[underline_idx-1]))
                dist_Y.append(int(Y_i[underline_idx+1]))
                mask_Y.append(int(Y_i[underline_idx+3]))

            X = test_X.to(self.device)
            face_Y = torch.LongTensor(face_Y).to(self.device)
            dist_Y = torch.LongTensor(dist_Y).to(self.device)
            mask_Y = torch.LongTensor(mask_Y).to(self.device)

            with torch.no_grad():
                output = self.model(X)

                cost_face = criterion(output[0], face_Y)
                cost_dist = criterion(output[1], dist_Y)
                cost_mask = criterion(output[2], mask_Y)
                cost = cost_face - 0.015 * cost_dist - 0.01 * cost_mask

                accuracy = (torch.max(output[0], 1)[1] == face_Y).float().mean().item()

                acc_list.append(accuracy)
                cost_list.append(cost.item())

                predictions.extend(torch.max(output[0], 1)[1].cpu().numpy())
                true_labels.extend(face_Y.cpu().numpy())

                print(f'Batch {i} averaged accuracy: {accuracy*100:.2f} %')

                incorrect_predictions = (torch.max(output[0], 1)[1] != face_Y)
                incorrect_indices = [i for i, x in enumerate(incorrect_predictions) if x]
                incorrect_samples.extend([sample_ids[idx] for idx in incorrect_indices])

        if acc_list:  # Check if acc_list is not empty
            print('\nAveraged Accuracy: {:2.2f} %'.format(np.mean(acc_list) * 100))

        self._calculate_metrics(predictions, true_labels)

    def _calculate_metrics(self, predictions, true_labels):
        N = 10  # Specify the number of portions
        precisions, recalls, f1_scores = [], [], []

        portion_size = len(predictions) // N
        for i in range(N):
            start_index = i * portion_size
            end_index = len(predictions) if i == N - 1 else start_index + portion_size

            portion_predictions = predictions[start_index:end_index]
            portion_true_labels = true_labels[start_index:end_index]

            precisions.append(precision_score(portion_true_labels, portion_predictions, average='macro'))
            recalls.append(recall_score(portion_true_labels, portion_predictions, average='macro'))
            f1_scores.append(f1_score(portion_true_labels, portion_predictions, average='macro'))

        avg_precision = np.mean(precisions)
        median_precision = np.median(precisions)
        avg_recall = np.mean(recalls)
        median_recall = np.median(recalls)
        avg_f1 = np.mean(f1_scores)
        median_f1 = np.median(f1_scores)

        print("Precision - Avg: {:.2f}%, Median: {:.2f}%".format(avg_precision * 100, median_precision * 100))
        print("Recall - Avg: {:.2f}%, Median: {:.2f}%".format(avg_recall * 100, median_recall * 100))
        print("F1-score - Avg: {:.2f}%, Median: {:.2f}%".format(avg_f1 * 100, median_f1 * 100))
