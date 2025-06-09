import tensorflow as tf, yaml, json, os
from pathlib import Path
from data_extractor import row_stream

cfg = yaml.safe_load(Path("config.yaml").read_text())
IMG_H, IMG_W = cfg["data"]["img_height"], cfg["data"]["img_width"]

# build label ↔ index map once
labels = sorted({p for _, p, _ in row_stream()})
label_to_idx = {lbl: i for i, lbl in enumerate(labels)}
Path("labels.json").write_text(json.dumps(label_to_idx, indent=2))

def _load_preprocess(path, pattern, weight):
    img = tf.io.read_file(path)
    img = tf.image.decode_png(img, channels=3)
    img = tf.image.resize(img, (IMG_H, IMG_W))
    img = img / 255.0
    img = tf.image.random_flip_left_right(img)
    return img, tf.one_hot(label_to_idx[pattern], len(labels)), weight

def build_dataset():
    ds = tf.data.Dataset.from_generator(
        lambda: row_stream(),                   # generator
        output_signature=(
            tf.TensorSpec(shape=(), dtype=tf.string),
            tf.TensorSpec(shape=(), dtype=tf.string),
            tf.TensorSpec(shape=(), dtype=tf.float32))
    )
    ds = ds.map(_load_preprocess, num_parallel_calls=tf.data.AUTOTUNE)
    ds = ds.shuffle(4096)
    bs = cfg["data"]["batch_size"]
    ds = ds.batch(bs).prefetch(tf.data.AUTOTUNE)
    card = tf.data.experimental.cardinality(ds).numpy()
    train = ds.take(int(card*0.7))
    val   = ds.skip(int(card*0.7)).take(int(card*0.15))
    test  = ds.skip(int(card*0.85))
    return train, val, test, len(labels)
