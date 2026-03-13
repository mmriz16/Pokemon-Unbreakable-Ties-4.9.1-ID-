# Translation Audit

## Runtime Summary
- `Game.ini` menunjuk ke `Data/Scripts.rxdata`.
- `Data/Scripts.rxdata` hanya loader kecil yang menjalankan `load_scripts_from_folder("Data/Scripts")`.
- Artinya perubahan di `Data/Scripts/**/*.rb` memang berpengaruh langsung saat game start.
- File di `PBS` tidak dibaca langsung saat bermain. File itu harus di-compile menjadi `Data/*.dat`.
- Dialog, common event, dan map event tidak berasal dari `PBS`; sumber utamanya ada di:
  - `Data/messages.dat`
  - `Data/CommonEvents.rxdata`
  - `Data/Map*.rxdata`

## Main Translatable Areas

### 1. UI Scripts
Prioritas tertinggi untuk tampilan menu dan flow pemain.

- `Data/Scripts/016_UI`
  - Pause menu
  - Pokedex
  - Party
  - Summary
  - Bag
  - Save/Load
  - Options
  - Storage
  - Mart
  - Mystery Gift
  - Text Entry

### 2. Battle Text
Teks pertempuran dan prompt sistem.

- `Data/Scripts/011_Battle`
  - 62 file
  - Paling banyak string `_INTL(...)`

### 3. Item/Overworld/System Text
- `Data/Scripts/013_Items`
- `Data/Scripts/012_Overworld`
- `Data/Scripts/019_Utilities`
- `Data/Scripts/999_Main`
- `Data/Scripts/017_Minigames`
- `Data/Scripts/018_Alternate battle modes`

### 4. PBS Text Data
Sumber nama/deskripsi/data teks statis.

Translatable:
- `PBS/abilities.txt`
- `PBS/items.txt`
- `PBS/moves.txt`
- `PBS/pokemon.txt`
- `PBS/pokemonforms.txt`
- `PBS/ribbons.txt`
- `PBS/trainertypes.txt`
- `PBS/trainers.txt`
- `PBS/phone.txt`
- `PBS/townmap.txt`
- `PBS/metadata.txt`
- `PBS/types.txt`

Mostly non-translatable or low priority:
- `PBS/connections.txt`
- `PBS/encounters.txt`
- `PBS/regionaldexes.txt`
- `PBS/shadowmoves.txt`
- `PBS/trainerlists.txt`

### 5. Compiled Runtime Data
Perubahan PBS baru akan muncul di game setelah compile ke:

- `Data/abilities.dat`
- `Data/items.dat`
- `Data/moves.dat`
- `Data/species.dat`
- `Data/ribbons.dat`
- `Data/phone.dat`
- `Data/town_map.dat`
- `Data/trainer_types.dat`
- `Data/trainers.dat`
- `Data/messages.dat`

### 6. Story/Event Text
Ini bagian terbesar untuk translasi penuh sesuai alur cerita.

- `Data/CommonEvents.rxdata`
- `Data/Map001.rxdata` sampai `Data/Map707.rxdata`
- `Data/messages.dat`
- `Data/english.dat` atau message pack bahasa aktif lain

## Folder Audit Summary

| Folder | Relevansi translasi | Catatan |
|---|---|---|
| `Data/Scripts/016_UI` | Sangat tinggi | Menu, prompt, layar utama |
| `Data/Scripts/011_Battle` | Sangat tinggi | Teks battle paling banyak |
| `Data/Scripts/013_Items` | Tinggi | Teks item/use-item |
| `Data/Scripts/012_Overworld` | Tinggi | Prompt field moves/fishing/overworld |
| `Data/Scripts/999_Main` | Tinggi | Script custom game, banyak teks unik |
| `PBS` | Tinggi | Data nama/deskripsi/statis |
| `Data/messages.dat` | Sangat tinggi | Message pack runtime |
| `Data/CommonEvents.rxdata` | Sangat tinggi | Event global |
| `Data/Map*.rxdata` | Sangat tinggi | Story dan NPC dialog |
| `Plugins` | Sedang | Banyak plugin UI/system yang mungkin punya string |

## Current Risks
- `english.dat` saat ini bukan versi Indonesia yang diharapkan.
- Build sumber ini punya jejak string campuran Inggris/Spanyol pada script custom.
- Kompilasi PBS bisa mengubah `.dat` runtime, jadi perlu backup konsisten.
- Translasi mesin perlu proofreading manual untuk menjaga istilah Pokemon tetap konsisten.
