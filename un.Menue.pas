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

unit un.Menue;

{$Mode objfpc} {$H+}    { "$H+" necessary for conversion of String to PChar !!; H+ => AnsiString }
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure init_Widgets;
procedure doWidgets;
procedure drawWidgets;

// ******************** implementation ********************

implementation

USES SDL3, SDL3_Image, SDL3_Mixer, JsonTools, sysutils,
     un.Defs,
     un.Structs,
     un.Draw,
     un.Text,
     un.Texture,
     un.Parameters,
     un.Utils;

TYPE me      = RECORD                                    { me = Menue }
                 txt  : String[60];                      { text }
                 x, y : Integer;                         { coordinate x, y }
               end;
     an      = RECORD                                    { an = Answers }
                 w, sw,
                 min, max : Integer;
               end;

CONST maxanz = 10;                                       { max Anz of Menue Points }
      resu   = 1;                                        { resu == Resume }
      fanc   = 2;                                        { fanc == fancy Terrain }
      prog   = 3;                                        { prog == progressive Gravity }
      land   = 4;                                        { land == landing Pad speed }
      vari   = 5;                                        { vari == variable landing Speed Platforms }
      mode   = 6;                                        { mode == Lander Model }
      grav   = 7;                                        { grav == Gravity Slider }
      soun   = 8;                                        { soun == sound Slider }
      musi   = 9;                                        { musi == music Slider }
      fini   = 10;                                       { fini == Quit }

VAR menu        : ARRAY[1..maxanz] of me;                { Array Menu }
    ant         : ARRAY[1..maxanz] of an;                { Array Answers }
    he          : ARRAY[1..maxanz] of String[60];        { Array Helptexts at bottom }
    wa          : ARRAY[2..maxanz, 0..1] of String[20];  { Array Answers as String }

function toggle(a, unter, ober, wahl: Integer) : Integer;      { Number, lower limit, upper limit }
VAR w : boolean;
begin
  toggle := a;
  w := true;
  if ((wahl = grav) OR (wahl = soun) OR (wahl = musi)) then w := false;
  if w = true then
  begin
    if a > ober  then toggle := unter;
    if a < unter then toggle := ober;
  end
  else
  begin
    if a > ober  then toggle := ober;
    if a < unter then toggle := unter;
  end
end;

// *****************   Stage  *****************

procedure draw_Bar(a : TSDL_FRect; wwith, vol, max : integer);
begin
  a.w := round((wwith - 4) * vol DIV max);
  SDL_SetRenderDrawColor(app.Renderer, 0, 255, 0, 255);                 { green }
  SDL_RenderFillRect(app.Renderer, @a);                                 { bar graph }
  a.x := a.x - 3;   a.y := a.y - 3;
  a.w := wwith + 2; a.h := a.h + 6;
  SDL_SetRenderDrawColor(app.Renderer, 255, 255, 255, 255);             { white }
  SDL_RenderRect(app.Renderer, @a);                                     { lines }
end;

procedure drawWidgets;
var i : Byte;
    r : TSDL_FRect;
begin
  drawTextLine(app.Renderer, '>', menu[anz].x - 30, menu[anz].y, 0, 255, 0, ORD(FONT_BIG), TEXT_ALIGN_LEFT);
  for i := 1 to maxAnz do
  begin
    if i = anz then drawTextLine(app.Renderer, menu[i].txt, menu[i].x , menu[i].y,   0, 255,   0, ORD(FONT_BIG), TEXT_ALIGN_LEFT)
               else drawTextLine(app.Renderer, menu[i].txt, menu[i].x , menu[i].y, 255, 255, 255, ORD(FONT_BIG), TEXT_ALIGN_LEFT);
    drawTextLine(app.Renderer, he[anz], 600, 650, 255, 255, 255, ORD(FONT_BIG), TEXT_ALIGN_CENTER);
  end;

  for i := fanc to mode do   { from 2 to 6 }
  begin
    if i = anz then drawTextLine(app.Renderer, '< ' + wa[i, ant[i].w] + ' >', menu[i].x + 400, menu[i].y,   0, 255,   0, ORD(FONT_BIG), TEXT_ALIGN_LEFT)
               else drawTextLine(app.Renderer, '< ' + wa[i, ant[i].w] + ' >', menu[i].x + 400, menu[i].y, 255, 255, 255, ORD(FONT_BIG), TEXT_ALIGN_LEFT);
  end;

  r.x := menu[grav].x + 400; r.y := menu[grav].y; r.w := 260; r.h :=  40;        { Gravity bar graph }
  draw_Bar(r, 284, ant[grav].w, 100);

  r.x := menu[soun].x + 400; r.y := menu[soun].y; r.w := 260; r.h :=  40;        { Sound bar graph }
  draw_Bar(r, 284, game.SoundVol, 100);

  r.x := menu[musi].x + 400; r.y := menu[musi].y; r.w := 260; r.h :=  40;        { Music bar graph }
  draw_Bar(r, 284, game.MusicVol, 100);
end;

// *****************   DEMO  *****************

procedure fancy;
begin
  game.opt_fancy_Terrain := Boolean(ant[fanc].w);
end;

procedure progressive;
begin
  game.opt_prog_grav := Boolean(ant[prog].w);
end;

procedure landing;
begin
  game.opt_lp_warn := Boolean(ant[land].w);
end;

procedure variable;
begin
  game.opt_lp_bonus := Boolean(ant[vari].w);
end;

procedure model;
begin
  if ant[mode].w = 0 then
  begin
    game.miniship.Textur := game.miniship1.Textur;   { Eagle }
    Eagle.Textur         := game.lander1.Textur;
  end
  else
  begin
    game.miniship.Textur := game.miniship2.Textur;   { Rocket }
    Eagle.Textur         := game.lander2.Textur;
  end;
  Eagle.Rect.w := eagle.textur^.rec.w;
  Eagle.Rect.h := eagle.textur^.rec.h;

  blitAtlasImage(eagle.Textur, Eagle.Rect.x, Eagle.Rect.y, 0);
  digitalisiere_Eagle(TRUNC(Eagle.Rect.w), TRUNC(Eagle.Rect.h), Eagle.Rect);
end;

procedure sl_gravity;
begin
  gravity_Pr := ant[grav].w;
  menu_Grav := gravity_Pr * 0.001;
  game.Gravity := menu_Grav + gravity;
  he[grav] := 'Gravity: ' + intToStr(ant[grav].w) + ' (Standard = 50)';
end;

procedure sound;
VAR i : byte;
begin
  for i := 0 to PRED(max_Sound) do                   { all channels without music }
  begin
    Mix_SetTrackGain(S_Mix[i]^.track,  ant[soun].w * 0.01);
    he[soun] := 'Sound volume: ' + IntToStr(ant[soun].w) + ' %';
    game.SoundVol := ant[soun].w;
  end;
end;

procedure music;                                     { only music channel }
begin
  Mix_SetTrackGain(S_Mix[Max_Sound]^.track,  ant[musi].w * 0.01);
  he[musi] := 'Music volume: ' + IntToStr(ant[musi].w) + ' %';
  game.MusicVol := ant[musi].w;
end;

procedure resume;
begin
  game.Menue := False;
  app.keyboard[SDL_ScanCode_RETURN] := 0;
  app.keyboard[SDL_ScanCode_KP_ENTER] := 0;
  app.keyboard[SDL_ScanCode_SPACE] := 0;
  saveGameParameter;
end;

procedure quit_game;
begin
  game.exitloop := True;
end;

procedure action;
begin
  case anz of
    resu : resume;        // 1
    fanc : fancy;         // 2
    prog : progressive;   // 3
    land : landing;       // 4
    vari : variable;      // 5
    mode : model;         // 6
    grav : sl_gravity;    // 7
    soun : sound;         // 8
    musi : music;         // 9
    fini : quit_game;     // 10
  end;
end;

procedure init_Widgets;
CONST xx = xSizeHalf - 300;                       { x - Coord. of the Menue    }
begin
  anz := 1;                                       { Cursor preset to 1st place }
  wa[fanc, 0] := 'Off';     wa[fanc, 1] := 'On';  { Answer as string           }
  wa[prog, 0] := 'Off';     wa[prog, 1] := 'On';
  wa[land, 0] := 'Off';     wa[land, 1] := 'On';
  wa[vari, 0] := 'Off';     wa[vari, 1] := 'On';
  wa[mode, 0] := 'Eagle';   wa[mode, 1] := 'Rocket';

  menu[resu].txt := 'Resume';                        menu[resu].x := xx;   menu[resu].y :=  90;
  menu[fanc].txt := 'Fancy Terrain';                 menu[fanc].x := xx;   menu[fanc].y := 140;
  menu[prog].txt := 'progressive Gravity';           menu[prog].x := xx;   menu[prog].y := 190;
  menu[land].txt := 'Landing Pad speed warning';     menu[land].x := xx;   menu[land].y := 240;
  menu[vari].txt := 'variable speed Landing Pads';   menu[vari].x := xx;   menu[vari].y := 290;
  menu[mode].txt := 'Lander Model (Eagle / Rocket)'; menu[mode].x := xx;   menu[mode].y := 340;
  menu[grav].txt := 'Gravity';                       menu[grav].x := xx;   menu[grav].y := 390;
  menu[soun].txt := 'Sound Vol';                     menu[soun].x := xx;   menu[soun].y := 440;
  menu[musi].txt := 'Musik Vol';                     menu[musi].x := xx;   menu[musi].y := 490;
  menu[fini].txt := 'Quit Game';                     menu[fini].x := xx;   menu[fini].y := 540;

  { Answer String                                    lower limit   answer  higher Limit  answer   step         size    helptext strings }

  ant[resu].w := 1;                                  ant[resu].min := 0;   ant[resu].max := 0;    ant[resu].sw := 1;   he[resu] := 'Back to Game!';
  ant[fanc].w := Integer(game.opt_fancy_Terrain);    ant[fanc].min := 0;   ant[fanc].max := 1;    ant[fanc].sw := 1;   he[fanc] := 'toggle terrain color';
  ant[prog].w := Integer(game.opt_prog_grav);        ant[prog].min := 0;   ant[prog].max := 1;    ant[prog].sw := 1;   he[prog] := 'toggle progressive Gravity';
  ant[land].w := Integer(game.opt_lp_warn);          ant[land].min := 0;   ant[land].max := 1;    ant[land].sw := 1;   he[land] := 'toggle landing speed warning';
  ant[vari].w := Integer(game.opt_lp_bonus);         ant[vari].min := 0;   ant[vari].max := 1;    ant[vari].sw := 1;   he[vari] := 'toggle variable speed for landing pads [at next level]';
  ant[mode].w := 0;                                  ant[mode].min := 0;   ant[mode].max := 1;    ant[mode].sw := 1;   he[mode] := 'toggle Lander Model [Eagle / Rocket]';
  ant[grav].w := gravity_Pr;                         ant[grav].min := 0;   ant[grav].max := 100;  ant[grav].sw := 1;   he[grav] := 'toggle Gravity (Standard 50) [0..100]';
  ant[soun].w := game.SoundVol;                      ant[soun].min := 0;   ant[soun].max := 100;  ant[soun].sw := 1;   he[soun] := 'toggle Sound Vol [0..100]';
  ant[musi].w := game.MusicVol;                      ant[musi].min := 0;   ant[musi].max := 100;  ant[musi].sw := 10;  he[musi] := 'toggle Music Vol [0..100]';
  ant[fini].w := 1;                                  ant[fini].min := 0;   ant[fini].max := 0;    ant[fini].sw := 1;   he[fini] := 'Quit the Game!';

  sl_gravity;       { initialise gravity }
  sound;            { initialise sound }
  music;            { initialise music }
end;

procedure doWidgets;
begin
  if (app.keyboard[SDL_SCANCODE_UP] = 1) then
  begin
    app.keyboard[SDL_SCANCODE_UP] := 0;
    DEC(anz); if anz < 1 then anz := maxanz;
  end;

  if (app.keyboard[SDL_SCANCODE_DOWN] = 1) then
  begin
    app.keyboard[SDL_SCANCODE_DOWN] := 0;
    INC(anz); if anz > maxanz then anz := 1;
  end;

  if (app.keyboard[SDL_SCANCODE_LEFT] = 1) then
  begin
    if anz = soun then begin app.keyboard[SDL_SCANCODE_LEFT] := 1; SDL_Delay(50); end else app.keyboard[SDL_SCANCODE_LEFT] := 0;
    ant[anz].w := toggle(ant[anz].w - ant[anz].sw, ant[anz].min, ant[anz].max, anz);
    if (anz <> resu) AND (anz <> fini) then action;
  end;

  if (app.keyboard[SDL_SCANCODE_RIGHT] = 1) then
  begin
    if anz = soun then begin app.keyboard[SDL_SCANCODE_RIGHT] := 1; SDL_Delay(50); end else app.keyboard[SDL_SCANCODE_RIGHT] := 0;
    ant[anz].w := toggle(ant[anz].w + ant[anz].sw, ant[anz].min, ant[anz].max, anz);
    if (anz <> resu) AND (anz <> fini) then action;
  end;

  if ((app.keyboard[SDL_SCANCODE_SPACE] = 1) OR (app.keyboard[SDL_SCANCODE_RETURN] = 1) OR (app.keyboard[SDL_SCANCODE_KP_ENTER] = 1)) then
  begin
    if (anz = resu) OR (anz = fini) then action;
  end;
end;

end.
