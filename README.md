# BoatNav — Garmin Vivoactive 3

Svart marinapp med röd kompassros, stor knopvisning och koordinater.

## Skärmlayout

```
        N               ← röd referens
   NW  ticks  NE
  W              E      ← N/E/S/W vid r=100, aldrig överlapp med pilen
   SW  ticks  SE
        S

       [KURS]
     NNE  022°          ← aktuell kurs

  ─────────────────────

        6.2              ← knop, stor och dominant
       KNOP

  ─────────────────────
  NM      │  POS
  12.45   │  58°22.3'N
          │  17°58.0'E
```

Pilspetsen (röd triangel) snurrar på ringen och pekar mot aktuell kurs.
Den rör sig på r=76–90, bokstäverna sitter på r=100 → aldrig överlapp.

---

## Installera

### Krav
1. **Visual Studio Code** — code.visualstudio.com
2. **Connect IQ SDK Manager** — developer.garmin.com/connect-iq/sdk
3. **VS Code-tillägget "Monkey C"** — sök i Extensions
4. **Eclipse Temurin JDK 11** — adoptium.net

### Bygga
```bash
# 1. Öppna mappen i VS Code
code BoatNav/

# 2. Ctrl+Shift+P → "Monkey C: Build for Device" → välj vivoactive3

# 3. bin/BoatNav.prg skapas
```

### Ladda upp till klockan
```
1. Anslut Vivoactive 3 med USB
2. Kopiera bin/BoatNav.prg → GARMIN/Apps/ på klockan
3. Koppla ur → appen finns under Aktiviteter
```

### Alternativt: direkt med SDK
```bash
monkeyc -f monkey.jungle -o bin/BoatNav.prg \
        -d vivoactive3 -y developer_key.der
```
(Developer key genereras gratis på developer.garmin.com)

---

## Finjustera layouten

Om siffror eller text sitter fel på din klocka, justera konstanterna
överst i `source/BoatNavApp.mc`:

| Konstant | Beskrivning |
|----------|-------------|
| `Y_KN`   | Knoptalets y-position (standard 92) |
| `Y_KNL`  | "KNOP"-etikettens y (standard 150) |
| `Y_S2`   | Undre separatorlinje (standard 160) |
| `Y_DV1`  | Första dataraden — NM/lat (standard 176) |
| `Y_DV2`  | Andra dataraden — lon (standard 189) |
| `R_LBL`  | Radius för N/E/S/W (standard 100) |
| `R_AT`   | Pilspetsens ytterradie (standard 90) |

Testa i Connect IQ Simulator (ingår i SDK) innan du laddar upp till klockan.

---

## Funktioner

| Fält | Källa | Enhet |
|------|-------|-------|
| Kurs | GPS heading | 16-punkt + grader |
| Knop | GPS hastighet × 1.94384 | kn |
| NM   | Haversine-summering | sjömil |
| POS  | GPS position | grader°minuter'N/E/S/W |

Distansen nollas vid omstart av appen (per tur).
# BoatNav
