{*****************************************************************************
  Copyright (C) 2026 NormalUser

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*****************************************************************************}

unit un.Sound;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure playSound(id : Byte);
procedure stopSound(id : Byte);
procedure stopALLSound;
procedure init_Sounds;

// ******************** implementation ********************

implementation

USES SDL3,
     SDL3_Mixer,
     un.Defs,
     un.Utils,
     un.Structs;

procedure loadSounds;
VAR i : Byte;
begin
  audiofname[AUDIO_MUSIC]      := 'music/epic-cinematic-background-248926.ogg';
  audiofname[SND_EXPLOSION]    := 'sounds/explosion2.wav';
  audiofname[SND_JETS]         := 'sounds/jet_lp.wav';
  audiofname[SND_ON]           := 'sounds/Blaster_1.wav';
  audiofname[SND_OFF]          := 'sounds/Retro_3.wav';
  audiofname[SND_READY]        := 'sounds/beep1b.wav';
  audiofname[SND_GO]           := 'sounds/honk.wav';
  audiofname[SND_NEW_EAGLE]    := 'sounds/freesound_community-piglevelwin2mp3-14800.mp3';
  audiofname[SND_EAGLE_LANDED] := 'sounds/eagle_has_landed.wav';

  if not MIX_Init then
  begin
    SDL_Log('Couldn''t initialize SDL_mixer: %s', SDL_GetError);
    Exit;
  end;

  S_Mix[MIXER_]^.mixer := MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nil);      { Mixer }
  if S_Mix[MIXER_]^.mixer = nil then
  begin
    SDL_Log('Couldn''t create mixer: %s', SDL_GetError);
    Halt(SDL_APP_FAILURE);
  end;

  for i := 0 to max_Sound do
  begin
    S_Mix[i]^.audio := MIX_LoadAudio(S_Mix[MIXER_]^.mixer, audiofname[i], True);
    if S_Mix[i]^.audio = nil then
    begin
      SDL_Log('Couldn''t load audio from %s: %s', audiofname[i], SDL_GetError);
      Halt(SDL_APP_FAILURE);
    end;

    S_Mix[i]^.track := MIX_CreateTrack(S_Mix[MIXER_]^.mixer);
    if S_Mix[i]^.track = nil then
    begin
      SDL_Log('Couldn''t create track: %s', SDL_GetError);
      Halt(SDL_APP_FAILURE);
    end;

    Mix_SetTrackGain(S_Mix[i]^.track, 0.95);                         { Sound volume }

    MIX_SetTrackAudio(S_Mix[i]^.track, S_Mix[i]^.audio);
  end;

  option := SDL_CreateProperties();
  SDL_SetNumberProperty(option, MIX_PROP_PLAY_LOOPS_NUMBER, -1);     { Play music in a loop }

  MIX_PlayTrack(S_Mix[AUDIO_MUSIC]^.track, option);
  Mix_SetTrackGain(S_Mix[AUDIO_MUSIC]^.track, 1.0);                  { Music volume }
end;

procedure playSound(id : Byte);
begin
  if NOT MIX_TrackPlaying(S_Mix[id]^.track) then  MIX_PlayTrack(S_Mix[id]^.track, 0);
end;

procedure stopSound(id : Byte);
begin
  if MIX_TrackPlaying(S_Mix[id]^.track) then
    MIX_StopTrack(S_Mix[id]^.track, 0);               { Stops sound on the mixer!! }
end;

procedure stopALLSound;
VAR i : Byte;
begin
  for i := 1 to max_Sound do                          { don`t stop Background Music ! It would stop Backgroundmusic also }
    if MIX_TrackPlaying(S_Mix[i]^.track) then         { starts with 1, because 0 == Music; 1..8 are sounds! }
      MIX_StopTrack(S_Mix[i]^.track, 0);
end;

procedure init_Sounds;
begin
  loadSounds;
end;

end.
