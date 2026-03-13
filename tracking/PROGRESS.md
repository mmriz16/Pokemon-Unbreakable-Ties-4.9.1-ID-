# Progress

## Dashboard
- Overall playable Indonesian progress: `40%`
- Phase 1. Audit source text: `100%`
- Phase 2. Build Indonesian runtime baseline (`english.dat`, `messages.dat`): `100%`
- Phase 3. Proofread runtime/UI/system text: `70%`
- Phase 4. Audit story/event text (`CommonEvents.rxdata`, `Map*.rxdata`): `100%`
- Phase 5. Draft story translation per batch/map: `10%`
- Phase 6. Inject translated story back into event runtime: `0%`
- Phase 7. In-game verification and polish pass: `0%`

## How To Read
- `Overall playable Indonesian progress` mengukur kesiapan game untuk dimainkan penuh dalam Bahasa Indonesia, bukan sekadar jumlah file yang sudah disentuh.
- Fase runtime sudah jauh lebih maju daripada fase story. Bottleneck utama sekarang ada di translasi event map/common event dan proses inject kembali ke file runtime.

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
- Script resumable untuk rebuild `messages.dat` dibuat.
- `Data/messages.dat` versi Indonesia berhasil dibangun di folder `ID`.
- Verifikasi sample `messages.dat` berhasil: type text, move descriptions, ability descriptions, trainer types, dan map/common messages sudah terbaca dari file hasil rebuild.
- Proofreading pass runtime pertama diterapkan langsung ke `english.dat` dan `messages.dat` untuk istilah yang paling terlihat salah, terutama `types` dan `trainer types`.
- Proofreading pass kedua diterapkan untuk trainer classes yang masih kaku dan string UI Pokedex yang sempat merusak path asset (`Graphics/Pictures`).
- Cleanup UI pass diterapkan ke `Party`, `Summary`, `Bag`, `Save`, `PC`, `Pokemon Storage`, `Move Relearner`, `Mystery Gift`, `Text Entry`, dan `Hall of Fame` untuk menghapus sisa path asset yang salah serta string `Pokedex/Pokemon` yang rusak encoding.
- Proofreading pass battle diterapkan ke runtime data untuk memperhalus kalimat yang paling sering muncul, misalnya status/stat down, pemblokiran jurus, serangan yang dihindari, dan beberapa pesan efek ability/item.
- Proofreading pass battle kedua diterapkan untuk effectiveness, flee text, miss text, dan beberapa pesan status/ability yang sangat sering tampil saat turn berjalan.
- Proofreading pass battle ketiga diterapkan untuk status ailment text dan beberapa kalimat flavour yang masih kaku, termasuk paralysis cure, drowsy/levitate text, dan beberapa deskripsi karakter yang sempat masih bercampur Spanyol.
- Cleanup pass item/overworld diterapkan ke `messages.dat` untuk memulihkan path asset runtime (`Graphics/Pictures/...`), merapikan prompt mail/item/editor, dan membersihkan beberapa string story/profile yang masih bercampur Spanyol atau terlalu literal.
- Cleanup pass save/shop/storage diterapkan ke `messages.dat` untuk merapikan prompt save, PC/mail wording, Summer Mart text, dan beberapa label editor yang masih memakai kata `gerakan` atau frasa hasil translasi literal.
- Cleanup pass residual story/dialog diterapkan ke `messages.dat` untuk mengubah wording `gerakan -> jurus` di pesan gameplay tertentu, merapikan deskripsi karakter Akebia, dan memperhalus sejumlah string meta/editor yang masih terasa seperti hasil translasi mesin.
- Audit event source di luar `messages.dat` selesai dengan extractor baru `tools/extract_event_text_audit.rb`. Hasil awal: `100` common events, `646` maps, dan `61,004` row teks event berhasil diekstrak ke `tracking/event_text_audit.csv`, dengan map paling padat teks saat ini antara lain `Map698`, `Map025`, dan `Map001`.
- Backlog story per map mulai dibentuk dengan `tools/build_event_priority_report.rb`, yang menghasilkan `tracking/event_text_priority.md` dan batch CSV di `tracking/event_batches/` untuk common events serta 15 map paling padat teks.
- Draft translasi story pertama mulai disusun di `tracking/translation_drafts/`, mencakup `common_events` awal dan bagian pembuka `Map001` (event meteor Dra. Vega) sebagai batch kerja pertama sebelum proses inject ke event runtime.

## Next
- Verifikasi `messages.dat` langsung di game.
- Audit `CommonEvents.rxdata` dan `Map*.rxdata` per urutan story.
- Prioritaskan translasi event/story berdasarkan hasil audit `event_text_audit.csv` dan map dengan row teks terbanyak.
- Rapikan istilah UI dan trainer class yang masih kaku.
- Mulai translasi `011_Battle`, `012_Overworld`, `013_Items`, dan `999_Main`.
- Putuskan apakah `english.dat` hasil rebuild akan dipakai langsung atau dijadikan baseline lalu diproofread dulu.

## Blockers
- Tidak ada akses Notion API/connector di environment ini.
- `english.dat` Indonesia lama tidak ditemukan di folder sumber saat ini, jadi rebuild dilakukan dari file Inggris yang ada sekarang.
- Hasil translasi mesin masih perlu proofreading, terutama trainer types, ribbon text, dan battle descriptions.
- Hasil translasi mesin untuk `messages.dat` masih perlu proofreading lanjutan, terutama event/story text dan prompt editor yang jarang muncul.

## Working Rules
- Nama Pokemon, item, move, ability tetap pakai istilah asli kecuali diputuskan lain.
- Deskripsi dan UI diterjemahkan ke Bahasa Indonesia.
- Setiap perubahan runtime harus punya backup.
