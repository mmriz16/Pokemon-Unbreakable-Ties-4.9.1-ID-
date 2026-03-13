# Pokemon Unbreakable Ties 4.9.1 (ID)

Workspace translasi Bahasa Indonesia untuk `Pokemon Unbreakable Ties 4.9.1`.

Status saat ini:
- Audit sumber teks selesai.
- Translasi awal sudah dipindahkan untuk `Data/Scripts/016_UI`.
- Translasi awal deskripsi PBS sudah dipindahkan untuk:
  - `abilities.txt`
  - `items.txt`
  - `moves.txt`
  - `pokemon.txt`
  - `pokemonforms.txt`
  - `ribbons.txt`
- Hasil compile awal `.dat` yang sudah tersedia juga dipindahkan:
  - `abilities.dat`
  - `items.dat`
  - `moves.dat`
  - `species.dat`
  - `ribbons.dat`

Catatan penting:
- Game runtime memakai `Data/Scripts.rxdata`, tetapi file itu hanya loader ke `Data/Scripts`.
- Banyak teks UI dan sistem dibaca dari `Data/Scripts`.
- Banyak teks game lain dibaca dari hasil compile `Data/*.dat`, bukan langsung dari `PBS`.
- `english.dat` yang ada di build sumber saat ini berisi teks Inggris, bukan versi Indonesia.
- Notion belum bisa diupdate langsung dari environment ini karena tidak ada akses API/connector. Sebagai pengganti, file CSV import Notion disediakan di `tracking/notion_translation_tasks.csv`.
