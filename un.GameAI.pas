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

unit un.GameAI;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES un.Structs;

procedure draw_Beacon;
procedure doFlightDirector;
procedure draw_flightdirector;
procedure game_ai1(VAR left, right, down : Integer; VAR game1 : TGame_def);
procedure game_ai2(VAR left, right, down : Integer; VAR game1 : TGame_def);

// ******************** implementation ********************

implementation

USES SDL3,
     un.Defs,
     un.Draw,
     un.Randomlevel;

function sign(a : Single) : Integer;
begin
  if 0 < game.x_vel then sign := 1
    else if 0 > game.x_vel then sign := -1 else sign := 0;
end;

procedure draw_Beacon;
var i, j : Byte;
begin
  for j := 0 to 2 do
    for i := 0 to 2 do
      draw_Pixel(app.renderer, RED, game.beacon_x - 1 + i, game.beacon_y - 4 + j);
end;

procedure draw_flightdirector;
VAR hi, vi, scale : Single;
    x, y, xy, cx, cy : Integer;
begin
  blitAtlasImage(game.crosshairs.textur, game.crosshairs.Rect.x, game.crosshairs.Rect.y, 0);
  hi := game.x_vel;
  vi := game.y_vel;
  scale := abs(hi);
  if abs(vi) > abs(hi)
    then scale := abs(vi)
    else scale := abs(hi);
  if 2 > scale then scale := 2;
  cx := TRUNC(game.crosshairs.Rect.x) + 4;
  cy := TRUNC(game.crosshairs.Rect.y) + 4;
  for xy := 1 to 14 do
  begin
    x := TRUNC(xy * (hi / scale) * 2);
    y := TRUNC(xy * (vi / scale) * 2);
    if (cy > ySize) then cy := ySize;     { do not draw outside of the screen }
    if (cx < 0)     then cx := 0;
    if (cx > xSize) then cx := xSize;
    draw_Pixel(app.Renderer, Cross, cx - x, cy - y);
  end;
end;

procedure doFlightDirector;
VAR a, b, xi, yi, hi, vi, sgn : Single;
  cx, cy : Integer;
begin
  a := game.gravity + 0.04;
  b := game.gravity + 0.01;
  xi := Eagle.x + 0.5 * Eagle.Rect.w;
  yi := Eagle.y; // + Eagle.Rect.h;
  hi := game.x_vel;
  vi := game.y_vel;
  if hi > 0 then sgn := 1 else sgn := -1;         { Function "sign" in unit math }
  cx := TRUNC(xi - 4 + sgn * hi * hi / (2 * b));
  cy := TRUNC(yi - 4 + vi * vi / (2 * (a - game.gravity)));
  game.crosshairs.Rect.x := cx;
  game.crosshairs.Rect.y := cy;
end;

procedure game_ai1(VAR left, right, down : Integer; VAR game1 : TGame_def);
VAR x, a, g, yt, vt, yf, yi, y0, i, f,
    t, T1, alt, max_v, xb, w, ub, C : Single;
    count, max_x, max_y : Integer;

{ -------------------------------------------------------------
   Game AI -- written by Michael Heckman 07/17/2001

   Ok, so we're going to divide the AI into several states:

   0 => Figure out the direction
   1 => Burn until we're half way there
   2 => Burn in the opposite direction
   3 => once we've reached the pad, cancel out any remaining
        velocity.
   4 => Freefall with minor course changes

   Game AI -- improved by Dr. Robert Meier 03/17/2002

   The lunar lander powered descent from low-phi orbit was
   a nonlinear problem well beyond autopilots until the 1970s.
   Landing with perfect attitude control on a flat surface is easy.

   The minimum fuel course is called bang-bang control.

   No vertical thrust until continuous vertical thrust will
   zero descent rate at the pad.
   Accelerate horizontally the minimum necessary to reach the pad.
   Coast horizontally until continuous deceleration is required.
   Decelerate continuously to reach zero groundspeed over the pad.

   To avoid burning landing gear off with backblast, you should actually
   shutdown and freefall when altitude and vertical speed are low enough.

     -------------------------------------------------------------  }

  { variant 1, user can interact with lander }

begin
  { find the target pad }
  game.ai.pad := 0;
  game.ai.distance := 9999;
  x := Eagle.x + (Eagle.Rect.w / 2);
  for count := 0 to game.curr_lev.num_landings do
  begin
    if ABS(x - game.curr_lev.landing_x[count]) < game.ai.distance then
    begin
      game.ai.distance := TRUNC(ABS(x - game.curr_lev.landing_x[count]));
      game.ai.pad := count;
    end;
  end;

  { Find the Target hovering point.  (Allow 0.05 margin for error }
  max_x := game.curr_lev.landing_x[game.ai.pad] + (game.curr_lev.landing_w[game.ai.pad] DIV 2);
  max_v := game.curr_lev.landing_speed[game.ai.pad] - 0.05;
  max_y := game.curr_lev.landing_y[game.ai.pad];

  {let the user know which pad is in use }
  game.beacon_x := max_x;
  game.beacon_y := max_y;

  g := game.gravity;    //0.05
  a := 0.10 - g;        //g
  yt := eagle.y;
  vt := game.y_vel;
  yf := max_y;
  yi := yt - (vt * vt) / (2 * g);
  y0 := ((a * yf) + (g * yi)) / (a + g);
  i := sqrt(2 * (y0 - yi) / g);
  f := sqrt(2 * (yf - y0) / a);
  t := i - vt / g;

  if ((down <> 1) AND (0 < vt)) then
  begin
    if (2 > t) then
    begin
      down := 1;
      t := 0;
    end;
  end;

  // Bang-bang control has an eigenfunction and three states.
  //
  // The eigenfunction is the phase space (position vs speed) trajectory
  //   during continuous burn.
  //   w      - acceleration
  //   x(-b)  - position now
  //   u(-b)  - groundspeed now
  //   C      - position of zero groundspeed relative to speed direction
  //   T      - time to coast and decelerate
  // The eigenfunction, the position axis, and the time to target,
  //   divide the space into three pairs of regions.
  //   C = x(-b) sgn(u(-b)) + u(-b) u(-b) / 2 abs(w)
  //   T = abs(x(-b)) / abs(u(-b)) + abs(u(-b)) / 2 abs(w)
  //
  //                  x
  //  . accelerating  :  decelerating
  //  .               :
  //  .           <<<<:
  //  .        <<<    :
  //    . . .<<       :
  //    .     . .     :
  //    .coast    .   :
  //      .         . :
  //      .    v    . :
  //        .  v      :
  //          .v.     :
  //              . . + . .         --- v
  //                  :     . .
  //                  :  coast  .
  //                  : .         .
  //        >         : .         .
  //         >>       :   .         .
  //           >>>    :     . .     .
  //              >>>>:         . . .
  //                  :               .
  //                  :               .
  //  decelerating    :  accelerating .
  //                  :               .
  //
  // State I: decelerating
  //   C > 0           - condition
  //   w               = -abs(w) sgn(u(-b))
  // State I transitions to state II if actual acceleration is greater than w.
  //
  // State II: coasting
  //   C < 0 & t+f > T - condition
  //   w               = 0
  // State II transitions to state I as C increases.
  //
  // State III: accelerating
  //   C < 0 & t+f < T - condition
  //   w               = abs(w) sgn(u(-b))
  // State III transition to state II if actual acceleration is greater than w.

  if game.y_vel < 0 then down := 0;     { no climbing! }

  xb := x - max_x;
  w  := 0.065;
  ub := game.x_vel;

  C := (xb * sign(ub) + ub * ub) / (2 * abs(w));
  T1 := (abs(xb) / (abs(ub) + 0.001)) + (abs(ub) / (2 * abs(w)));

  { Thrust if continuous thrust will be just enough. }
  { (Dont cancel pilot command.)                     }
  { (Dont thrust if close enough)                    }
  { (Shutdown if altitude is low enough)             }

  if NOT game.manual then
  begin
    left  := 0;
    right := 0;
    if ((0.1 < abs(ub)) OR (1 < abs(xb))) then
    begin
      if (0 < C) then                 { State I: decelerating }
      begin
        if (0 < ub) then left  := 1   { confirmed }
                    else right := 1;  { confirmed }
      end
      else
      begin
        if (t + f > T1) then          { State II: coasting }
        begin end
        else                          { State III: accelerating }
        begin
          if (0 < ub) then right := 1
                      else left  := 1;
        end;
      end;
    end
    else
    begin
      alt := game.curr_lev.landing_y[game.ai.pad] - yt;
      if (2 * g * alt + vt * vt) < (max_v * max_v) then
        down := 0;                    { shutdown }
    end;
  end;
   if (left = 0) AND (right = 0) then
    engine_on := 0;
end;

(* =================================================================================== *)

procedure game_ai2(VAR left, right, down : Integer; VAR game1 : TGame_def);
VAR x : Single;
    count, max_xx, max_yy : Integer;

  { variant 2, better for Demo-Mode; user can't interact with lander }

begin
  left  := 0;
  right := 0;

  { AI State }
  { --- state 0, locate the pad and init variables --- }
  if game.y_vel < 0 then down := 0;

  if (game.ai.state = 0) then
  begin
    game.ai.vdiff := 0;

    { Find which pad we're going to take. }
    game.ai.pad := 0;
    game.ai.distance := 9999;

    x := Eagle.x + (Eagle.Rect.w / 2);
    for count := 0 to game.curr_lev.num_landings do
    begin
      if ABS(x - game.curr_lev.landing_x[count]) < game.ai.distance then
      begin
        game.ai.distance := Trunc(ABS(x - game.curr_lev.landing_x[count]));
        game.ai.pad := count;
      end;
    end;
    game.ai.max_y := game.curr_lev.landing_speed[game.ai.pad];

    max_xx := game.curr_lev.landing_x[game.ai.pad] + (game.curr_lev.landing_w[game.ai.pad] DIV 2);
    max_yy := game.curr_lev.landing_y[game.ai.pad];

    {let the user know which pad is in use }
    game.beacon_x := max_xx;
    game.beacon_y := max_yy;

    { Calculate the half the difference between our current position }
    { and the landing pad  }
    game.ai.target := game.curr_lev.landing_x[game.ai.pad] + ((game.curr_lev.landing_w[game.ai.pad] - Eagle.Rect.w) / 2);
    game.ai.difference := abs(Eagle.x - game.ai.target) / 2;

    { Decide if we're going left or right }
    if ( game.ai.target < Eagle.x) then
    begin
      game.ai.difference := Eagle.x - game.ai.difference;
      game.ai.direction := 0;
    end
    else
    begin
      game.ai.difference := Eagle.x + game.ai.difference;
      game.ai.direction := 1;
    end;
  end;

  { Stay under the final velocity  }
  if (game.ai.max_y < game.y_vel) then down := 1;

  { --- state 1 & 2, main flight --- }
  if ((game.ai.direction = 0) AND (game.ai.state < 3)) then
  begin
    if ((game.ai.state = 0) AND  (Eagle.x >  game.ai.difference)) then game.ai.state := 1;
    if ((game.ai.state = 1) AND  (Eagle.x <= game.ai.difference)) then game.ai.state := 2;
    if ((game.ai.state = 2) AND ((Eagle.x <= game.ai.target) OR (game.x_vel > 0))) then game.ai.state := 3;

    if (game.ai.state = 1) then left  := 1;
    if (game.ai.state = 2) then right := 1;
  end;

  { --- state 1 & 2, main flight --- }
  if ((game.ai.direction = 1) AND (game.ai.state < 3)) then
  begin
    if ((game.ai.state = 0) AND  (Eagle.x <  game.ai.difference)) then game.ai.state := 1;
    if ((game.ai.state = 1) AND  (Eagle.x >= game.ai.difference)) then game.ai.state := 2;
    if ((game.ai.state = 2) AND ((Eagle.x >= game.ai.target) OR (Game.x_vel < 0))) then game.ai.state := 3;

    if (game.ai.state = 1) then right := 1;
    if (game.ai.state = 2) then left  := 1;
  end;

  { --- state 3, bring x velocity close to zero --- }
  if (game.ai.state = 3) then
  begin
    if ((game.x_vel > 0.04) OR (game.x_vel < -0.04)) then
    begin
      if (game.x_vel > 0) then left := 1
                          else right := 1;
    end
    else
    begin
      game.ai.state := 4;
      game.ai.vdiff := Eagle.y + ((game.curr_lev.landing_y[game.ai.pad] - Eagle.y) / 2.3);  //2.5; 2.4; 2.2
    end;
  end;

  { --- state 4, close in on the landing pad --- }
  if (game.ai.state = 4) then
  begin
    if ((Eagle.x < game.ai.target - 2) OR (Eagle.x > game.ai.target + 2) OR (game.x_vel <> 0.07)) then
    begin
      if (Eagle.x > game.ai.target + 2) then      { "+ 2" <==> 2 pixel width }
        if (game.x_vel > -0.07) then
          left := 1;
      if (Eagle.x < game.ai.target - 2) then
        if (game.x_vel < 0.07) then
          right := 1;
    end;

    if (Eagle.y < (game.ai.vdiff + game.y_vel)) then
      down := 0;
  end;
  if (left = 0) AND (right = 0) then
    engine_on := 0;
end;

end.
