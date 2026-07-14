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

unit un.Parameters;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure saveGameParameter;
procedure loadGameParameter;
procedure init_Game_Var;

// ******************** implementation ********************

implementation

USES SDL3, sysutils, JsonTools,
     un.Structs,
     un.Defs;

procedure saveGameParameter;
var C : TJsonNode;
begin
  C := TJsonNode.Create;
  C.Force('Parameter').Add('sound', game.SoundVol);
  C.Force('Parameter').Add('music', game.MusicVol);
  C.Force('Parameter').Add('fancy_Terrain', game.opt_fancy_Terrain);
  C.Force('Parameter').Add('progressive_gravity', game.opt_prog_grav);
  C.Force('Parameter').Add('landing_pad_bonus', game.opt_lp_bonus);
  C.Force('Parameter').Add('landing_pad_warn', game.opt_lp_warn );
  C.SaveToFile(Parameter_Path);
  C.Free;
end;

procedure loadGameParameter;
var N, C : TJsonNode;
begin
  if FileExists(Parameter_Path) then
  begin
    //Get the JSON data
    N := TJsonNode.Create;
    N.LoadFromFile(Parameter_Path);

    C := N.Find('Parameter');
    game.SoundVol          := C.Find('sound').asInteger;
    game.MusicVol          := C.Find('music').asInteger;
    game.opt_fancy_Terrain := C.Find('fancy_Terrain').asBoolean;
    game.opt_prog_grav     := C.Find('progressive_gravity').asBoolean;
    game.opt_lp_bonus      := C.Find('landing_pad_bonus').asBoolean;
    game.opt_lp_warn       := C.Find('landing_pad_warn').asBoolean;
    N.Free;
  end
  else
  begin
    game.SoundVol          := 50;
    game.MusicVol          := 50;
    game.opt_fancy_Terrain := True;
    game.opt_prog_grav     := False;
    game.opt_lp_bonus      := True;
    game.opt_lp_warn       := True;
    saveGameParameter;
  end;
end;

procedure init_Game_Var;                         { initialize game parameters }
begin
  game.curr_lev.difficulty := 0;
  game.ships_remaining := 3;
  game.maxScoreShip := Max_Score;
  game.difficulty := 1;
  game.pause := False;
  game.score := 0;
  game.fullscreen := 0;
  gravity_Pr := 50;
  engine_on := 0;
  tick := 0;
  loadGameParameter;
end;

end.
