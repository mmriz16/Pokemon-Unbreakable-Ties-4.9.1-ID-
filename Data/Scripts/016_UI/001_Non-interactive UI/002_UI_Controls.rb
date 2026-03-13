#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Shows a help screen listing the keyboard controls.
# Display with:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super
    Graphics.freeze
    @current_screen = 1
    addImage(0, 0, "Graphics/Pictures/Controls help/help_bg")
    @labels = []
    @label_screens = []
    @keys = []
    @key_screens = []

    addImageForScreen(1, 44, 122, "Graphics/Pictures/Controls help/help_f1")
    addImageForScreen(1, 44, 252, "Graphics/Pictures/Controls help/help_f8")
    addLabelForScreen(1, 134, 84, 352, _INTL("Membuka jendela Key Bindings, tempat Anda dapat memilih tombol keyboard mana yang akan digunakan untuk setiap kontrol."))
    addLabelForScreen(1, 134, 244, 352, _INTL("Ambil tangkapan layar. Itu ditempatkan di folder yang sama dengan file penyimpanan."))

    addImageForScreen(2, 16, 158, "Graphics/Pictures/Controls help/help_arrows")
    addLabelForScreen(2, 134, 100, 352, _INTL("Gunakan tombol Panah untuk memindahkan karakter utama.\r\n\r\nAnda juga dapat menggunakan tombol Panah untuk memilih entri dan menavigasi menu."))

    addImageForScreen(3, 16, 106, "Graphics/Pictures/Controls help/help_usekey")
    addImageForScreen(3, 16, 236, "Graphics/Pictures/Controls help/help_backkey")
    addLabelForScreen(3, 134, 84, 352, _INTL("Digunakan untuk mengonfirmasi pilihan, berinteraksi dengan orang dan benda, dan menelusuri teks. (Bawaan: C)"))
    addLabelForScreen(3, 134, 212, 352, _INTL("Digunakan untuk keluar, membatalkan pilihan, dan membatalkan mode. Juga digunakan untuk membuka Menu Jeda. (Bawaan: X)"))

    addImageForScreen(4, 16, 90, "Graphics/Pictures/Controls help/help_actionkey")
    addImageForScreen(4, 16, 252, "Graphics/Pictures/Controls help/help_specialkey")
    addLabelForScreen(4, 134, 52, 352, _INTL("Memiliki berbagai fungsi tergantung konteksnya. Saat bergerak, tahan untuk bergerak dengan kecepatan berbeda. (Bawaan: Z)"))
    addLabelForScreen(4, 134, 212, 352, _INTL("Tekan untuk membuka Menu Siap, dimana item terdaftar dan perpindahan bidang yang tersedia dapat digunakan. (Bawaan: D)"))

    set_up_screen(@current_screen)
    Graphics.transition(20)
    # Go to next screen when user presses USE
    onCTrigger.set(method(:pbOnScreenEnd))
  end

  def addLabelForScreen(number, x, y, width, text)
    @labels.push(addLabel(x, y, width, text))
    @label_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def addImageForScreen(number, x, y, filename)
    @keys.push(addImage(x, y, filename))
    @key_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def set_up_screen(number)
    @label_screens.each_with_index do |screen, i|
      @labels[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    @key_screens.each_with_index do |screen, i|
      @keys[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    pictureWait   # Update event scene with the changes
  end

  def pbOnScreenEnd(scene, *args)
    last_screen = [@label_screens.max, @key_screens.max].max
    if @current_screen >= last_screen
      # End scene
      Graphics.freeze
      Graphics.transition(20, "fadetoblack")
      scene.dispose
    else
      # Next screen
      @current_screen += 1
      onCTrigger.clear
      set_up_screen(@current_screen)
      onCTrigger.set(method(:pbOnScreenEnd))
    end
  end
end
