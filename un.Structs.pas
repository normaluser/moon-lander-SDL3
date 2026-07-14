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

unit un.Structs;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES SDL3,
     SDL3_Mixer,
     un.Defs;

TYPE PAtlasImage = ^TAtlasImage;
     TAtlasImage = RECORD
                     FNam : String;
                     Rec  : TSDL_FRect;
                     Rot  : Integer;
                     Tex  : PSDL_Texture;
                     next : PAtlasImage;
                   end;
     PSprite     = ^TSprite;
     TSprite     = RECORD                      { Sprite }
                     Textur : PAtlasImage;
                     x, y   : Single;
                     Rect   : TSDL_FRect;
                   end;
     PTextur     = ^TTexture;
     TTexture    = RECORD
                     namen1 : ARRAY[0..MAX_LINE_LENGTH] of Char;
                     Texture : PSDL_Texture;
                     x, y   : Single;
                     Rect   : TSDL_FRect;
                     next : PTextur;
                   end;
     TAI         = RECORD
                     difference, vdiff, max_y, target : Single;
                     pad, distance, direction, state : Integer;
                   end;
     TLevel      = RECORD
                     landing_x, landing_y, landing_w, landing_score : ARRAY[0..ANZ] of LongInt;
                     landing_speed : ARRAY[0..ANZ] of Single;
                     landing_color : ARRAY[0..ANZ] of TSDL_Color;
                     difficulty, fuel, num_landings  : Integer;
                   end;
     TGame_def   = RECORD
                     ai                                                                   : TAI;
                     curr_lev                                                             : TLevel;
                     gravity, x_vel, y_vel                                                : Single;
                     thruster_m, thruster_l, thruster_r,
                     crosshairs, miniship, miniship1, miniship2,
                     magigames, logo, lander1, lander2                                    : TSprite;
                     maxscoreShip, ships_remaining, score, levelscore, difficulty, nr,
                     landing_pad, Timeout, fuel, SoundVol, MusicVol, beacon_x, beacon_y   : Integer;
                     fullscreen                                                           : UInt32;
                     opt_fancy_Terrain, opt_lp_warn, opt_lp_bonus, opt_prog_grav,
                     B_thrust_m, B_thrust_l, B_thrust_r, startGame, endGame, newGame,
                     title, newRound, menue, won, loose, destroy, landed, exitloop,
                     pause, director, manual, autopilot, demoMode                         : Boolean;
                     TBack, Background, Boden, BodenGrey                                  : TTexture;
                   end;
     TMix        = RECORD
                     mixer: PMIX_Mixer;
                     track: PMIX_Track;
                     audio: PMIX_Audio;
                   end;
     PMix        = ^TMix;
     TDelegating = PROCEDURE;
     TDelegate   = RECORD
                     logic, draw : TDelegating;
                   end;
     TApp        = RECORD
                     Window    : PSDL_Window;
                     Renderer  : PSDL_Renderer;
                     keyboard  : ARRAY[0..MAX_KEYBOARD_KEYS] OF Integer;
                     delegate  : TDelegate;
                   end;
     AtlasArr    = ARRAY[0..NUMATLASBUCKETS] of PAtlasImage;

VAR app          : TApp;
    SDL_Event    : TSDL_Event;
    RGB          : TSDL_Color;
    game         : TGame_def;
    gTicks       : UInt32;
    menu_Grav    : Single;
    gravity_Pr   : Byte;
    gRemainder   : Double;
    speedTex     : PSDL_Texture;
    Eagle,
    Rocket,
    BodenRect    : TSprite;
    backPic      : TTexture;
    Explo        : ARRAY[1..Max_Exp] of TSprite;
    backPicNam   : ARRAY[1..Max_Back] of String;
    BodenArr     : ARRAY[0..xSize] of Integer;
    EagleArr     : ARRAY of ARRAY of Byte;
    option       : TSDL_PropertiesID;
    S_Mix        : ARRAY[0..max_Sound] of PMix;
    audiofname   : ARRAY[0..max_Sound] of PChar;
    engine_on,
    engine_on_past,
    Anz_Back     : Byte;
    atlasTex     : PSDL_Texture;
    atlases      : AtlasArr;
 //   sounds       : ARRAY[1..SND_MAX] OF PMix_Chunk;
 //   music        : PMix_Music;
    anz,
    _left,
    _right,
    _down,
    tick         : Integer;
    CH_ANY       : PCHAR;

// ******************** implementation ********************

implementation

end.
