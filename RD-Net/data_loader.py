class AudioFaceDataset(Dataset):
    def __init__(self, data_dir, split='train', transform=None, target_transform=None):
        self.data_dir = data_dir
        self.split = split
        self.transform = transform
        self.target_transform = target_transform
        self.all_labels = self.get_all_label_df()  # Get all labels without splitting
        self.labels = self.split_labels()  # Split the labels according to the specified split

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        row = self.labels.iloc[idx]
        label = row["label"]
        path = row["path"]
        data = self.read_mat_cnn(path)
        if self.transform:
            data = self.transform(data)
        if self.target_transform:
            label = self.target_transform(label)

        identifier = path

        return data, label, identifier

    @staticmethod
    def read_mat_cnn(file):
        data = loadmat(file)["mat_concat"]
        data_tmp = np.expand_dims(data, axis=0)
        return data_tmp.astype(np.float32)

    def list_all_mat_files(self):
        all_files = [str(x.absolute()) for x in Path(self.data_dir).glob("**/*.mat")]
        # print(f"Found {len(all_files)} .mat files in {self.data_dir}")
        return all_files

    def convert_path_to_label(self, path_str):
        label_start_idx = path_str.rfind('.mat')
        face_label = path_str[label_start_idx-3]
        mask_label = path_str[label_start_idx-2]
        dist_label = path_str[label_start_idx-1]
        return "_".join([face_label, dist_label, mask_label])

    def get_all_label_df(self):
        label_dict = {}
        for file in self.list_all_mat_files():
            label = self.convert_path_to_label(file)
            label_dict[file] = label

        label_df = pd.DataFrame.from_dict(label_dict, orient="index").reset_index().rename(columns={"index": "path", 0: "label"})
        return label_df

    def split_labels(self):
        all_labels_shuffled = self.all_labels.sample(frac=1).reset_index(drop=True)
        if self.split == 'train':
            return all_labels_shuffled.sample(frac=0.8)
        elif self.split == 'test':
            return all_labels_shuffled.sample(frac=0.6)
        else:
            raise ValueError("Split must be 'train' or 'test'.")

test_dir = './drive/MyDrive/AcFace_AE/RD-Net/Dataset/Accuracy/env3_samples'
data_test = AudioFaceDataset(data_dir, split='test')
data_test_loader = DataLoader(dataset=data_test,
                              batch_size=batch_size,
                              shuffle=True,  # Typically, we don't need to shuffle the test data
                              num_workers=8)

print("Data loader setup complete.")