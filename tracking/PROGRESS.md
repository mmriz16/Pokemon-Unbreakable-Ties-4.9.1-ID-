# Progress

## Done
- Audit sumber teks runtime selesai.
- Repo kerja lokal di folder `Pokemon Unbreakable Ties 4.9.1 (ID)` dibuat.
- Remote GitHub ditambahkan.
- Translasi awal `Data/Scripts/016_UI` dipindahkan ke repo kerja.
- Translasi awal PBS/deskripsi dipindahkan ke repo kerja.
- Compile awal beberapa file `.dat` dipindahkan ke repo kerja.
- Script rebuild `english.dat` dibuat.
- `Data/english.dat` versi Indonesia berhasil dibangun di folder `ID`.
- Verifikasi sample berhasil: nama species tetap asli, sedangkan kinds/entries/deskripsi terjemah ke Indonesia.

## Next
- Audit `messages.dat`, `CommonEvents.rxdata`, dan `Map*.rxdata` per urutan story.
- Rapikan istilah UI yang masih kaku.
- Mulai translasi `011_Battle`, `012_Overworld`, `013_Items`, dan `999_Main`.
- Putuskan apakah `english.dat` hasil rebuild akan dipakai langsung atau dijadikan baseline lalu diproofread dulu.

## Blockers
- Tidak ada akses Notion API/connector di environment ini.
- `english.dat` Indonesia lama tidak ditemukan di folder sumber saat ini, jadi rebuild dilakukan dari file Inggris yang ada sekarang.
- Hasil translasi mesin masih perlu proofreading, terutama trainer types, ribbon text, dan battle descriptions.

## Working Rules
- Nama Pokemon, item, move, ability tetap pakai istilah asli kecuali diputuskan lain.
- Deskripsi dan UI diterjemahkan ke Bahasa Indonesia.
- Setiap perubahan runtime harus punya backup.
