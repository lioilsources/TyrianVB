# Tyrian 2026

## Proces: nový skin od A do Z

1. **Vygeneruj AI assety (xAI Grok)**  
   32 JPEGů x N variací.

```bash
cd /Volumes/YOTTA/Dev/TyrianVB/pipeline
go run ./cmd/generate -skin geometry_wars -n 4
```

2. **Postprocess obrázků**  
   JPG -> PNG s alpha, resize, přejmenování.

```bash
go run ./cmd/postprocess -skin geometry_wars
```

3. **Hotovo**  
   Assety jsou rovnou v `tyrian_mobile/assets/skins/geometry_wars/`.

Ověř:

```bash
ls tyrian_mobile/assets/skins/geometry_wars/sprites/
ls tyrian_mobile/assets/skins/geometry_wars/ui/preview.png
```

4. **Spusť na iPadu**

```bash
cd /Volumes/YOTTA/Dev/TyrianVB/tyrian_mobile
flutter run
```

## Postprocess MP3 -> OGG

```bash
go run ./cmd/postprocess \
  -skin geometry_wars \
  -input /Volumes/YOTTA/Dev/TyrianVB/pipeline/output/assets/skins \
  -output /Volumes/YOTTA/Dev/TyrianVB/tyrian_mobile/assets/skins
```

# Skins
- Nuclear Throne
- Luftrausers
- Nech Machina
- Geometry Wars
- Tyrion
- Gradius V
- R-Type
- Blazing Lazers
- Ikaruga
- Galaga
- Space Invaders
- Asteroids