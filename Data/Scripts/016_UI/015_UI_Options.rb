#===============================================================================
#
#===============================================================================
class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :frame
  attr_accessor :textskin
  attr_accessor :skipText
  attr_accessor :streamer
  attr_accessor :flashlight
  attr_accessor :screensize
  attr_accessor :language
  attr_accessor :runstyle
  attr_accessor :bgmvolume
  attr_accessor :sevolume
  attr_accessor :textinput
  attr_accessor :battletypes
  attr_accessor :modes

  def initialize
    @textspeed   = 2     # Text speed (0=slow, 1=normal, 2=fast)
    @battlescene = 0     # Battle effects (animations) (0=on, 1=off)
    @battlestyle = 0     # Battle style (0=switch, 1=set)
    @frame       = 0     # Default window frame (see also Settings::MENU_WINDOWSKINS)
    @textskin    = 0     # Speech frame
    @skipText    = 0
    @streamer    = 1
    @flashlight  = 0
    @skipText    = 0
    @screensize  = (Settings::SCREEN_SCALE * 2).floor - 1   # 0=half size, 1=full size, 2=full-and-a-half size, 3=double size
    @language    = 0     # Language (see also Settings::LANGUAGES in script PokemonSystem)
    @runstyle    = 0     # Default movement speed (0=walk, 1=run)
    @bgmvolume   = 100   # Volume of background music and ME
    @sevolume    = 100   # Volume of sound effects
    @textinput   = 1     # Text input mode (0=cursor, 1=keyboard)
    @battletypes = 0     # Types in battles
  end
end

#===============================================================================
#
#===============================================================================
module PropertyMixin
  def get
    (@getProc) ? @getProc.call : nil
  end

  def set(value)
    @setProc.call(value) if @setProc
  end
end

#===============================================================================
#
#===============================================================================
class EnumOption
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc,somethingElse = "SEXO")
    @name    = name
    @values  = options
    @getProc = getProc
    @setProc = setProc
    @somethingElse = somethingElse
  end

  def next(current)
    index = current+1
    index = @values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index = current-1
    index = 0 if index<0
    return index
  end
end

#===============================================================================
#
#===============================================================================
class EnumOption2
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)
    @name    = name
    @values  = options
    @getProc = getProc
    @setProc = setProc
  end

  def next(current)
    index = current+1
    index = @values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index = current-1
    index = 0 if index<0
    return index
  end
end

#===============================================================================
#
#===============================================================================
class NumberOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart
  attr_reader :optend

  def initialize(name,optstart,optend,getProc,setProc)
    @name     = name
    @optstart = optstart
    @optend   = optend
    @getProc  = getProc
    @setProc  = setProc
  end

  def next(current)
    index = current+@optstart
    index += 1
    index = @optstart if index>@optend
    return index-@optstart
  end

  def prev(current)
    index = current+@optstart
    index -= 1
    index = @optend if index<@optstart
    return index-@optstart
  end
end

#===============================================================================
#
#===============================================================================
class SliderOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart
  attr_reader :optend

  def initialize(name,optstart,optend,optinterval,getProc,setProc)
    @name        = name
    @optstart    = optstart
    @optend      = optend
    @optinterval = optinterval
    @getProc     = getProc
    @setProc     = setProc
  end

  def next(current)
    index = current+@optstart
    index += @optinterval
    index = @optend if index>@optend
    return index-@optstart
  end

  def prev(current)
    index = current+@optstart
    index -= @optinterval
    index = @optstart if index<@optstart
    return index-@optstart
  end
end

#===============================================================================
# Main options list
#===============================================================================
class Window_PokemonOption < Window_DrawableCommand
  attr_reader :mustUpdateOptions

  def initialize(options,x,y,width,height)
    @options = options
    @nameBaseColor   = Color.new(31*8,22*8,10*8)
    @nameShadowColor = Color.new(24*8,15*8,0)
    @selBaseColor    = Color.new(31*8,17*8,16*8)
    @selShadowColor  = Color.new(31*8,6*8,3*8)
    @optvalues = []
    @mustUpdateOptions = false
    for i in 0...@options.length
      @optvalues[i] = 0
    end
    super(x,y,width,height)
  end

  def [](i)
    return @optvalues[i]
  end

  def []=(i,value)
    @optvalues[i] = value
    refresh
  end

  def setValueNoRefresh(i,value)
    @optvalues[i] = value
  end

  def itemCount
    return @options.length+1
  end

  def drawItem(index,_count,rect)
    rect = drawCursor(index,rect)
    optionname = (index==@options.length) ? _INTL("Batal") : @options[index].name
    optionwidth = rect.width*9/20
    pbDrawShadowText(self.contents,rect.x,rect.y,optionwidth,rect.height,optionname,
       @nameBaseColor,@nameShadowColor)
    return if index==@options.length
    if @options[index].is_a?(EnumOption)
      if @options[index].values.length>1
        totalwidth = 0
        for value in @options[index].values
          totalwidth += self.contents.text_size(value).width
        end
        spacing = (optionwidth-totalwidth)/(@options[index].values.length-1)
        spacing = 0 if spacing<0
        xpos = optionwidth+rect.x
        ivalue = 0
        for value in @options[index].values
          pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
             (ivalue==self[index]) ? @selBaseColor : self.baseColor,
             (ivalue==self[index]) ? @selShadowColor : self.shadowColor
          )
          xpos += self.contents.text_size(value).width
          xpos += spacing
          ivalue += 1
        end
      else
        pbDrawShadowText(self.contents,rect.x+optionwidth,rect.y,optionwidth,rect.height,
           optionname,self.baseColor,self.shadowColor)
      end
    elsif @options[index].is_a?(NumberOption)
      value = _INTL("Ketik {1}/{2}",@options[index].optstart+self[index],
         @options[index].optend-@options[index].optstart+1)
      xpos = optionwidth+rect.x
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
    elsif @options[index].is_a?(SliderOption)
      value = sprintf(" %d",@options[index].optend)
      sliderlength = optionwidth-self.contents.text_size(value).width
      xpos = optionwidth+rect.x
      self.contents.fill_rect(xpos,rect.y-2+rect.height/2,
         optionwidth-self.contents.text_size(value).width,4,self.baseColor)
      self.contents.fill_rect(
         xpos+(sliderlength-8)*(@options[index].optstart+self[index])/@options[index].optend,
         rect.y-8+rect.height/2,
         8,16,@selBaseColor)
      value = sprintf("%d",@options[index].optstart+self[index])
      xpos += optionwidth-self.contents.text_size(value).width
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
    else
      value = @options[index].values[self[index]]
      xpos = optionwidth+rect.x
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
    end
  end

  def update
    oldindex = self.index
    @mustUpdateOptions = false
    super
    dorefresh = (self.index!=oldindex)
    if self.active && self.index<@options.length
      if Input.repeat?(Input::LEFT)
        self[self.index] = @options[self.index].prev(self[self.index])
        dorefresh = true
        @mustUpdateOptions = true
      elsif Input.repeat?(Input::RIGHT)
        self[self.index] = @options[self.index].next(self[self.index])
        dorefresh = true
        @mustUpdateOptions = true
      end
    end
    refresh if dorefresh
  end
end

#===============================================================================
# Options main screen
#===============================================================================
class PokemonOption_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(inloadscreen=false)
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
       _INTL("Opsi"),0,0,Graphics.width,64,@viewport)
    @sprites["textbox"] = pbCreateMessageWindow
    @sprites["textbox"].text           = _INTL("Bingkai pidato {1}.",1+$PokemonSystem.textskin)
    @sprites["textbox"].letterbyletter = false
    pbSetSystemFont(@sprites["textbox"].contents)
    # These are the different options in the game. To add an option, define a
    # setter and a getter for that option. To delete an option, comment it out
    # or delete it. The game's options may be placed in any order.
    @PokemonOptions = [
       SliderOption.new(_INTL("Volume Musik"),0,100,5,
         proc { $PokemonSystem.bgmvolume },
         proc { |value|
           if $PokemonSystem.bgmvolume!=value
             $PokemonSystem.bgmvolume = value
             if $game_system.playing_bgm!=nil && !inloadscreen
               playingBGM = $game_system.getPlayingBGM
               $game_system.bgm_pause
               $game_system.bgm_resume(playingBGM)
             end
           end
         }
       ),
       SliderOption.new(_INTL("Jilid SE"),0,100,5,
         proc { $PokemonSystem.sevolume },
         proc { |value|
           if $PokemonSystem.sevolume!=value
             $PokemonSystem.sevolume = value
             if $game_system.playing_bgs!=nil
               $game_system.playing_bgs.volume = value
               playingBGS = $game_system.getPlayingBGS
               $game_system.bgs_pause
               $game_system.bgs_resume(playingBGS)
             end
             pbPlayCursorSE
           end
         }
       ),
       EnumOption.new(_INTL("Kecepatan Teks"),[_INTL("Lambat"),_INTL("Normal"),_INTL("Cepat")],
         proc { $PokemonSystem.textspeed },
         proc { |value|
           $PokemonSystem.textspeed = value
           MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed(value))
         }
       ),

       EnumOption.new(_INTL("Modus pita"),[_INTL("Tidak"),_INTL("Ya")],
        proc { $PokemonSystem.streamer},
        proc { |value| $PokemonSystem.streamer = value}
       ),

       EnumOption.new(_INTL("Lampu berkedip"),[_INTL("Pada"),_INTL("Mati")],
       proc { $PokemonSystem.flashlight},
       proc { |value| $PokemonSystem.flashlight = value}
      ),

       EnumOption.new(_INTL("Efek Pertempuran"),[_INTL("Pada"),_INTL("Mati")],
         proc { $PokemonSystem.battlescene },
         proc { |value| $PokemonSystem.battlescene = value }
       ),

       EnumOption.new(_INTL("Gaya Pertempuran"),[_INTL("Ganti"),_INTL("Mengatur")],
         proc { $PokemonSystem.battlestyle },
         proc { |value| $PokemonSystem.battlestyle = value }
       ),

       EnumOption.new(_INTL("Lewati Teks"),[_INTL("Tidak"),_INTL("Ya")],
          proc { $PokemonSystem.skipText },
          proc { |value| $PokemonSystem.skipText = value },
        ),

          mode_option = EnumOption.new(_INTL("Ubah Modus"),[_INTL("Mudah"),_INTL("Normal"),_INTL("Keras"),_INTL("Radikal"),],
          proc { $PokemonSystem.modes },
          proc { |value|
           $PokemonSystem.modes = value

          # Game init?
          if $game_switches
            base = 2093
            (0..3).each do |i|
              $game_switches[base + i] = (value == i)
            end

            getPointMultiplier
          end
          },
        ),

        EnumOption.new(_INTL("Jenis Pertempuran"),[_INTL("Pada"),_INTL("Mati")],
          proc { $PokemonSystem.battletypes },
          proc { |value| $PokemonSystem.battletypes = value },
        ),

       EnumOption.new(_INTL("Gerakan Bawaan"),[_INTL("Sedang berjalan"),_INTL("Berlari")],
         proc { $PokemonSystem.runstyle },
         proc { |value| $PokemonSystem.runstyle = value }
       ),
       NumberOption.new(_INTL("Bingkai Pidato"),1,Settings::SPEECH_WINDOWSKINS.length,
         proc { $PokemonSystem.textskin },
         proc { |value|
           $PokemonSystem.textskin = value
           MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/" + Settings::SPEECH_WINDOWSKINS[value])
         }
       ),
       NumberOption.new(_INTL("Bingkai Menu"),1,Settings::MENU_WINDOWSKINS.length,
         proc { $PokemonSystem.frame },
         proc { |value|
           $PokemonSystem.frame = value
           MessageConfig.pbSetSystemFrame("Graphics/Windowskins/" + Settings::MENU_WINDOWSKINS[value])
         }
       ),
       EnumOption.new(_INTL("Entri Teks"),[_INTL("Kursor"),_INTL("papan ketik")],
         proc { $PokemonSystem.textinput },
         proc { |value| $PokemonSystem.textinput = value }
       ),
       EnumOption.new(_INTL("Ukuran Layar"),[_INTL("S"),_INTL("M"),_INTL("L"),_INTL("XL"),_INTL("Penuh")],
         proc { [$PokemonSystem.screensize, 4].min },
         proc { |value|
           if $PokemonSystem.screensize != value
             $PokemonSystem.screensize = value
             pbSetResizeFactor($PokemonSystem.screensize)
           end
         }
       ),
       EnumOption.new(_INTL("Tidak Ada Utilitas Otomatis"),[_INTL("Mati"),_INTL("Pada")],
       proc { $PokemonSystem.noAutoTiles },
       proc { |value|
           $PokemonSystem.noAutoTiles = value
       }
   )
    ]

    @PokemonOptions.delete(mode_option) unless $game_switches

    @PokemonOptions = pbAddOnOptions(@PokemonOptions)
    @sprites["option"] = Window_PokemonOption.new(@PokemonOptions,0,
       @sprites["title"].height,Graphics.width,
       Graphics.height-@sprites["title"].height-@sprites["textbox"].height)
    @sprites["option"].viewport = @viewport
    @sprites["option"].visible  = true
    # Get the values of each option
    for i in 0...@PokemonOptions.length
      @sprites["option"].setValueNoRefresh(i,(@PokemonOptions[i].get || 0))
    end
    @sprites["option"].refresh
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbAddOnOptions(options)
    return options
  end

  def pbOptions
    oldSystemSkin = $PokemonSystem.frame      # Menu
    oldTextSkin   = $PokemonSystem.textskin   # Speech
    pbActivateWindow(@sprites,"option") {
      loop do
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["option"].mustUpdateOptions
          # Set the values of each option
          for i in 0...@PokemonOptions.length
            @PokemonOptions[i].set(@sprites["option"][i])
          end
          if $PokemonSystem.textskin!=oldTextSkin
            @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
            @sprites["textbox"].text = _INTL("Bingkai pidato {1}.",1+$PokemonSystem.textskin)
            oldTextSkin = $PokemonSystem.textskin
          end
          if $PokemonSystem.frame!=oldSystemSkin
            @sprites["title"].setSkin(MessageConfig.pbGetSystemFrame())
            @sprites["option"].setSkin(MessageConfig.pbGetSystemFrame())
            oldSystemSkin = $PokemonSystem.frame
          end
        end
        if Input.trigger?(Input::BACK)
          break
        elsif Input.trigger?(Input::USE)
          break if @sprites["option"].index==@PokemonOptions.length
        end
      end
    }
  end

  def pbEndScene
    pbPlayCloseMenuSE
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Set the values of each option
    for i in 0...@PokemonOptions.length
      @PokemonOptions[i].set(@sprites["option"][i])
    end
    pbDisposeMessageWindow(@sprites["textbox"])
    pbDisposeSpriteHash(@sprites)
    pbUpdateSceneMap
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonOptionScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(inloadscreen=false)
    @scene.pbStartScene(inloadscreen)
    @scene.pbOptions
    @scene.pbEndScene
  end
end
