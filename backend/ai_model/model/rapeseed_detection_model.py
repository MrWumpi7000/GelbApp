
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models
import matplotlib.pyplot as plt

# Datenaugmentation und Datenvorbereitung
train_datagen = ImageDataGenerator(
    rescale=1./255,  # Normalisierung der Pixelwerte
    rotation_range=20,  # Zufällige Rotation der Bilder
    width_shift_range=0.2,  # Horizontale Verschiebung
    height_shift_range=0.2,  # Vertikale Verschiebung
    shear_range=0.2,  # Scherung der Bilder
    zoom_range=0.2,  # Zoom
    horizontal_flip=True,  # Horizontal spiegeln
    fill_mode='nearest'  # Füllen der leeren Bereiche
)

validation_datagen = ImageDataGenerator(rescale=1./255)  # Nur Normalisierung für Validierungsdaten

train_generator = train_datagen.flow_from_directory(
    'path_to_data/train',  # Pfad zu deinem Trainingsordner
    target_size=(150, 150),  # Alle Bilder auf 150x150 skalieren
    batch_size=32,
    class_mode='binary'  # Zwei Klassen: Rapsfeld und anderes
)

validation_generator = validation_datagen.flow_from_directory(
    'path_to_data/validation',  # Pfad zu deinem Validierungsordner
    target_size=(150, 150),
    batch_size=32,
    class_mode='binary'
)

# Modell erstellen
model = models.Sequential([
    layers.Conv2D(32, (3, 3), activation='relu', input_shape=(150, 150, 3)),  # Convolutional Layer
    layers.MaxPooling2D((2, 2)),  # Max-Pooling
    layers.Conv2D(64, (3, 3), activation='relu'),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),  # Flache Schicht
    layers.Dense(512, activation='relu'),  # Vollverbundene Schicht
    layers.Dense(1, activation='sigmoid')  # Ausgabe (1 = Rapsfeld, 0 = anderes)
])

# Kompilieren des Modells
model.compile(optimizer='adam',
              loss='binary_crossentropy',
              metrics=['accuracy'])

# Modell trainieren
history = model.fit(
    train_generator,
    steps_per_epoch=train_generator.samples // train_generator.batch_size,
    epochs=10,
    validation_data=validation_generator,
    validation_steps=validation_generator.samples // validation_generator.batch_size
)

# Genauigkeit und Verlust visualisieren
plt.plot(history.history['accuracy'], label='Training accuracy')
plt.plot(history.history['val_accuracy'], label='Validation accuracy')
plt.xlabel('Epochs')
plt.ylabel('Accuracy')
plt.legend()
plt.show()

plt.plot(history.history['loss'], label='Training loss')
plt.plot(history.history['val_loss'], label='Validation loss')
plt.xlabel('Epochs')
plt.ylabel('Loss')
plt.legend()
plt.show()

# Modell speichern
model.save('rapeseed_model.h5')
