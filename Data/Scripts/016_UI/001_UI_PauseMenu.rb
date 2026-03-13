#===============================================================================
#
#===============================================================================
class PokemonPauseMenu_Scene
  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["helpwindow"].visible = false
    @infostate = false
    @helpstate = false
    pbSEPlay("GUI menu open")
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text,Graphics.height)
    @sprites["infowindow"].text    = text
    @sprites["infowindow"].visible = true
    @infostate = true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text,Graphics.height)
    @sprites["helpwindow"].text    = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
    @helpstate = true
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = true
    @sprites["infowindow"].visible = @infostate
    @sprites["helpwindow"].visible = @helpstate
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"].visible = false
  end

  def pbShowCommands(commands)
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = commands
    cmdwindow.index    = $PokemonTemp.menuLastChoice
    cmdwindow.resizeToFit(commands)
    cmdwindow.x        = Graphics.width-cmdwindow.width
    cmdwindow.y        = 0
    cmdwindow.visible  = true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::BACK)
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = cmdwindow.index
        $PokemonTemp.menuLastChoice = ret
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh; end
end

#===============================================================================
#
#===============================================================================
class PokemonPauseMenu
  def initialize(scene)
    @scene = scene
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbStartPokemonMenu
    if !$Trainer
      if $DEBUG
        pbMessage(_INTL("Pelatih pemain tidak ditentukan, sehingga menu jeda tidak dapat ditampilkan."))
        pbMessage(_INTL("Silakan lihat dokumentasi untuk mempelajari cara menyiapkan pemutar pelatih."))
      end
      return
    end
    @scene.pbStartScene
    endscene = true
    commands = []
    cmdLogros = -1
    cmdPokedex  = -1
    cmdPokemon  = -1
    cmdBag      = -1
    cmdTrainer  = -1
    cmdSave     = -1
    cmdOption   = -1
    cmdPokegear = -1
    cmdDebug    = -1
    cmdQuit     = -1
    cmdEndGame  = -1
    cmdEncounter = -1
    cmdSwitch   = -1 

    if $Trainer.has_pokedex && $Trainer.pokedex.accessible_dexes.length > 0
      commands[cmdPokedex = commands.length] = _INTL("Pokedex")
    end
    commands[cmdPokemon = commands.length]   = _INTL("Pokemon") if $Trainer.party_count > 0
    commands[cmdBag = commands.length]       = _INTL("Tas") if !pbInBugContest?
    commands[cmdPokegear = commands.length]  = _INTL("Pokegear") if $Trainer.has_pokegear
    commands[cmdEncounter = commands.length] = _INTL("Pertemuan")
    commands[cmdLogros = commands.length] = _INTL("Prestasi")
    commands[cmdTrainer = commands.length]   = $Trainer.name

     if $PokemonGlobal.commandCharacterSwitchOn && !pbInSafari? &&
           !pbInBugContest? && !pbBattleChallenge.pbInProgress?
       commands[cmdSwitch = commands.length] = _INTL("Ganti")
     end

    if pbInSafari?
      if Settings::SAFARI_STEPS <= 0
        @scene.pbShowInfo(_INTL("Bola: {1}",pbSafariState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Langkah-langkah: {1}/{2}\nBola: {3}",
           pbSafariState.steps, Settings::SAFARI_STEPS, pbSafariState.ballcount))
      end
      commands[cmdQuit = commands.length]    = _INTL("Keluar")
    elsif pbInBugContest?
      if pbBugContestState.lastPokemon
        @scene.pbShowInfo(_INTL("Tertangkap: {1}\nTingkat: {2}\nBola: {3}",
           pbBugContestState.lastPokemon.speciesName,
           pbBugContestState.lastPokemon.level,
           pbBugContestState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Tertangkap: Tidak ada\nBola: {1}",pbBugContestState.ballcount))
      end
      commands[cmdQuit = commands.length]    = _INTL("Keluar dari Kontes")
    else
      commands[cmdSave = commands.length]    = _INTL("Simpan") if $game_system && !$game_system.save_disabled
    end
    commands[cmdOption = commands.length]    = _INTL("Opsi")
    commands[cmdDebug = commands.length]     = _INTL("Men-debug") if $DEBUG
    commands[cmdEndGame = commands.length]   = _INTL("Keluar dari Game")
    loop do
      command = @scene.pbShowCommands(commands)
      if cmdPokedex>=0 && command==cmdPokedex
        pbPlayDecisionSE
        if Settings::USE_CURRENT_REGION_DEX
          pbFadeOutIn {
            scene = PokemonPokedex_Scene.new
            screen = PokemonPokedexScreen.new(scene)
            screen.pbStartScreen
            @scene.pbRefresh
          }
        else
          if $Trainer.pokedex.accessible_dexes.length == 1
            $PokemonGlobal.pokedexDex = $Trainer.pokedex.accessible_dexes[0]
            pbFadeOutIn {
              scene = PokemonPokedex_Scene.new
              screen = PokemonPokedexScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          else
            pbFadeOutIn {
              scene = PokemonPokedexMenu_Scene.new
              screen = PokemonPokedexMenuScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          end
        end
      elsif cmdPokemon>=0 && command==cmdPokemon
        pbPlayDecisionSE
        hiddenmove = nil
        pbFadeOutIn {
          sscene = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
          hiddenmove = sscreen.pbPokemonScreen
          (hiddenmove) ? @scene.pbEndScene : @scene.pbRefresh
        }
        if hiddenmove
          $game_temp.in_menu = false
          pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
          return
        end
      elsif cmdBag>=0 && command==cmdBag
        pbPlayDecisionSE
        item = nil
        pbFadeOutIn {
          scene = PokemonBag_Scene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          item = screen.pbStartScreen
          (item) ? @scene.pbEndScene : @scene.pbRefresh
        }
        if item
          $game_temp.in_menu = false
          pbUseKeyItemInField(item)
          return
        end
      elsif cmdPokegear>=0 && command==cmdPokegear
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonPokegear_Scene.new
          screen = PokemonPokegearScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
	elsif cmdEncounter>=0 && command==cmdEncounter
  	pbPlayDecisionSE
 	 pbFadeOutIn {
       scene = EncounterList_Scene.new
   	 screen = EncounterList_Screen.new(scene)
   	 screen.pbStartScreen
  	 @scene.pbRefresh
  }

      elsif cmdTrainer>=0 && command==cmdTrainer
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonTrainerCard_Scene.new
          screen = PokemonTrainerCardScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
      elsif cmdQuit>=0 && command==cmdQuit
        @scene.pbHideMenu
        if pbInSafari?
          if pbConfirmMessage(_INTL("Apakah Anda ingin keluar dari Game Safari sekarang?"))
            @scene.pbEndScene
            pbSafariState.decision = 1
            pbSafariState.pbGoToStart
            return
          else
            pbShowMenu
          end
        else
          if pbConfirmMessage(_INTL("Apakah Anda ingin mengakhiri Kontes sekarang?"))
            @scene.pbEndScene
            pbBugContestState.pbStartJudging
            return
          else
            pbShowMenu
          end
        end
      elsif cmdSave>=0 && command==cmdSave
        @scene.pbHideMenu
        scene = PokemonSave_Scene.new
        screen = PokemonSaveScreen.new(scene)
        if screen.pbSaveScreen
          @scene.pbEndScene
          endscene = false
          break
        else
          pbShowMenu
        end
 elsif cmdSwitch>=0 && command==cmdSwitch
       characters = []
       characterIDs = []
       for i in 0...8
         if $PokemonGlobal.allowedCharacters[i] && i != $Trainer.character_ID
           characters.push(getTrainerFromCharacter(i).name)
           characterIDs.push(i)
         end
       end
       if characters.length <= 0
         pbMessage(_INTL("Anda satu-satunya karakter!"))
         next
       end
       characters.push("Cancel")
       command = pbShowCommands(nil, characters, characters.length)
       if command >= 0 && command < characters.length - 1
         @scene.pbHideMenu
         pbSwitchCharacter(characterIDs[command])
         break
       end

      elsif cmdOption>=0 && command==cmdOption
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen
          pbUpdateSceneMap
          @scene.pbRefresh
        }
      elsif cmdDebug>=0 && command==cmdDebug
        pbPlayDecisionSE
        pbFadeOutIn {
          pbDebugMenu
          @scene.pbRefresh
        }
      elsif cmdEndGame>=0 && command==cmdEndGame
        @scene.pbHideMenu
        if pbConfirmMessage(_INTL("Apakah Anda yakin ingin keluar dari permainan?"))
          scene = PokemonSave_Scene.new
          screen = PokemonSaveScreen.new(scene)
          if screen.pbSaveScreen
            @scene.pbEndScene
          end
          @scene.pbEndScene
          $scene = nil
          return
        else
          pbShowMenu
        end
      else
        pbPlayCloseMenuSE
        break
      end
    end
    @scene.pbEndScene if endscene
  end
end
