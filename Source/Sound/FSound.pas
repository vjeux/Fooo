// By Banban
// Doc : http://www.fmod.org/docs/tutorials/basics.htm
unit FSound;

interface
uses
  fmod, fmodtypes, FUnit;

procedure Sound_init();
//Short sounds loaded into memory
procedure Sound_Init_sample();
procedure Play_Sound_sample(son : PFSoundSample);
procedure Sound_Close_sample();
procedure Adviser_voice(sound : TSoundType);
procedure PlayStatSound(Stats : PUnitAttributes; soundtype : TSoundType);
procedure PlayUnitSound(id : integer; soundtype : TSoundType);
//Bigger sounds like music, streamed
procedure Sound_Init_stream();
procedure Play_Sound_stream(id, vol : integer ; x, y, z : single);
procedure Sound_Close_stream();
procedure Stop_Sound_stream(id : integer);
function LoadSound(path: string) : PFSoundSample;    

procedure Sound_close();

const
  DEFAULT_WAV_VOL     = 100;
  DEFAULT_STREAM_VOL  = 80;
  ID_ADVISOR_TREANT   = 1;
  ID_ADVISOR_RAT      = 11;
  ID_RACE_TREANT      = 0;
  ID_RACE_RAT         = 1;
  ATTACK_WARNING_DELAY = 15;

var
  wav_volume        : integer;
  stream_volume     : integer;
  stream_channel    : integer;
  lastAttackWArning : integer;

implementation

uses
  FInterfaceDraw, sysutils, Classes, FFPS, FData;

type
  PTSound = ^TSound;
  TSound = record
    Path : string;
    Sound : PFSoundSample;
  end;
  
var
  Sound_tab_sample : array[0..63] of PFSoundSample;  //!\\ Global //!\\
  Sound_tab_stream : array[0..63] of PFSoundStream;  //!\\ Global //!\\
	LoadedSounds : TList;
  lastPlayedWav : integer;  //!\\ GLOBAL ZOMG
  NextPlayableSound : Int64 = 0;


function LoadSound(path: string) : PFSoundSample;
var
  index, len : integer;
  t : PTSound;
begin
	if path <> '' then begin
    index := 0;
    len := LoadedSounds.Count;
    while (index < len) and (PTSound(LoadedSounds.Items[index])^.Path <> path) do
      Inc(index);

		if (index = len) then begin
      New(t);
      t^.Path := path;
      t^.Sound := FSOUND_Sample_Load(FSOUND_FREE, PChar(path), FSOUND_LOOP_OFF, 0, 0);
      LoadedSounds.Add(t);
      Result := t^.Sound;
		end else begin
      Result := PTSound(LoadedSounds.Items[index])^.Sound;
    end;
	end else
    Result := nil;
end;
              

function getSoundName(soundtype : TSoundType) : string;
begin
  case soundtype of
    SOUND_BUILDING: Result := 'building';
    SOUND_GOLD:     Result := 'gold';
    SOUND_SEARCH:   Result := 'search';
    SOUND_UNDER:    Result := 'under';
    SOUND_WOOD:     Result := 'wood';
    SOUND_ATTACK:   Result := 'attack';
    SOUND_DEATH:    Result := 'death';
    SOUND_LISTEN:   Result := 'listen';
    SOUND_MANA:     Result := 'mana';
    SOUND_MOVE:     Result := 'move';
    SOUND_OK:       Result := 'ok';
    SOUND_READY:    Result := 'ready';
  end;
end;

procedure Adviser_voice(sound : TSoundType);
begin
  if myRace = ID_RACE_TREANT then
    PlayUnitSound(ID_ADVISOR_TREANT, sound)
  else
    PlayUnitSound(ID_ADVISOR_RAT, sound);
end;

procedure PlayUnitSound(id : integer; soundtype : TSoundType);
var
  i, len : integer;
begin
  i := 0;
  len := Length(Attributes);
  while (i < len) and (Attributes[i].ID <> id) do
    Inc(i);

  if i = len then
    AddLine('Unit id `' + IntToStr(id) + '` does not exist, can''t play sound')
  else
    PlayStatSound(@Attributes[i], soundtype);
end;

procedure PlayStatSound(Stats : PUnitAttributes; soundtype : TSoundType);
var
  i     : integer;
  path : string;
begin
  path := Stats^.SoundFolder + getSoundName(soundtype);
  if Stats^.SoundCount[Integer(soundtype)] = -1 then begin
    i := 1;
    Stats^.SoundCount[Integer(soundtype)] := 0;
    while FileExists(path + IntToStr(i) + '.wav') do begin
      inc(Stats^.SoundCount[Integer(soundtype)]);
      inc(i);
    end;

    if Stats^.SoundCount[Integer(soundtype)] = 0 then begin
      AddLine('Sound `' + path + '` not found for `' + Stats^.Name + '`');
      exit;
    end;
  end else if Stats^.SoundCount[Integer(soundtype)] = 0 then
    exit;

  if Count.Now >= NextPlayableSound then
  begin
      //évite de répéter le même son
    i := random(Stats^.SoundCount[Integer(soundtype)] - 1) + 1;
    if i = lastPlayedWav then
      i := Stats^.SoundCount[Integer(soundtype)];
    Play_Sound_sample(LoadSound(path + IntToStr(i) + '.wav'));
    lastPlayedWav := i;
 end;
end;

procedure Sound_init();
begin
  FSOUND_Init(44100, 32, 0); 
  LoadedSounds      := TList.Create();
  wav_volume        := DEFAULT_WAV_VOL;
  stream_volume     := DEFAULT_STREAM_VOL;
  stream_channel    := 0;
  lastPlayedWav     := -1;
  lastAttackWArning := -1;
end;

procedure Sound_Init_sample();
var
  son : PFSoundSample;
  i : integer;
begin
  son := FSOUND_Sample_Load(FSOUND_FREE, 'Sounds/jaguar.wav', FSOUND_HW3D OR FSOUND_LOOP_OFF, 0, 0);
  Sound_tab_sample[0] := son; //Jaguar
  for i := 1 to 63 do begin
    Sound_tab_sample[i] := NIL;
  end;
end;

procedure Play_Sound_sample(son : PFSoundSample);
var
  chanel : integer;
begin
  NextPlayableSound := Count.Now + Round(FSOUND_Sample_GetLength(son) * 0.022);//125 div (4 *1411);

  chanel := FSOUND_PLaySound(FSOUND_FREE, son);
  FSOUND_SetVolume(chanel, wav_volume);
end;

procedure Sound_Close_sample();
var
  p : pointer;
  i : integer;
begin
  i := 0;
  p := Sound_tab_sample[i];
  while p <> NIL do begin
    FSOUND_Sample_Free(p);
    inc(i);
    p := Sound_tab_sample[i];
  end;
end;

procedure Sound_Init_stream();
var
  i : integer;
begin
  Sound_tab_stream[0] := FSOUND_Stream_Open('Sounds/stream/03 - 03 Xcyril - Alter Ego - La fin de monbourg.mp3', {FSOUND_HW3D OR }FSOUND_LOOP_NORMAL, 0, 0);
  Sound_tab_stream[1] := FSOUND_Stream_Open('Sounds/stream/01 - The Cyclone.ogg', {FSOUND_HW3D OR }FSOUND_LOOP_NORMAL, 0, 0);
  for i := 1 to 63 do begin
    Sound_tab_sample[i] := NIL;
  end;
end;

procedure Play_Sound_stream(id, vol : integer ; x, y, z : single);
var
  son : PFSoundSample;
  chanel : integer;
  Vect : PFSoundVector;
begin
  new(vect);
  vect^.x := x;
  vect^.y := y;
  vect^.z := z;

  son := Sound_tab_stream[id];
  chanel := FSOUND_Stream_Play(FSOUND_FREE, son);
  stream_channel := chanel;
  FSOUND_3D_SetAttributes(chanel, vect, NIL);
  FSOUND_SetVolume(chanel, vol * stream_volume div 100);
  dispose(vect);
end;

procedure Stop_Sound_stream(id : integer);
begin
  FSOUND_SetVolume(id, 0);
end;

procedure Sound_Close_stream();
var
  p : pointer;
  i : integer;
begin
  i := 0;
  p := Sound_tab_stream[i];
  while p <> NIL do begin
    FSOUND_Stream_Close(p);
    inc(i);
    p := Sound_tab_stream[i];
  end;
end;

procedure Sound_close();
begin
  FSOUND_Close;
end;

end.
