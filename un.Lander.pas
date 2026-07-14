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

unit un.Lander;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure doLander;
procedure draw_Lander;

// ******************** implementation ********************

implementation

USES SDL3, SDL3_mixer,
     un.Defs,
     un.Structs,
     un.Draw,
     un.GameAI,
     un.Utils,
     un.Sound;

procedure draw_Lander;
begin
  Eagle.Rect.x := TRUNC(Eagle.x);
  Eagle.Rect.y := TRUNC(Eagle.y) - Eagle.Rect.h;
  if (game.destroy = False) then
  begin
    blitAtlasImage(eagle.Textur, Eagle.Rect.x, Eagle.Rect.y, 0);
    if game.B_thrust_m then
    begin
      game.thruster_m.Rect.x := TRUNC(Eagle.x) + (Eagle.Rect.w / 2) - 4;
      game.thruster_m.Rect.y := TRUNC(Eagle.y) +  Eagle.Rect.h - 3;
      blitAtlasImage(game.thruster_m.Textur, game.Thruster_m.Rect.x, game.Thruster_m.Rect.y - Eagle.Rect.h, 0);
    end;
    if game.B_thrust_l then
    begin
      game.thruster_l.Rect.x := TRUNC(Eagle.x) + (Eagle.Rect.w / 2) + 24;
      game.thruster_l.Rect.y := TRUNC(Eagle.y) +  Eagle.Rect.h - 17;
      blitAtlasImage(game.thruster_l.Textur, game.Thruster_l.Rect.x, game.Thruster_l.Rect.y - Eagle.Rect.h, 0);
    end;
    if game.B_thrust_r then
    begin
      game.thruster_r.Rect.x := TRUNC(Eagle.x) + (Eagle.Rect.w / 2) - 34;
      game.thruster_r.Rect.y := TRUNC(Eagle.y) +  Eagle.Rect.h - 17;
      blitAtlasImage(game.thruster_r.Textur, game.Thruster_r.Rect.x, game.Thruster_r.Rect.y - Eagle.Rect.h, 0);
    end;
  end;
end;

function collision_detect_perfect(obj1, obj2 : TSprite) : Boolean;
VAR i, j,
    left1,   right1,                { obj1 == Eagle }
    top1,    top2,                  { obj2 == ground }
    bottom1, bottom2 : Integer;

begin
  left1   := TRUNC(obj1.x);         { Eagle and ground have the same width }
  //right1  := TRUNC(obj1.x) + obj1.Rect.w;
  top1    := TRUNC(obj1.y) - TRUNC(obj1.Rect.h);
  top2    := TRUNC(obj2.y);
  bottom1 := TRUNC(obj1.y);
  //bottom2 := obj2.Rect.h;

  { Trivial rejections: }
  if (bottom1 < top2) then begin collision_detect_perfect := False; exit; end;
  //if (top1 > bottom2) then begin collision_detect_perfect := False; exit; end;   not necessary, because of Eagle-Array and Boden-Array
  //if (right1 < left1) then begin collision_detect_perfect := False; exit; end;
  //if (left1 > right1) then begin collision_detect_perfect := False; exit; end;

  collision_detect_perfect := False;

  for j := pred(TRUNC(obj1.Rect.h)) downto 0 do
    for i := 0 to pred(TRUNC(obj1.Rect.w)) do
    begin
      if ((EagleArr[i,j] = 1) AND (BodenArr[left1 + i] = (top1 + j))) then
      begin
        collision_detect_perfect := True;
        exit;
      end;
    end;
end;

function suche_LandingPlattform_Nr : Byte;
CONST wx = 3;
VAR i : Byte;
begin
  suche_LandingPlattform_Nr := 0;

  for i := 0 to game.curr_lev.num_landings do
  begin                                { Query with wx pixel tolerance right and left }
    if (TRUNC(Eagle.x) >= game.curr_lev.landing_x[i] - wx) AND ((TRUNC(Eagle.x) + Eagle.Rect.w)
      <= (game.curr_lev.landing_x[i] + game.curr_lev.landing_w[i] + wx)) then
        suche_LandingPlattform_Nr := i;
  end;
end;

procedure boden_Rect;
VAR i, j, Min, Max : Integer;
begin
  j := TRUNC(Eagle.x);        { x-Pos of the Eagle == x-Pos of the groundArray }
  Min := BodenArr[j];         { Initialize min and max; use ground height as the starting value. }
  Max := BodenArr[j];
  for i := 0 to pred(TRUNC(Eagle.Rect.w)) do  { Loop to Eagle_width == width groundArray }
  begin
    if BodenArr[i + j] > Max then Max := BodenArr[i + j];
    if BodenArr[i + j] < Min then Min := BodenArr[i + j];
  end;
  BodenRect.x := Eagle.x;           { x/y top-left corner }
  BodenRect.y := Min;               { x/y top-left corner }
  BodenRect.Rect.w := Eagle.Rect.w; { x/y bottom right corner }
  BodenRect.Rect.h := Max;          { x/y bottom right corner }
end;

procedure doLander;
CONST row = 6;  { Row = Safety column of 6 pixels at the screen edge due to ground and EagleARRAY; outer edge not defined }
VAR   PLat_Nr : Byte;
begin
  game.manual := False;
  if (Eagle.x <= row) then game.destroy := True;                           { Do not leave the screen! }
  if (Eagle.x >= xSize - Eagle.Rect.w - row) then game.destroy := True;    { Because of the groundArr; not defined outside! }
  if (Eagle.y <= -50) then Eagle.y := -50;                                 { Eagle can go a little higher up :) }

  if game.director then doFlightDirector;

  if (game.landed = False) AND (game.destroy = False) then
  begin
    game.B_thrust_m := False; game.B_thrust_l := False; game.B_thrust_r := False;

    game.y_vel := game.y_vel + game.gravity;

    if game.fuel > 0 then
    begin
    { keyboard query }
      if ((app.keyboard[SDL_ScanCode_UP] OR app.keyboard[SDL_ScanCode_KP_8]) = 1) OR (_down = 1) then
        begin game.y_vel := game.y_vel - way_y; DEC(game.fuel, 2); game.B_thrust_m := True; engine_on := 1; _down := 1; end;

      if ((app.keyboard[SDL_ScanCode_DOWN]  OR app.keyboard[SDL_ScanCode_KP_2]) = 1) then   { lander accelerates down to the lunar surface ! }
        begin game.y_vel := game.y_vel + way_y; DEC(game.fuel); end;

      if ((app.keyboard[SDL_ScanCode_LEFT]  OR app.keyboard[SDL_ScanCode_KP_4]) = 1) then
        begin game.manual := True; game.x_vel := game.x_vel - way_x; DEC(game.fuel); game.B_thrust_l := True; engine_on := 1; _left := 1; end;

      if ((app.keyboard[SDL_ScanCode_RIGHT] OR app.keyboard[SDL_ScanCode_KP_6]) = 1) then
        begin game.manual := True; game.x_vel := game.x_vel + way_x; DEC(game.fuel); game.B_thrust_r := True; engine_on := 1; _right := 1; end;

      { game-AI query }
      if (_left = 1) AND (NOT game.manual) then
        begin game.x_vel := game.x_vel - way_x; DEC(game.fuel); game.B_thrust_l := True; engine_on := 1; _left := 1; end;

      if (_right = 1) AND (NOT game.manual) then
        begin game.x_vel := game.x_vel + way_x; DEC(game.fuel); game.B_thrust_r := True; engine_on := 1; _right := 1; end;

      { Sound }
      if (engine_on = 1) AND (NOT Mix_TrackPlaying(S_Mix[2]^.track)) then
        playSound(SND_JETS);

      if (engine_on = 0) AND (engine_on_past = 1) then
        stopSound(SND_JETS);

      engine_on_past := engine_on;
      if (game.opt_prog_grav) then game.gravity := game.gravity + (game.difficulty * difficu);

      if game.fuel <= 0 then game.fuel := 0;                          { after keys are pressed and fuel <= 0 ... }
    end;

    Eagle.x := Eagle.x + game.x_vel;                                  { move sprite }
    Eagle.y := Eagle.y + game.y_vel;

    Boden_Rect;
    if collision_detect_perfect(Eagle, BodenRect) then                { if collision then }
    begin
      Plat_Nr := suche_LandingPlattform_Nr;
      if Plat_Nr <> 0 then                                            { Eagle-Rect within platform }
      begin
        game.B_thrust_m := False; game.B_thrust_l := False; game.B_thrust_r := False; { Thruster turn off! }

        if (game.y_vel <= game.curr_lev.landing_speed[Plat_Nr]) AND (ABS(game.x_vel) <= x_velmax) then  { landed safely !! }
        begin
          game.destroy := False; game.landed := True; game.won := True;  { landed safely !! }
          stopSound(SND_JETS);
          if game.score >= game.MaxScoreShip then
          begin                                                       { new Eagle !! }
            INC(game.ships_remaining);
            INC(game.maxScoreShip, Max_Score);
            playSound(SND_NEW_EAGLE);
          end;
          PlaySound(SND_EAGLE_LANDED);
          if (NOT game.autopilot) then                                { get your score, but NOT if autopilot is active }
          begin
            INC(game.difficulty);
            game.levelscore := game.curr_lev.landing_score[Plat_Nr] + game.Fuel;
            game.score := game.score + game.levelscore;
          end;
          Eagle.y := game.curr_lev.landing_y[Plat_Nr];                { line up Sprite with platform }
        end
        else                                                          { collision with platform !! }
        begin
          game.destroy := True; game.landed := False; game.won := False; DEC(game.ships_remaining);
          {stopALLSound;} stopSound(SND_JETS); playSound(SND_EXPLOSION);
        end;
      end
      else                                                            { Eagle destroyed on terrain }
      begin
        game.destroy := True; game.landed := False; game.won := False; DEC(game.ships_remaining);
        {StopALLSound;} stopSound(SND_JETS); playSound(SND_EXPLOSION);
        game.B_thrust_m := False; game.B_thrust_l := False; game.B_thrust_r := False;
      end;
    end;
  end;
end;

end.
