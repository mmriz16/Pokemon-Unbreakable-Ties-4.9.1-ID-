#===============================================================================
#
#===============================================================================
class TrainerPC
  def shouldShow?
    return false
  end

  def name
   return _INTL("PC {1}",$Trainer.name)
  end

  def access
    pbMessage(_INTL("\\se[PC access]Mengakses PC {1}.",$Trainer.name))
    pbTrainerPCMenu
  end
end

#===============================================================================
#
#===============================================================================
class StorageSystemPC
  def shouldShow?
    return true
  end

  def name
    if $Trainer.seen_storage_creator
      return _INTL("PC {1}",pbGetStorageCreator)
    else
      return _INTL("Buka PC {1}", $Trainer.name)
    end
  end

  def access
    pbMessage(_INTL("\\se[PC access]Sistem Penyimpanan Pokémon telah dibuka."))
    command = 0
    loop do
      command = pbShowCommandsWithHelp(nil,
         [_INTL("Atur Kotak"),
         _INTL("Tarik Pokemon"),
         _INTL("Setor Pokemon"),
         _INTL("Sampai jumpa!")],
         [_INTL("Atur Pokemon Anda di dalam kotak dan di party Anda."),
         _INTL("Pindahkan Pokemon dari kotak ke party Anda."),
         _INTL("Simpan Pokemon dari party Anda ke dalam kotak."),
         _INTL("Kembali ke menu pilihan.")],-1,command
      )
      if command>=0 && command<3
        if command==1   # Withdraw
          if $PokemonStorage.party_full?
            pbMessage(_INTL("Pestamu penuh!"))
            next
          end
        elsif command==2   # Deposit
          count=0
          for p in $PokemonStorage.party
            count += 1 if p && !p.egg? && p.hp>0
          end
          if count<=1
            pbMessage(_INTL("Anda tidak dapat menyimpan Pokemon terakhir!"))
            next
          end
        end
        pbFadeOutIn {
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene,$PokemonStorage)
          screen.pbStartScreen(command)
        }
      else
        break
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
module PokemonPCList
  @@pclist = []

  def self.registerPC(pc)
    @@pclist.push(pc)
  end

  def self.getCommandList
    commands = []
    for pc in @@pclist
      commands.push(pc.name) if pc.shouldShow?
    end
    commands.push(_INTL("Matikan PC"))
    return commands
  end

  def self.callCommand(cmd)
    return false if cmd<0 || cmd>=@@pclist.length
    i = 0
    for pc in @@pclist
      next if !pc.shouldShow?
      if i==cmd
        pc.access
        return true
      end
      i += 1
    end
    return false
  end
end

#===============================================================================
# PC menus
#===============================================================================
def pbPCItemStorage
  command = 0
  loop do
    command = pbShowCommandsWithHelp(nil,
       [_INTL("Penarikan Barang"),
       _INTL("Barang Setoran"),
       _INTL("Barang Lempar"),
       _INTL("KELUAR")],
       [_INTL("Keluarkan item dari PC."),
       _INTL("Simpan item di PC."),
       _INTL("Buang barang-barang yang tersimpan di PC."),
       _INTL("Kembali ke menu sebelumnya.")],-1,command
    )
    case command
    when 0   # Withdraw Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("Tidak ada item."))
      else
        pbFadeOutIn {
          scene = WithdrawItemScene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          screen.pbWithdrawItemScreen
        }
      end
    when 1   # Deposit Item
      pbFadeOutIn {
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene,$PokemonBag)
        screen.pbDepositItemScreen
      }
    when 2   # Toss Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("Tidak ada item."))
      else
        pbFadeOutIn {
          scene = TossItemScene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          screen.pbTossItemScreen
        }
      end
    else
      break
    end
  end
end

def pbPCMailbox
  if !$PokemonGlobal.mailbox || $PokemonGlobal.mailbox.length==0
    pbMessage(_INTL("Tidak ada Mail di sini."))
  else
    loop do
      command = 0
      commands=[]
      for mail in $PokemonGlobal.mailbox
        commands.push(mail.sender)
      end
      commands.push(_INTL("Batal"))
      command = pbShowCommands(nil,commands,-1,command)
      if command>=0 && command<$PokemonGlobal.mailbox.length
        mailIndex = command
        commandMail = pbMessage(_INTL("Apa yang ingin Anda lakukan dengan Email {1}?",
           $PokemonGlobal.mailbox[mailIndex].sender),[
           _INTL("Membaca"),
           _INTL("Pindah ke Tas"),
           _INTL("Memberi"),
           _INTL("Batal")
           ],-1)
        case commandMail
        when 0   # Read
          pbFadeOutIn {
            pbDisplayMail($PokemonGlobal.mailbox[mailIndex])
          }
        when 1   # Move to Bag
          if pbConfirmMessage(_INTL("Pesannya akan hilang. Apakah itu oke?"))
            if $PokemonBag.pbStoreItem($PokemonGlobal.mailbox[mailIndex].item)
              pbMessage(_INTL("Surat dikembalikan ke Tas dengan pesannya terhapus."))
              $PokemonGlobal.mailbox.delete_at(mailIndex)
            else
              pbMessage(_INTL("Tasnya penuh."))
            end
          end
        when 2   # Give
          pbFadeOutIn {
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
            sscreen.pbPokemonGiveMailScreen(mailIndex)
          }
        end
      else
        break
      end
    end
  end
end

def pbTrainerPCMenu
  command = 0
  loop do
    command = pbMessage(_INTL("Apa yang ingin kamu lakukan?"),[
       _INTL("Penyimpanan Barang"),
       _INTL("Kotak surat"),
       _INTL("Mematikan")
       ],-1,nil,command)
    case command
    when 0 then pbPCItemStorage
    when 1 then pbPCMailbox
    else        break
    end
  end
end

def pbTrainerPC
  pbMessage(_INTL("\\se[PC open]{1} mem-boot PC.",$Trainer.name))
  pbTrainerPCMenu
  pbSEPlay("PC close")
end

def pbPokeCenterPC
  pbMessage(_INTL("\\se[PC open]{1} mem-boot PC.",$Trainer.name))
  command = 0
  loop do
    commands = PokemonPCList.getCommandList
    command = pbMessage(_INTL("Apa yang ingin Anda lakukan dengan PC Anda?"),commands,
       commands.length,nil,command)
    break if !PokemonPCList.callCommand(command)
  end
  pbSEPlay("PC close")
end

def pbGetStorageCreator
  creator = Settings.storage_creator_name
  creator = _INTL("Tagihan") if nil_or_empty?(creator)
  return creator
end

#===============================================================================
#
#===============================================================================
PokemonPCList.registerPC(StorageSystemPC.new)
PokemonPCList.registerPC(TrainerPC.new)


