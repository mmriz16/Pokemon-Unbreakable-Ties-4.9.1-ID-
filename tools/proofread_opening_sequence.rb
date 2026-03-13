require "csv"
require "fileutils"
require "pathname"

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
TRACKING_DIR = ROOT.join("tracking")
CSV_PATH = TRACKING_DIR.join("opening_sequence_translation.csv")
SUMMARY_PATH = TRACKING_DIR.join("opening_sequence_proofread_summary.md")
BACKUP_PATH = TRACKING_DIR.join("opening_sequence_translation.csv.bak")
DRAFTS_DIR = TRACKING_DIR.join("translation_drafts")
OPENING_MAP_IDS = [22, 42, 32, 76, 78, 79, 80, 83, 88, 90, 92].freeze

MANUAL_DRAFT_FILES = %w[
  Map022_Intro_real_id_draft.md
  Map042_Your_home_id_draft.md
  Map032_Sparrow_Town_id_draft.md
].freeze

EXACT_TEXT_OVERRIDES = {
  "Nah" => "Tidak",
  "Nope" => "Tidak",
  "Nope, solo estoy jugando." => "Tidak, saya hanya bermain.",
  "Sip, soy fotosensible" => "Ya, saya fotosensitif.",
  "Si" => "Ya",
  "Sí" => "Ya",
  "No" => "Tidak",
  "Yes" => "Ya",
  "Antes de empezar, ¿necesitas saber cómo funcionan los controles?" => "Sebelum mulai, apakah kamu perlu tahu cara kerja kontrolnya?",
  "Un par de preguntas antes de empezar..." => "Ada beberapa pertanyaan sebelum kita mulai...",
  "¿Quieres subir este juego a Internet? Esta opción sustituirá algunas canciones que contienen copyright para evitar problemas." => "Apakah kamu ingin mengunggah game ini ke Internet? Opsi ini akan mengganti beberapa lagu berhak cipta untuk menghindari masalah.",
  "Para evitar cualquier problema... ¿Eres fotosensible a algunas luces e iluminación?" => "Untuk menghindari masalah apa pun... apakah kamu sensitif terhadap cahaya atau pencahayaan tertentu?",
  "Selecciona un modo de dificultad." => "Pilih mode kesulitan.",
  "¡Te has puesto las \\c[2]deportivas\\c[0]!" => "Kamu sudah memakai \\c[2]sepatu olahraga\\c[0]!",
  "Lo de que no te hayas puesto las zapatillas antes de bajar, me tiene bailando danza aleteo." => "Kamu turun ke bawah tanpa memakai sepatu dulu? Itu bikin aku geleng-geleng kepala.",
  "¿Qué está pasando?" => "Apa yang sedang terjadi?",
  "No tienes instalado en tu juego el script del" => "Kamu belum memasang script",
  "Monotype. Añádelo para poder usar estas funciones." => "Monotype di game ini. Pasang dulu supaya fitur ini bisa dipakai.",
  "¡Hola! ¿Quieres activar el \\c[2]reto monotipo\\c[0]?" => "Halo! Apa kamu ingin mengaktifkan \\c[2]tantangan monotype\\c[0]?",
  "Solo puedes activarlo si NO es tu primera partida." => "Fitur ini hanya bisa diaktifkan jika ini BUKAN save pertamamu.",
  "Sí, quiero monotipo." => "Ya, saya ingin mode monotype.",
  "No quiero." => "Tidak, saya tidak mau.",
  "Estupendo, a partir de aquí, solo podrás tener Pokémon de dicho tipo." => "Bagus. Mulai sekarang, kamu hanya boleh memiliki Pokémon dengan tipe itu.",
  "¡Nos vemos!" => "Sampai jumpa!",
  "La profesora Álama llegó a Pueblo Gorrión hace como unos 7 años y fue asignada como profesora en la escuela, pero nunca hizo una carrera o algo similar..." => "Profesor Álama datang ke Pueblo Gorrión sekitar tujuh tahun lalu dan ditugaskan mengajar di sekolah, meski ia tidak pernah menjalani karier resmi sebagai Profesor Pokémon...",
  "No sé de dónde ha sacado sus conocimientos sobre los Pokémon, es una chica ciertamente curiosa." => "Aku tidak tahu dari mana ia mendapatkan semua pengetahuan tentang Pokémon. Dia memang gadis yang sangat unik.",
  "\\dxn[Álama]¡Anda! ¡Pues sí, no me había dado cuenta!" => "\\dxn[Álama]Aduh! Benar juga, aku sampai tidak menyadarinya!",
  "\\dxn[Álama]¡Es verdad, qué cabeza la mía!" => "\\dxn[Álama]Benar juga! Waduh, pelupanya aku ini!",
  "\\dxn[Álama]Pues es una buena pregunta, la verdad..." => "\\dxn[Álama]Yah... itu pertanyaan yang bagus juga, sebenarnya...",
  "\\dxn[Álama]¡Parece que les habéis caído bien!" => "\\dxn[Álama]Sepertinya mereka langsung menyukaimu!",
  "\\dxn[Eda]¡Ay! ¡Justamente es el que más me gusta de los dos!" => "\\dxn[Eda]Ah! Justru itu yang paling kusukai dari keduanya!",
  "\\dxn[Darek]Lo mismo digo, Treecko tiene el mismo carácter que yo." => "\\dxn[Darek]Aku juga begitu. Treecko punya sifat yang sama denganku.",
  "\\dxn[Eda]Pero... ¿y \\PN?" => "\\dxn[Eda]Tapi... bagaimana dengan \\PN?",
  "\\dxn[Eda]¿Con qué Pokémon se va a quedar?" => "\\dxn[Eda]Pokémon apa yang akan didapat \\PN?",
  "\\dxn[Álama]¡Espera! ¡Creo que sé qué podemos hacer!" => "\\dxn[Álama]Tunggu! Kurasa aku tahu apa yang bisa kita lakukan!",
  "\\dxn[Álama]Pásate por mi casa en un rato, creo que tengo una solución." => "\\dxn[Álama]Datanglah ke rumahku sebentar lagi. Kurasa aku punya solusinya.",
  "¡Vas con mucha prisa! ¿No quieres un combate?" => "Kamu buru-buru sekali! Tidak mau bertarung dulu?",
  "Si lo llego a saber te dejo ir de primeras..." => "Kalau tahu dari awal, tadi aku biarkan kamu lewat saja...",
  "Esta es la típica ruta en la que sólo hay puro magikarp, vaya tela." => "Ini rute yang terasa sepi sekali. Rasanya cuma Magikarp saja yang ada di sini.",
  "\\dxn[Álama]Al menos no ha volado como Darek, no me ha dado tiempo de darle nada." => "\\dxn[Álama]Untung dia belum kabur seperti Darek. Aku bahkan belum sempat memberinya apa-apa.",
  "\\dxn[Álama]En fin, ya lo pillaré, tú necesitarás una <b>Pokédex</b> y unas <b>Poké Ball</b>." => "\\dxn[Álama]Sudahlah, nanti aku cari dia. Untuk sekarang kamu butuh <b>Pokédex</b> dan beberapa <b>Poké Ball</b>.",
  "\\wtnp[0]¡Has obtenido una <b>Pokédex</b>!\\wt[30]" => "\\wtnp[0]Kamu memperoleh <b>Pokédex</b>!\\wt[30]",
  "\\dxn[Álama]Bueno, ahora sí que sí. Yo me voy a buscar a Darek, que necesitará un <b>Mapa</b> o algo." => "\\dxn[Álama]Nah, sekarang sudah lengkap. Aku pergi mencari Darek dulu. Dia pasti butuh <b>Peta</b> atau semacamnya.",
  "\\dxn[Álama]¡Vamos Psyduck! ¡Quiero ir a una cafetería, que tengo hambre!" => "\\dxn[Álama]Ayo, Psyduck! Aku ingin ke kafe. Aku lapar!",
  "\\dxn[Eda]No sé si llegarán a una cafetería estos dos..." => "\\dxn[Eda]Aku ragu mereka berdua benar-benar akan sampai ke kafe...",
  "\\dxn[Eda]Bueno, tengo que ir en busca de Darek, que la profe dudo que lo encuentre." => "\\dxn[Eda]Baiklah, aku harus menyusul Darek. Jujur saja, aku ragu Bu Profesor bisa menemukannya.",
  "\\dxn[Eda]Aunque Darek parezca tan independiente, en verdad me necesita a su lado. Es capaz de perderse incluso con un mapa." => "\\dxn[Eda]Meski Darek terlihat mandiri, sebenarnya dia butuh aku di sisinya. Bahkan pakai peta pun dia masih bisa tersesat.",
  "\\sh\\dxn[Eda]¡Ahora que caigo!" => "\\sh\\dxn[Eda]Eh, baru kepikiran!",
  "\\dxn[Eda]Hablando de mapas, la profe no nos ha dado un mapa para movernos. Habrá que ir a buscarla." => "\\dxn[Eda]Ngomong-ngomong soal peta, Bu Profesor belum memberi kita peta perjalanan. Kita harus mencarinya.",
  "\\dxn[Eda]¡Me adelanto antes de que la pierda de vista!" => "\\dxn[Eda]Aku duluan sebelum dia hilang dari pandanganku!",
  "Ahora podrás usar la función de \"Encuentros\" del menú para saber qué Pokémon puedes encontrar en cada ruta. ¡Échale un vistazo!" => "Sekarang kamu bisa memakai fitur \"Pertemuan\" di menu untuk melihat Pokémon apa saja yang bisa ditemukan di tiap rute. Coba lihat nanti!"
}.freeze

EXACT_DRAFT_OVERRIDES = {
  "Tidak, aku hanya bermain-main." => "Tidak, saya hanya bermain.",
  "\\c[2]Mode Mudah\\c[0] diperuntukkan bagi orang yang belum terlalu mengenal Pokémon." => "\\c[2]Mode Mudah\\c[0] ditujukan untuk pemain yang belum terlalu akrab dengan Pokémon.",
  "Pokémon Pelatih memiliki level \\c[2]2 lebih sedikit\\c[0]." => "Pokémon milik Trainer memiliki level \\c[2]2 lebih rendah\\c[0].",
  "Anda telah memakai \\c[2]sports\\c[0]!" => "Kamu sudah memakai \\c[2]sepatu olahraga\\c[0]!",
  "\\dxn[Papá]Saya tahu Anda kuat, \\PN, saya yakin Anda akan menemukan Lucario dan bepergian bersama lagi." => "\\dxn[Ayah]Ayah tahu kamu kuat, \\PN. Ayah yakin kamu akan menemukan Lucario dan kembali berpetualang bersamanya.",
  "\\dxn[Papá]Mucho ánimo." => "\\dxn[Ayah]Tetap semangat.",
  "\\dxn[Mamá]Akhirnya kamu sampai di rumah, sayang. Kemana kamu pergi?" => "\\dxn[Ibu]Akhirnya kamu pulang juga, sayang. Dari mana saja?",
  "\\dxn[Mamá]Begitu, jadi Anda akhirnya mendapatkan Pokémon." => "\\dxn[Ibu]Begitu ya, jadi akhirnya kamu berhasil mendapatkan Pokémon.",
  "\\dxn[Mamá]Omong-omong... Dimana catatanmu?" => "\\dxn[Ibu]Ngomong-ngomong... mana nilai rapormu?",
  "Ya, saya ingin monotipe." => "Ya, saya ingin mode monotype.",
  "Anda hanya dapat mengaktifkannya jika ini BUKAN game pertama Anda." => "Fitur ini hanya bisa diaktifkan jika ini BUKAN save pertamamu.",
  "Anda belum menginstal skrip di game Anda." => "Kamu belum memasang script",
  "Monotipe. Tambahkan untuk dapat menggunakan fitur ini." => "Monotype di game ini. Pasang dulu supaya fitur ini bisa dipakai.",
  "\\dxn[Álama]Mereka sepertinya menyukai Anda!" => "\\dxn[Álama]Sepertinya mereka langsung menyukaimu!",
  "\\dxn[Eda]Dan... apa yang akan kita lakukan sekarang?" => "\\dxn[Eda]Lalu... sekarang kita harus bagaimana?",
  "\\dxn[Álama]Datanglah ke rumah saya sebentar lagi, saya rasa saya punya solusinya." => "\\dxn[Álama]Datanglah ke rumahku sebentar lagi. Kurasa aku punya solusinya.",
  "\\dxn[Eda]\\PN! Syukurlah kami menemukanmu tepat waktu!" => "\\dxn[Eda]\\PN! Syukurlah kami berhasil menemukanmu tepat waktu!",
  "\\dxn[Álama]Bagaimanapun, saya akan mengambilnya, Anda memerlukan <b>Pokédex</b> dan beberapa <b>Poké Ball</b>." => "\\dxn[Álama]Sudahlah, nanti aku cari dia. Untuk sekarang kamu butuh <b>Pokédex</b> dan beberapa <b>Poké Ball</b>.",
  "\\dxn[Álama]Nah, sekarang sudah. Saya akan mencari Darek, yang membutuhkan <b>Map</b> atau semacamnya." => "\\dxn[Álama]Nah, sekarang sudah lengkap. Aku pergi mencari Darek dulu. Dia pasti butuh <b>Peta</b> atau semacamnya.",
  "\\dxn[Eda]Saya tidak tahu apakah keduanya akan sampai ke kedai kopi..." => "\\dxn[Eda]Aku ragu mereka berdua benar-benar akan sampai ke kafe...",
  "\\dxn[Eda]Baiklah, saya harus pergi mencari Darek, saya ragu guru akan menemukannya." => "\\dxn[Eda]Baiklah, aku harus menyusul Darek. Jujur saja, aku ragu Bu Profesor bisa menemukannya.",
  "\\dxn[Eda]Meskipun Darek terlihat sangat mandiri, dia sangat membutuhkan saya di sisinya. Dia mampu tersesat bahkan dengan peta." => "\\dxn[Eda]Meski Darek terlihat mandiri, sebenarnya dia butuh aku di sisinya. Bahkan pakai peta pun dia masih bisa tersesat.",
  "\\sh\\dxn[Eda]Sekarang aku terjatuh!" => "\\sh\\dxn[Eda]Eh, baru kepikiran!",
  "\\f[ditto002]Dit....!" => "\\f[ditto002]Dit...!",
  "<ac>Arah Timur: Route 1</ac>" => "<ac>Arah Timur: Rute 1</ac>",
  "\\dxn[Eda]Tunggu.... Bukankah seharusnya ada tiga Pokémon? Hanya ada dua di sana." => "\\dxn[Eda]Tunggu... bukankah seharusnya ada tiga Pokémon? Di sini cuma ada dua.",
  "\\dxn[Ayudante]Ini.... Profesor Álama.... Saya ingatkan Anda bahwa pagi ini pelatih muda itu datang untuk mengambil Pokémonnya." => "\\dxn[Asisten]Ehm... Profesor Álama... saya ingin mengingatkan bahwa tadi pagi ada Trainer muda yang datang untuk mengambil Pokémonnya.",
  "\\dxn[Darek]Saya takut akan hal serupa ketika saya hanya melihat dua Pokémon...." => "\\dxn[Darek]Aku sudah menduga hal seperti ini saat melihat cuma ada dua Pokémon...",
  "\\dxn[Eda]Lalu.... sekarang kita harus bagaimana?" => "\\dxn[Eda]Lalu... sekarang kita harus bagaimana?",
  "Kalau tahu dari awal, tadi aku biarkan kamu lewat saja...." => "Kalau tahu dari awal, tadi aku biarkan kamu lewat saja...",
  "\\dxn[???](Apa yang terjadi?)" => "\\dxn[\\PN](Apa yang terjadi?)",
  "\\dxn[\\PN](Anak itu sepertinya butuh bantuan....)" => "\\dxn[\\PN](Anak itu sepertinya butuh bantuan...)",
  "\\dxn[???]A.... Pelatih? Mengendus, mengendus...." => "\\dxn[???]Se-seorang... Trainer? Hiks, hiks...",
  "\\dxn[???]Saya tahu jika saya mulai menangis seseorang akan membantu saya heh heh heh." => "\\dxn[???]Aku tahu kalau aku pura-pura menangis pasti ada yang mau menolong. Hehe.",
  "\\dxn[???]Ternyata Pokémon saya hilang dan saya tidak tahu di mana letaknya.... Bisakah Anda membantu saya mencarinya?" => "\\dxn[???]Pokémon-ku hilang dan aku tidak tahu dia ada di mana... mau bantu aku mencarinya?",
  "Hanya ada sampah." => "Tidak ada apa-apa selain sampah.",
  "\\dxn[Darek]Wah, saya sudah tersesat.... Saya sangat kesulitan menemukan jalan keluarnya, tolong...." => "\\dxn[Darek]Yah... aku tersesat lagi. Arah memang kelemahanku.",
  "\\dxn[Darek](\\PN kamu tidak bisa berpikir aku tersesat. Aku Darek, Darek yang luar biasa dan sempurna....)" => "\\dxn[Darek](\\PN tidak boleh mengira aku tersesat. Aku ini Darek. Darek yang hebat dan sempurna...)",
  "\\dxn[Darek]Ahem, ahem.... (Batuk)" => "\\dxn[Darek]Ehem, ehem... (batuk)",
  "\\dxn[Darek]Maksudku.... Ini.... Aku di sini menjelajahi area tersebut, mencari Pokémon dan sebagainya!" => "\\dxn[Darek]Maksudku... a-aku memang sedang menjelajahi daerah ini, mencari Pokémon dan semacamnya!",
  "Aku di sini minum soda. Ada banyak mesin penjual otomatis di seluruh wilayah, karena cuaca dan sebagainya. Itu sudah dipikirkan dengan matang." => "Aku sedang menikmati minuman dingin. Karena cuacanya panas, mesin penjual otomatis memang tersebar di seluruh wilayah ini. Ide yang bagus, kan?",
  "<b><ac>PUEBLO FINZÓN</ac></b><ac>Suasananya" => "<b><ac>PUEBLO PINZÓN</ac></b><ac>Suasana",
  "Kota ini sangat ramah dan iklimnya tidak lagi" => "desa ini terasa hangat dan cuacanya tidak lagi",
  "Panas sekali, dingin di malam hari!</ac>" => "terlalu panas. Malam hari justru terasa dingin!</ac>",
  "Saya suka berlatih dengan Pokémon saya, saya tidak peduli apa yang orang tua saya katakan." => "Aku suka berlatih bersama Pokémon-ku. Mau orang tuaku bilang apa pun, aku tidak peduli.",
  "Saya telah melatih Pokémon saya dengan sangat baik. Apakah kamu mau" => "Aku sudah melatih Pokémon-ku dengan baik. Apa kamu mau ",
  "Pergi! Ada Talonflame terbang di sekitar sini. Mungkinkah Anda bisa menemukan Fletchling di area ini?" => "Lihat! Ada Talonflame terbang di sekitar sini. Mungkin Fletchling juga ada di daerah ini?",
  "\\shMenakutkan sekali sobat!" => "\\shWah, kamu bikin kaget saja!",
  "<b><ac>RUTE 3</ac></b><ac>Pelatih dan pejalan kaki berlimpah!</ac>" => "<b><ac>RUTE 3</ac></b><ac>Trainer dan pendaki memenuhi rute ini!</ac>",
  "Saya sudah mulai berolahraga, saya tidak tahu apakah itu terlihat." => "Aku baru mulai rajin olahraga. Kelihatan, tidak?",
  "Cucu saya melakukan petualangan seperti Anda. Namun, aku belum menerima pesan apa pun darinya sejak itu, aku khawatir...." => "Cucuku juga pergi berpetualang sepertimu. Tapi sejak itu aku belum menerima kabar darinya. Aku khawatir...",
  "saya sedang joging. Saya berencana pergi ke \\c[2]Ciudad Ninfa\\c[0] dan mandi." => "Aku sedang jogging. Rencananya aku mau sampai ke \\c[2]Ciudad Ninfa\\c[0] lalu berendam di sana.",
  "Aku pernah bertemu gadis ini, tapi dia hanya bercerita kepadaku tentang betapa panasnya saat itu, betapa membosankannya kencan itu...." => "Aku janjian dengan gadis ini, tapi dari tadi dia cuma membahas cuaca panas. Kencan yang membosankan sekali...",
  "Hidrasi itu penting banget nih nak, nih." => "Menjaga tubuh tetap terhidrasi itu penting. Nih, Nak, ambil ini.",
  "Hidrasi sangat penting, ini nak, ini." => "Menjaga tubuh tetap terhidrasi itu penting. Nih, Nak, ambil ini.",
  "Jangan berterima kasih padaku, kalian anak muda harus menjaga dirimu sendiri" => "Tak usah berterima kasih. Anak muda juga harus menjaga diri ",
  "Saya suka berlari, tapi saya juga suka bertarung!" => "Aku suka berlari, tapi aku juga suka bertarung!",
  "Aku akan terus berlari sampai aku mati!" => "Aku akan terus berlari sampai benar-benar tumbang!",
  "Sejujurnya, saya lebih suka Pokémon sungai. Para Gyarado ini bisa melarikan diri dengan lebih mudah." => "Sejujurnya, aku lebih suka Pokémon sungai. Gyarados di sini lebih gampang lepas.",
  "Bahkan tidak bercanda aku beranjak dari bayangan, betapa malasnya." => "Jangan harap aku keluar dari tempat teduh. Panas begini bikin malas.",
  "\\dxn[Niño]Ayah, Ayah, aku rindu itu!" => "\\dxn[Anak]Ayah, Ayah! Lepas! Lepas!",
  "<b><ac>Ciudad Calentra</ac></b><ac>Kota yang sangat tenang dengan pantai!</ac><ac>" => "<b><ac>Ciudad Calentra</ac></b><ac>Kota pantai yang tenang dan nyaman!</ac><ac>",
  "Saya pulang kerja cukup larut.... Bir dan pulang." => "Aku pulang kerja cukup malam... minum sebentar lalu langsung pulang.",
  "Saya memahami bahwa Gym Leader di kota ini menggunakan Pokémon tipe Fighting." => "Katanya Gym Leader di kota ini memakai Pokémon tipe Fighting.",
  "Saya menyirami tanaman kecil saya, dalam cuaca seperti ini mereka tumbuh dengan baik!" => "Aku sedang menyiram tanamanku. Dengan cuaca seperti ini, mereka tumbuh dengan sangat baik!",
  "Apa yang kamu inginkan? saya sedang bekerja." => "Ada apa? Aku sedang bekerja.",
  "Saya berlatih untuk bisa melawan pemimpin kota ini." => "Aku sedang berlatih supaya bisa menantang pemimpin kota ini.",
  "Betapa melelahkannya harus bekerja untuk \\c[2]Keluarga Kerajaan\\c[0]...." => "Melelahkan juga harus bekerja untuk \\c[2]Keluarga Kerajaan\\c[0]...",
  "Saya belajar menjadi pengacara. Tepat sekali, yang saya gantung di sini." => "Aku kuliah hukum untuk menjadi pengacara. Ijazahnya itu, yang tergantung di sana."
}.freeze

GENERIC_REPLACEMENTS = [
  [/\bberkelahi\b/i, "bertarung"],
  [/\brocks\b/i, "batu"],
  [/\bMap\b/, "Peta"],
  [/\bRoute\b/, "Rute"],
  [/\bsports\b/, "sepatu olahraga"],
  [/\bgerakan\b/i, "jurus"],
  [/\bROUTE\b/, "RUTE"],
  [/\s+\./, "."],
  [/\s+,/, ","],
  [/\s+!/, "!"],
  [/\s+\?/, "?"]
].freeze

def parse_manual_overrides
  overrides = {}
  MANUAL_DRAFT_FILES.each do |filename|
    path = DRAFTS_DIR.join(filename)
    next unless path.exist?
    path.each_line do |line|
      match = line.match(/^\| `(.*)` \| `(.*)` \|$/)
      overrides[match[1]] = match[2] if match
    end
  end
  overrides
end

def proofread_text(original, draft, manual_overrides)
  original = original.to_s.gsub(/\r\n?/, "\n").strip
  draft = draft.to_s.gsub(/\r\n?/, "\n").strip
  result = manual_overrides[original] || EXACT_TEXT_OVERRIDES[original] || EXACT_DRAFT_OVERRIDES[draft] || draft
  EXACT_DRAFT_OVERRIDES.each { |from, to| result = result.gsub(from, to) }
  GENERIC_REPLACEMENTS.each { |pattern, replacement| result = result.gsub(pattern, replacement) }
  result = result.gsub(/\.{4,}/, "...")
  result = result.gsub(/ \.\.\./, "...")
  result.strip
end

rows = CSV.read(CSV_PATH, headers: true)
manual_overrides = parse_manual_overrides
FileUtils.cp(CSV_PATH, BACKUP_PATH)

proofread_count = 0
per_source = Hash.new(0)

rows.each do |row|
  next unless OPENING_MAP_IDS.include?(row["source_id"].to_i)
  next if row["draft_status"].start_with?("skip_")
  next if row["draft_id"].to_s.empty?

  row["draft_id"] = proofread_text(row["text"], row["draft_id"], manual_overrides)
  row["draft_status"] = "proofread_opening"
  proofread_count += 1
  per_source[row["source_id"].to_i] += 1
end

CSV.open(CSV_PATH, "w", write_headers: true, headers: rows.headers) do |csv|
  rows.each { |row| csv << row }
end

SUMMARY_PATH.write(<<~MD)
  # Opening Sequence Proofread Summary

  - Source CSV: `tracking/opening_sequence_translation.csv`
  - Backup: `tracking/opening_sequence_translation.csv.bak`
  - Opening map count: #{OPENING_MAP_IDS.size}
  - Proofread rows updated: #{proofread_count}
  - Status applied: `proofread_opening`

  ## Rows Per Map
  #{OPENING_MAP_IDS.map { |id| "- Map#{format('%03d', id)}: #{per_source[id]}" }.join("\n")}
MD

puts "csv=#{CSV_PATH}"
puts "backup=#{BACKUP_PATH}"
puts "summary=#{SUMMARY_PATH}"
puts "proofread_rows=#{proofread_count}"
