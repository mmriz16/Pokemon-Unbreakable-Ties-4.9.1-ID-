#===============================================================================
# Mystery Gift system
# By Maruno
#===============================================================================
# This url is the location of an example Mystery Gift file.
# You should change it to your file's url once you upload it.
#===============================================================================
module MysteryGift
  URL = "https://pastebin.com/raw/w6BqqUsm"
end

#===============================================================================
# Creating a new Mystery Gift for the Master file, and editing an existing one.
#===============================================================================
# type: 0=Pokémon; 1 or higher=item (is the item's quantity).
# item: The thing being turned into a Mystery Gift (Pokémon object or item ID).
def pbEditMysteryGift(type,item,id=0,giftname="")
  begin
    if type==0   # Pokémon
      commands=[_INTL("Hadiah Misteri"),
                _INTL("Tempat yang jauh")]
      commands.push(item.obtain_text) if item.obtain_text && !item.obtain_text.empty?
      commands.push(_INTL("[Custom]"))
      loop do
        command=pbMessage(
           _INTL("Pilih frasa yang menjadi tempat asal hadiah PokÃ©mon."),commands,-1)
        if command<0
          return nil if pbConfirmMessage(_INTL("Berhenti mengedit hadiah ini?"))
        elsif command<commands.length-1
          item.obtain_text = commands[command]
          break
        elsif command==commands.length-1
          obtainname=pbMessageFreeText(_INTL("Masukkan frasa."),"",false,30)
          if obtainname!=""
            item.obtain_text = obtainname
            break
          end
          return nil if pbConfirmMessage(_INTL("Berhenti mengedit hadiah ini?"))
        end
      end
    elsif type>0   # Item
      params=ChooseNumberParams.new
      params.setRange(1,99999)
      params.setDefaultValue(type)
      params.setCancelValue(0)
      loop do
        newtype=pbMessageChooseNumber(_INTL("Pilih jumlah {1}.",
           GameData::Item.get(item).name),params)
        if newtype==0
          return nil if pbConfirmMessage(_INTL("Berhenti mengedit hadiah ini?"))
        else
          type=newtype
          break
        end
      end
    end
    if id==0
      master=[]
      idlist=[]
      if safeExists?("MysteryGiftMaster.txt")
        master=IO.read("MysteryGiftMaster.txt")
        master=pbMysteryGiftDecrypt(master)
      end
      for i in master; idlist.push(i[0]); end
      params=ChooseNumberParams.new
      params.setRange(0,99999)
      params.setDefaultValue(id)
      params.setCancelValue(0)
      loop do
        newid=pbMessageChooseNumber(_INTL("Pilih ID unik untuk hadiah ini."),params)
        if newid==0
          return nil if pbConfirmMessage(_INTL("Berhenti mengedit hadiah ini?"))
        else
          if idlist.include?(newid)
            pbMessage(_INTL("ID tersebut sudah digunakan oleh Hadiah Misteri."))
          else
            id=newid
            break
          end
        end
      end
    end
    loop do
      newgiftname=pbMessageFreeText(_INTL("Masukkan nama untuk hadiahnya."),giftname,false,250)
      if newgiftname!=""
        giftname=newgiftname
        break
      end
      return nil if pbConfirmMessage(_INTL("Berhenti mengedit hadiah ini?"))
    end
    return [id,type,item,giftname]
  rescue
    pbMessage(_INTL("Tidak dapat mengedit hadiah."))
    return nil
  end
end

def pbCreateMysteryGift(type,item)
  gift=pbEditMysteryGift(type,item)
  if !gift
    pbMessage(_INTL("Tidak membuat hadiah."))
  else
    begin
      if safeExists?("MysteryGiftMaster.txt")
        master=IO.read("MysteryGiftMaster.txt")
        master=pbMysteryGiftDecrypt(master)
        master.push(gift)
      else
        master=[gift]
      end
      string=pbMysteryGiftEncrypt(master)
      File.open("MysteryGiftMaster.txt","wb") { |f| f.write(string) }
      pbMessage(_INTL("Hadiah telah disimpan ke MysteryGiftMaster.txt."))
    rescue
      pbMessage(_INTL("Tidak dapat menyimpan hadiah ke MysteryGiftMaster.txt."))
    end
  end
end

#===============================================================================
# Debug option for managing gifts in the Master file and exporting them to a
# file to be uploaded.
#===============================================================================
def pbManageMysteryGifts
  if !safeExists?("MysteryGiftMaster.txt")
    pbMessage(_INTL("Tidak ada Hadiah Misteri yang ditentukan."))
    return
  end
  # Load all gifts from the Master file.
  master=IO.read("MysteryGiftMaster.txt")
  master=pbMysteryGiftDecrypt(master)
  if !master || !master.is_a?(Array) || master.length==0
    pbMessage(_INTL("Tidak ada Hadiah Misteri yang ditentukan."))
    return
  end
  # Download all gifts from online
  msgwindow=pbCreateMessageWindow
  pbMessageDisplay(msgwindow,_INTL("Mencari hadiah online...\\wtnp[0]"))
  online = pbDownloadToString(MysteryGift::URL)
  pbDisposeMessageWindow(msgwindow)
  if nil_or_empty?(online)
    pbMessage(_INTL("Tidak ditemukan Hadiah Misteri online.\\wtnp[20]"))
    online=[]
  else
    pbMessage(_INTL("Hadiah Misteri Online ditemukan.\\wtnp[20]"))
    online=pbMysteryGiftDecrypt(online)
    t=[]
    online.each { |gift| t.push(gift[0]) }
    online=t
  end
  # Show list of all gifts.
  command=0
  loop do
    commands=pbRefreshMGCommands(master,online)
    command=pbMessage(_INTL("\\ts[]Kelola Hadiah Misteri (X=online)."),commands,-1,nil,command)
    # Gift chosen
    if command==-1 || command==commands.length-1   # Cancel
      break
    elsif command==commands.length-2   # Export selected to file
      begin
        newfile=[]
        for gift in master
          newfile.push(gift) if online.include?(gift[0])
        end
        string=pbMysteryGiftEncrypt(newfile)
        File.open("MysteryGift.txt","wb") { |f| f.write(string) }
        pbMessage(_INTL("Hadiah disimpan ke MysteryGift.txt."))
        pbMessage(_INTL("Unggah MysteryGift.txt ke Internet."))
      rescue
        pbMessage(_INTL("Tidak dapat menyimpan hadiah ke MysteryGift.txt."))
      end
    elsif command>=0 && command<commands.length-2   # A gift
      cmd=0
      loop do
        commands=pbRefreshMGCommands(master,online)
        gift=master[command]
        cmds=[_INTL("Aktifkan/luring"),
              _INTL("Sunting"),
              _INTL("Menerima"),
              _INTL("Menghapus"),
              _INTL("Batal")]
        cmd=pbMessage("\\ts[]"+commands[command],cmds,-1,nil,cmd)
        if cmd==-1 || cmd==cmds.length-1
          break
        elsif cmd==0   # Toggle on/offline
          if online.include?(gift[0])
            for i in 0...online.length
              online[i]=nil if online[i]==gift[0]
            end
            online.compact!
          else
            online.push(gift[0])
          end
        elsif cmd==1   # Edit
          newgift=pbEditMysteryGift(gift[1],gift[2],gift[0],gift[3])
          master[command]=newgift if newgift
        elsif cmd==2   # Receive
          if !$Trainer
            pbMessage(_INTL("Tidak ada file simpanan yang dimuat. Tidak dapat menerima hadiah apa pun."))
            next
          end
          replaced=false
          for i in 0...$Trainer.mystery_gifts.length
            if $Trainer.mystery_gifts[i][0]==gift[0]
              $Trainer.mystery_gifts[i]=gift; replaced=true
            end
          end
          $Trainer.mystery_gifts.push(gift) if !replaced
          pbReceiveMysteryGift(gift[0])
        elsif cmd==3   # Delete
          if pbConfirmMessage(_INTL("Apakah Anda yakin ingin menghapus hadiah ini?"))
            master[command]=nil
            master.compact!
          end
          break
        end
      end
    end
  end
end

def pbRefreshMGCommands(master, online)
  commands = []
  for gift in master
    itemname = "BLANK"
    if gift[1] == 0
      itemname = gift[2].speciesName
    elsif gift[1] > 0
      itemname = GameData::Item.get(gift[2]).name + sprintf(" x%d", gift[1])
    end
    ontext = ["[  ]", "[X]"][(online.include?(gift[0])) ? 1 : 0]
    commands.push(_INTL("{1} {2}: {3} ({4})", ontext, gift[0], gift[3], itemname))
  end
  commands.push(_INTL("Ekspor yang dipilih ke file"))
  commands.push(_INTL("Batal"))
  return commands
end

#===============================================================================
# Downloads all available Mystery Gifts that haven't been downloaded yet.
#===============================================================================
# Called from the Continue/New Game screen.
def pbDownloadMysteryGift(trainer)
  sprites={}
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  addBackgroundPlane(sprites,"background","mysteryGiftbg",viewport)
  pbFadeInAndShow(sprites)
  sprites["msgwindow"]=pbCreateMessageWindow
  pbMessageDisplay(sprites["msgwindow"],_INTL("Mencari hadiah.\nHarap tunggu...\\wtnp[0]"))
  string = pbDownloadToString(MysteryGift::URL)
  if nil_or_empty?(string)
    pbMessageDisplay(sprites["msgwindow"],_INTL("Tidak ada hadiah baru yang tersedia."))
  else
    online=pbMysteryGiftDecrypt(string)
    pending=[]
    for gift in online
      notgot=true
      for j in trainer.mystery_gifts
        notgot=false if j[0]==gift[0]
      end
      pending.push(gift) if notgot
    end
    if pending.length==0
      pbMessageDisplay(sprites["msgwindow"],_INTL("Tidak ada hadiah baru yang tersedia."))
    else
      loop do
        commands=[]
        for gift in pending; commands.push(gift[3]); end
        commands.push(_INTL("Batal"))
        pbMessageDisplay(sprites["msgwindow"],_INTL("Pilih hadiah yang ingin Anda terima.\\wtnp[0]"))
        command=pbShowCommands(sprites["msgwindow"],commands,-1)
        if command==-1 || command==commands.length-1
          break
        else
          gift=pending[command]
          sprites["msgwindow"].visible=false
          if gift[1]==0
            sprite=PokemonSprite.new(viewport)
            sprite.setOffset(PictureOrigin::Center)
            sprite.setPokemonBitmap(gift[2])
            sprite.x=Graphics.width/2
            sprite.y=-sprite.bitmap.height/2
          else
            sprite=ItemIconSprite.new(0,0,gift[2],viewport)
            sprite.x=Graphics.width/2
            sprite.y=-sprite.height/2
          end
          distanceDiff = 8*20/Graphics.frame_rate
          loop do
            Graphics.update
            Input.update
            sprite.update
            sprite.y+=distanceDiff
            break if sprite.y>=Graphics.height/2
          end
          pbMEPlay("Battle capture success")
          (Graphics.frame_rate*3).times do
            Graphics.update
            Input.update
            sprite.update
            pbUpdateSceneMap
          end
          sprites["msgwindow"].visible=true
          pbMessageDisplay(sprites["msgwindow"],_INTL("Hadiah telah diterima!")) { sprite.update }
          pbMessageDisplay(sprites["msgwindow"],_INTL("Silakan ambil hadiah Anda dari pengantar di PokÃ© Mart mana pun.")) { sprite.update }
          trainer.mystery_gifts.push(gift)
          pending[command]=nil; pending.compact!
          opacityDiff = 16*20/Graphics.frame_rate
          loop do
            Graphics.update
            Input.update
            sprite.update
            sprite.opacity-=opacityDiff
            break if sprite.opacity<=0
          end
          sprite.dispose
        end
        if pending.length==0
          pbMessageDisplay(sprites["msgwindow"],_INTL("Tidak ada hadiah baru yang tersedia."))
          break
        end
      end
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeMessageWindow(sprites["msgwindow"])
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end

#===============================================================================
# Converts an array of gifts into a string and back.
#===============================================================================
def pbMysteryGiftEncrypt(gift)
  ret=[Zlib::Deflate.deflate(Marshal.dump(gift))].pack("m")
  return ret
end

def pbMysteryGiftDecrypt(gift)
  return [] if nil_or_empty?(gift)
  ret = Marshal.restore(Zlib::Inflate.inflate(gift.unpack("m")[0]))
  if ret
    ret.each do |gift|
      if gift[1] == 0   # Pokémon
        gift[2] = PokeBattle_Pokemon.convert(gift[2])
      else   # Item
        gift[2] = GameData::Item.get(gift[2]).id
      end
    end
  end
  return ret
end

#===============================================================================
# Collecting a Mystery Gift from the deliveryman.
#===============================================================================
def pbNextMysteryGiftID
  for i in $Trainer.mystery_gifts
    return i[0] if i.length>1
  end
  return 0
end

def pbReceiveMysteryGift(id)
  index=-1
  for i in 0...$Trainer.mystery_gifts.length
    if $Trainer.mystery_gifts[i][0]==id && $Trainer.mystery_gifts[i].length>1
      index=i
      break
    end
  end
  if index==-1
    pbMessage(_INTL("Tidak dapat menemukan Hadiah Misteri yang belum diklaim dengan ID {1}.",id))
    return false
  end
  gift=$Trainer.mystery_gifts[index]
  if gift[1]==0   # Pokémon
    gift[2].personalID = rand(2**16) | rand(2**16) << 16
    gift[2].calc_stats
    time=pbGetTimeNow
    gift[2].timeReceived=time.getgm.to_i
    gift[2].obtain_method = 4   # Fateful encounter
    gift[2].record_first_moves
    if $game_map
      gift[2].obtain_map=$game_map.map_id
      gift[2].obtain_level=gift[2].level
    else
      gift[2].obtain_map=0
      gift[2].obtain_level=gift[2].level
    end
    if pbAddPokemonSilent(gift[2])
      pbMessage(_INTL("\\me[Pkmn get]{1} menerima {2}!",$Trainer.name,gift[2].name))
      $Trainer.mystery_gifts[index]=[id]
      return true
    end
  elsif gift[1]>0   # Item
    item=gift[2]
    qty=gift[1]
    if $PokemonBag.pbCanStore?(item,qty)
      $PokemonBag.pbStoreItem(item,qty)
      itm = GameData::Item.get(item)
      itemname=(qty>1) ? itm.name_plural : itm.name
      if item == :LEFTOVERS
        pbMessage(_INTL("\\me[Item get]Anda memperoleh beberapa \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
      elsif itm.is_machine?   # TM or HM
        pbMessage(_INTL("\\me[Item get]Anda memperoleh \\c[1]{1} {2}\\c[0]!\\wtnp[30]",itemname,
           GameData::Move.get(itm.move).name))
      elsif qty>1
        pbMessage(_INTL("\\me[Item get]Anda memperoleh {1} \\c[1]{2}\\c[0]!\\wtnp[30]",qty,itemname))
      elsif itemname.starts_with_vowel?
        pbMessage(_INTL("\\me[Item get]Anda memperoleh \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
      else
        pbMessage(_INTL("\\me[Item get]Anda memperoleh \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
      end
      $Trainer.mystery_gifts[index]=[id]
      return true
    end
  end
  return false
end
