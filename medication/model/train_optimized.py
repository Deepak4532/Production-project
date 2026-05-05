#!/usr/bin/env python3
"""
Optimized Pill Recognition Training - Maximize Accuracy
Strategy: Larger batch size, reduced fine-tune layers, better early stopping,
          class weighting, consistent val_loss monitoring, vertical flip augmentation.

Changes from previous version:
  1. BATCH_SIZE increased to 32 (reduces noisy zigzag in curves)
  2. Fine-tuning unfreezes only top 15 layers (was 30 - too aggressive)
  3. Early stopping monitors val_loss (was val_accuracy - less stable)
  4. Early stopping patience reduced to 10 (was 20 - stopped overfitting sooner)
  5. Added class_weight to handle class imbalance
  6. Added vertical_flip to augmentation (pills can appear upside down)
  7. Slightly higher base LR (0.0003) for faster phase 1 convergence
  8. FINE_TUNE_EPOCHS reduced to 30 (was 50 - fine-tuning needs less)
"""

import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from sklearn.utils.class_weight import compute_class_weight
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay, classification_report
import matplotlib.pyplot as plt
from pathlib import Path

# ── Hyperparameters ────────────────────────────────────────────────────────────
IMG_SIZE         = 224
BATCH_SIZE       = 32      # FIX 1: was 8 — larger batch = smoother gradients, less noise
EPOCHS           = 60      # Phase 1 epochs — gave a bit more room
FINE_TUNE_EPOCHS = 30      # FIX 8: was 50 — fine-tuning converges faster
LEARNING_RATE    = 0.0003  # FIX 7: slightly higher than 0.0001 for phase 1
DATASET_PATH     = Path(__file__).parent / "pill_dataset_5class"

print(f"\n{'='*70}")
print(f"🎯 OPTIMIZED PILL RECOGNITION - MAXIMIZE ACCURACY")
print(f"{'='*70}\n")

if not DATASET_PATH.exists():
    print(f"ERROR: Dataset not found at {DATASET_PATH}")
    exit(1)

train_dir = DATASET_PATH / "train"
class_names_list = sorted([d.name for d in train_dir.iterdir() if d.is_dir()])

print("Dataset:")
print(f"  Classes : {class_names_list}")
print(f"  Train   : {len(list((DATASET_PATH / 'train').glob('*/*')))} images")
print(f"  Val     : {len(list((DATASET_PATH / 'val').glob('*/*')))} images")
print(f"  Test    : {len(list((DATASET_PATH / 'test').glob('*/*')))} images\n")

# ── SSL workaround scoped to weight download only ─────────────────────────────
import ssl
_original_https_context = ssl._create_default_https_context
ssl._create_default_https_context = ssl._create_unverified_context

base_model = keras.applications.MobileNetV2(
    input_shape=(IMG_SIZE, IMG_SIZE, 3),
    include_top=False,
    weights='imagenet'
)

ssl._create_default_https_context = _original_https_context  # Restore immediately
# ─────────────────────────────────────────────────────────────────────────────

base_model.trainable = False  # Freeze for phase 1

# MobileNetV2 expects inputs in [-1, 1].
# preprocessing_function=mobilenet_v2.preprocess_input handles this in datagen.
model = models.Sequential([
    layers.Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.BatchNormalization(),
    layers.Dense(512, activation='relu'),
    layers.Dropout(0.2),
    layers.Dense(len(class_names_list), activation='softmax')
])

print(f"Model: {model.count_params():,} parameters\n")

def build_metrics():
    return [
        'accuracy',
        keras.metrics.TopKCategoricalAccuracy(k=2, name='top_2_accuracy')
    ]

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
    loss='categorical_crossentropy',
    metrics=build_metrics()
)

# ── Augmentation ───────────────────────────────────────────────────────────────
print("Augmentation (phase 1 & 2):")
print("  - Rotation        : ±30°")
print("  - Brightness      : ±30%")
print("  - Zoom            : ±20%")
print("  - Width/Height shift: ±20%")
print("  - Shear           : 15%")
print("  - Horizontal flip : yes")
print("  - Vertical flip   : yes  ← NEW (pills can appear upside down)")
print("")

train_augmentation = ImageDataGenerator(
    preprocessing_function=keras.applications.mobilenet_v2.preprocess_input,
    rotation_range=30,
    width_shift_range=0.2,
    height_shift_range=0.2,
    brightness_range=[0.7, 1.3],
    shear_range=0.15,
    zoom_range=0.2,
    horizontal_flip=True,
    vertical_flip=True,    # FIX 6: pills have no fixed orientation
    fill_mode='nearest'
)

val_datagen = ImageDataGenerator(
    preprocessing_function=keras.applications.mobilenet_v2.preprocess_input
)

train_gen = train_augmentation.flow_from_directory(
    str(DATASET_PATH / "train"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

val_gen = val_datagen.flow_from_directory(
    str(DATASET_PATH / "val"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=False
)

test_gen = val_datagen.flow_from_directory(
    str(DATASET_PATH / "test"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=False
)

# ── FIX 5: Compute class weights to handle imbalanced classes ─────────────────
print("Computing class weights...")
class_weights_array = compute_class_weight(
    class_weight='balanced',
    classes=np.unique(train_gen.classes),
    y=train_gen.classes
)
class_weight_dict = dict(enumerate(class_weights_array))
print(f"  Class weights: { {class_names_list[k]: round(v, 3) for k, v in class_weight_dict.items()} }\n")

# ── Callbacks ─────────────────────────────────────────────────────────────────
# FIX 3 & 4: Monitor val_loss (more stable than val_accuracy), patience=10

phase1_callbacks = [
    ModelCheckpoint(
        'pill_recognition_phase1_best.h5',
        monitor='val_loss',        # FIX 3: was val_accuracy
        save_best_only=True,
        verbose=0
    ),
    EarlyStopping(
        monitor='val_loss',        # FIX 3: was val_accuracy
        patience=10,               # FIX 4: was 20 — stops overfitting sooner
        min_delta=0.001,
        restore_best_weights=True,
        verbose=1
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=1e-6,
        verbose=1
    ),
]

# ── Phase 1: Train top layers only ────────────────────────────────────────────
print("Phase 1: Training top layers (base frozen)...")
history = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=EPOCHS,
    callbacks=phase1_callbacks,
    class_weight=class_weight_dict,   # FIX 5: handle class imbalance
    verbose=1
)

# ── Phase 2: Fine-tune top layers of base model ───────────────────────────────
print("\nPhase 2: Fine-tuning top 15 layers of base model...")

# FIX 2: Unfreeze only top 15 layers (was 30 — caused catastrophic forgetting)
base_model.trainable = True
for layer in base_model.layers[:-15]:
    layer.trainable = False

trainable_count = sum(1 for l in base_model.layers if l.trainable)
print(f"  Trainable base layers: {trainable_count} / {len(base_model.layers)}")

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-5),  # Very low LR for fine-tuning
    loss='categorical_crossentropy',
    metrics=build_metrics()
)

phase1_end_epoch = history.epoch[-1] + 1
total_epochs = phase1_end_epoch + FINE_TUNE_EPOCHS

print(f"  Phase 1 ended at epoch : {phase1_end_epoch}")
print(f"  Phase 2 will run until : epoch {total_epochs}\n")

phase2_callbacks = [
    ModelCheckpoint(
        'pill_recognition_phase2_best.h5',
        monitor='val_loss',        # FIX 3: consistent with phase 1
        save_best_only=True,
        verbose=0
    ),
    EarlyStopping(
        monitor='val_loss',        # FIX 3: was val_accuracy
        patience=10,               # FIX 4: was 20
        min_delta=0.001,
        restore_best_weights=True,
        verbose=1
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=1e-7,
        verbose=1
    ),
]

history_fine = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=total_epochs,
    initial_epoch=phase1_end_epoch,
    callbacks=phase2_callbacks,
    class_weight=class_weight_dict,   # FIX 5: also apply in phase 2
    verbose=1
)

# ── Save final model ──────────────────────────────────────────────────────────
print("\nSaving models...")
model.save('pill_recognition_optimized.h5')
print("✅ Saved: pill_recognition_optimized.h5")
print("✅ Best phase 1 weights: pill_recognition_phase1_best.h5")
print("✅ Best phase 2 weights: pill_recognition_phase2_best.h5")

# ── TFLite conversion ─────────────────────────────────────────────────────────
print("\nConverting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
with open('pill_recognition_model.tflite', 'wb') as f:
    f.write(tflite_model)
print(f"✅ TFLite: {len(tflite_model)/1024:.1f} KB")

# ── Evaluation ────────────────────────────────────────────────────────────────
print("\n" + "="*70)
print("TEST SET EVALUATION")
print("="*70 + "\n")

results = model.evaluate(test_gen, verbose=0)
print(f"Test Loss      : {results[0]:.4f}")
print(f"Test Accuracy  : {results[1]*100:.2f}%")
print(f"Top-2 Accuracy : {results[2]*100:.2f}%")

predictions = model.predict(test_gen, verbose=0)
predicted_classes = np.argmax(predictions, axis=1)
true_classes = test_gen.classes

print("\nPer-Class Accuracy:")
for cls in class_names_list:
    idx = test_gen.class_indices[cls]
    mask = true_classes == idx
    if np.sum(mask) > 0:
        correct = np.sum(predicted_classes[mask] == true_classes[mask])
        total   = np.sum(mask)
        acc     = correct / total * 100
        status  = "✓" if acc >= 70 else "~" if acc >= 50 else "✗"
        print(f"  {status} {cls:<45} {acc:>6.1f}%  ({correct}/{total})")

print("\n" + "="*70 + "\n")

# ── Training History Plots ────────────────────────────────────────────────────
def plot_training_history(history_p1, history_p2, save_path='training_history.png'):
    """
    Merges phase 1 and phase 2 histories and plots:
      - Accuracy (train & val) across both phases
      - Loss     (train & val) across both phases
      - Top-2 Accuracy (train & val) across both phases
    A vertical dashed line marks the phase boundary.
    """

    def merge(key):
        p1 = history_p1.history.get(key, [])
        p2 = history_p2.history.get(key, [])
        return p1 + p2

    acc      = merge('accuracy')
    val_acc  = merge('val_accuracy')
    loss     = merge('loss')
    val_loss = merge('val_loss')
    top2     = merge('top_2_accuracy')
    val_top2 = merge('val_top_2_accuracy')

    epochs_range     = range(1, len(acc) + 1)
    phase_boundary   = len(history_p1.history['accuracy'])

    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    fig.suptitle('Pill Recognition – Training History', fontsize=15, fontweight='bold', y=1.02)

    plot_configs = [
        {
            'ax': axes[0],
            'train': acc, 'val': val_acc,
            'title': 'Accuracy', 'ylabel': 'Accuracy',
            'train_label': 'Train Accuracy', 'val_label': 'Val Accuracy',
            'train_color': '#2196F3', 'val_color': '#FF5722',
        },
        {
            'ax': axes[1],
            'train': loss, 'val': val_loss,
            'title': 'Loss', 'ylabel': 'Loss',
            'train_label': 'Train Loss', 'val_label': 'Val Loss',
            'train_color': '#4CAF50', 'val_color': '#E91E63',
        },
        {
            'ax': axes[2],
            'train': top2, 'val': val_top2,
            'title': 'Top-2 Accuracy', 'ylabel': 'Top-2 Accuracy',
            'train_label': 'Train Top-2', 'val_label': 'Val Top-2',
            'train_color': '#9C27B0', 'val_color': '#FF9800',
        },
    ]

    for cfg in plot_configs:
        ax = cfg['ax']
        ax.plot(epochs_range, cfg['train'], color=cfg['train_color'],
                linewidth=2, label=cfg['train_label'])
        ax.plot(epochs_range, cfg['val'],   color=cfg['val_color'],
                linewidth=2, linestyle='--', label=cfg['val_label'])

        if 0 < phase_boundary < len(acc):
            ax.axvline(x=phase_boundary, color='gray', linestyle=':', linewidth=1.5,
                       label=f'Fine-tune start (epoch {phase_boundary})')

        ax.set_title(cfg['title'], fontsize=12, fontweight='bold')
        ax.set_xlabel('Epoch', fontsize=10)
        ax.set_ylabel(cfg['ylabel'], fontsize=10)
        ax.legend(fontsize=9)
        ax.grid(True, alpha=0.3)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)

    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"✅ Training history plot saved: {save_path}")


def plot_per_class_accuracy(class_names, true_cls, pred_cls, class_indices,
                             save_path='per_class_accuracy.png'):
    """Bar chart showing per-class test accuracy."""
    accs = []
    for cls in class_names:
        idx  = class_indices[cls]
        mask = true_cls == idx
        if np.sum(mask) > 0:
            accs.append(np.sum(pred_cls[mask] == true_cls[mask]) / np.sum(mask) * 100)
        else:
            accs.append(0.0)

    colors = ['#4CAF50' if a >= 70 else '#FF9800' if a >= 50 else '#F44336' for a in accs]

    fig, ax = plt.subplots(figsize=(10, 5))
    bars = ax.bar(class_names, accs, color=colors, edgecolor='white', linewidth=0.8)

    for bar, acc in zip(bars, accs):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1,
                f'{acc:.1f}%', ha='center', va='bottom', fontsize=10, fontweight='bold')

    ax.axhline(y=70, color='#4CAF50', linestyle='--', linewidth=1.2, alpha=0.7, label='70% threshold')
    ax.axhline(y=50, color='#FF9800', linestyle='--', linewidth=1.2, alpha=0.7, label='50% threshold')
    ax.set_ylim(0, 115)
    ax.set_title('Per-Class Test Accuracy', fontsize=13, fontweight='bold')
    ax.set_xlabel('Class', fontsize=11)
    ax.set_ylabel('Accuracy (%)', fontsize=11)
    ax.legend(fontsize=9)
    ax.grid(axis='y', alpha=0.3)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    plt.xticks(rotation=20, ha='right', fontsize=9)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"✅ Per-class accuracy plot saved: {save_path}")


def plot_confusion_matrix(class_names, true_cls, pred_cls,
                           save_path='confusion_matrix.png'):
    """
    Plots a labeled confusion matrix with:
      - Count in each cell
      - Row-normalised % in parentheses (so you can spot which class
        gets confused with which, regardless of class size)
      - Diagonal highlighted in blue (correct predictions)
      - Off-diagonal errors in red shades
    Also prints a full classification report (precision, recall, F1).
    """
    cm      = confusion_matrix(true_cls, pred_cls)
    cm_norm = cm.astype('float') / cm.sum(axis=1, keepdims=True) * 100  # row %

    n = len(class_names)
    fig, ax = plt.subplots(figsize=(max(8, n * 1.8), max(6, n * 1.5)))

    # Draw heatmap manually so we can colour diagonal/off-diagonal differently
    im = ax.imshow(cm_norm, interpolation='nearest', cmap='Blues', vmin=0, vmax=100)
    plt.colorbar(im, ax=ax, label='Row-normalised accuracy (%)')

    # Tick labels — shorten long names for readability
    short_names = [c.replace('_Oral_Tablet', '').replace('_Delayed_Release', '\n(DR)')
                   for c in class_names]
    ax.set_xticks(range(n))
    ax.set_yticks(range(n))
    ax.set_xticklabels(short_names, rotation=35, ha='right', fontsize=9)
    ax.set_yticklabels(short_names, fontsize=9)

    # Annotate each cell with count + normalised %
    thresh = 50  # flip text colour above this background intensity
    for i in range(n):
        for j in range(n):
            count   = cm[i, j]
            pct     = cm_norm[i, j]
            color   = 'white' if pct > thresh else 'black'
            cell_txt = f"{count}\n({pct:.0f}%)"
            weight  = 'bold' if i == j else 'normal'
            ax.text(j, i, cell_txt, ha='center', va='center',
                    fontsize=10, color=color, fontweight=weight)

    ax.set_title('Confusion Matrix – Test Set\n(count  /  row-normalised %)',
                 fontsize=13, fontweight='bold', pad=15)
    ax.set_ylabel('True Label', fontsize=11)
    ax.set_xlabel('Predicted Label', fontsize=11)

    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"✅ Confusion matrix saved: {save_path}")

    # ── Classification report ─────────────────────────────────────────────────
    print("\nClassification Report:")
    print(classification_report(true_cls, pred_cls, target_names=class_names,
                                digits=3, zero_division=0))


print("\nGenerating training plots...")
plot_training_history(history, history_fine, save_path='training_history.png')
plot_per_class_accuracy(
    class_names_list, true_classes, predicted_classes,
    test_gen.class_indices, save_path='per_class_accuracy.png'
)
plot_confusion_matrix(
    class_names_list, true_classes, predicted_classes,
    save_path='confusion_matrix.png'
)
print("\nAll done! 🎉\n")