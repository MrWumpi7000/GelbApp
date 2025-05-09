import tensorflow as tf # type: ignore
from tensorflow.keras.preprocessing import image # type: ignore
import numpy as np # type: ignore

# Modell laden
model = tf.keras.models.load_model('../saved_model/rapeseed_model.h5')

# Pfad zum Bild
img_path = 'path_to_new_image.jpg'  # Hier den Pfad zum Bild angeben

# Bild laden und vorverarbeiten
img = image.load_img(img_path, target_size=(150, 150))  # Bild auf 150x150 skalieren
img_array = image.img_to_array(img)  # Bild in ein Array umwandeln
img_array = np.expand_dims(img_array, axis=0)  # Die Dimensionen erweitern, damit es zu einem Batch passt
img_array = img_array / 255.0  # Pixelwerte normalisieren (zwischen 0 und 1)

# Vorhersage mit dem geladenen Modell
prediction = model.predict(img_array)

# Ausgabe der Vorhersage
if prediction[0] > 0.5:
    print("Das Bild zeigt ein Rapsfeld (Label 1).")
else:
    print("Das Bild zeigt kein Rapsfeld (Label 0).")
