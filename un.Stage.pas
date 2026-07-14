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

unit un.Stage;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure init_Title;

// ******************** implementation ********************

implementation

USES SDL3, SDL3_image, SDL3_mixer, sysutils, JsonTools,
  un.Defs,
  un.Structs,
  un.Utils,
  un.Sound,
  un.Text,
  un.Menue,
  un.Draw,
  un.Lander,
  un.GameAI,
  un.Randomlevel,
  un.Parameters,
  un.Texture;

procedure transparency(r : TSDL_FRect; a : Byte);
begin
  SDL_SetRenderDrawBlendMode(app.renderer, SDL_BLENDMODE_BLEND);
  SDL_SetRenderDrawColor(app.renderer, 0, 0, 0, a);
  SDL_RenderFillRect(app.renderer, @r);
  SDL_SetRenderDrawBlendMode(app.renderer, SDL_BLENDMODE_NONE);
end;

procedure draw_Abfrage(GameEnd : Boolean);
var r : TSDL_FRect;
begin
  if GameEnd then
  begin
    SDL_RenderTexture(app.Renderer, game.Background.Texture, NIL, NIL);
    blitAtlasImageScaled(game.Logo.Textur, game.logo.Rect.x, game.logo.Rect.y, TRUNC(game.logo.Rect.w), TRUNC(game.logo.Rect.h));
    blitAtlasImageScaled(game.Magigames.Textur, game.Magigames.Rect.x, game.Magigames.Rect.y, TRUNC(game.Magigames.Rect.w), TRUNC(game.Magigames.Rect.h));
    drawTextLine(app.renderer, 'Game end !', xSizeHalf, 250, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
  end;

  if (game.won OR game.loose) and (NOT game.demoMode) then
  begin
    r.x := xSizeHalf - 180; r.y := 147; r.w := 360; r.h := 70;
    transparency(r, 96);
    if GameEnd then drawTextLine(app.renderer, 'Your Highscore: '   + IntToStr(game.score),      xSizeHalf, 170, 255, 255, 255, 1, TEXT_ALIGN_CENTER)
               else drawTextLine(app.renderer, 'Your Level-Score: ' + IntToStr(game.levelscore), xSizeHalf, 170, 255, 255, 255, 1, TEXT_ALIGN_CENTER);

    if game.difficulty = 5 then
    begin
      r.x := xSizeHalf - 180; r.y := 270; r.w := 360; r.h := 70;
      transparency(r, 96);
      drawTextLine(app.renderer, 'Not Bad', xSizeHalf, 290, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
    end
    else if game.difficulty = 10 then
    begin
      r.x := xSizeHalf - 200; r.y := 270; r.w := 400; r.h := 70;
      transparency(r, 96);
      drawTextLine(app.renderer, 'You think you''re hot shit, huh?', xSizeHalf, 290, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
    end
    else if game.difficulty = 15 then
    begin
      r.x := xSizeHalf - 200; r.y := 270; r.w := 400; r.h := 70;
      transparency(r, 96);
      drawTextLine(app.renderer, 'Starfleet called, they want to', xSizeHalf, 275, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
      drawTextLine(app.renderer, 'offer you a job',                xSizeHalf, 305, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
    end
    else if game.difficulty = 20 then
    begin
      r.x := xSizeHalf - 180; r.y := 270; r.w := 360; r.h := 70;
      transparency(r, 96);
      drawTextLine(app.renderer, 'The force is strong in you', xSizeHalf, 290, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
    end;
  end;
end;

procedure draw_Explosion;
begin
  if game.destroy then
  begin
    Explo[1].Rect.x := TRUNC(Eagle.x) - ((Explo[1].Rect.w / 2) - (Eagle.Rect.w / 2)); { Center explosion }
    Explo[1].Rect.y := TRUNC(Eagle.y) - ((Explo[1].Rect.h / 2) - (Eagle.Rect.h / 2));
    if game.nr < Max_Exp then          { It should play 26 explosion images... }
    begin
      INC(game.nr);
      SDL_Delay(20);
      blitAtlasImageScaled(explo[game.Nr].Textur, Explo[1].Rect.x, Explo[1].Rect.y - Eagle.Rect.h, TRUNC(Explo[1].Rect.w), TRUNC(Explo[1].Rect.h));
    end;
  end;
  if game.nr = Max_Exp then            { when all the explosion images have been drawn }
  begin
    game.loose := True;                { prevent array overflow }
    if game.Ships_remaining = 0 then   { if all ships are lost }
      game.endGame := True;
  end;
end;

procedure draw_miniEagle;
VAR i : Byte;
begin
  game.miniship.Rect.w := game.miniship.textur^.rec.w;
  game.miniship.Rect.h := game.miniship.textur^.rec.h;
  game.miniship.Rect.x := 10;
  drawTextLine(app.renderer, 'Ships remaining', 10, 10, 255, 255, 255, 1, TEXT_ALIGN_LEFT);

  if game.ships_remaining > 0 then
  begin
    for i := 1 to game.ships_remaining do
    begin
      blitAtlasImage(game.miniship.Textur, game.miniship.Rect.x, game.miniship.Rect.y - game.miniship.Rect.h, 0);
      game.miniship.Rect.x := game.miniship.Rect.x + game.miniship.Rect.w + 10;
    end;
  end;
end;

procedure draw_LandingPad_Score;
VAR i, x, y : Integer;
begin
  for i := 0 to game.curr_lev.num_landings do
  begin
    x := game.curr_lev.landing_x[i] + (game.curr_lev.landing_w[i] DIV 2);
    y := game.curr_lev.landing_y[i] + 5;
    drawTextLine(app.renderer, numberfill(game.curr_lev.landing_score[i]), x, y, 255, 255, 255, 0, TEXT_ALIGN_CENTER);
  end;
end;

procedure draw_Hud;
VAR r : TSDL_FRect;
begin
  r.x := 0; r.y := 0; r.w := xSize; r.h := 100;
  transparency(r, 96);
  drawTextLine(app.renderer, 'X-Velocity: ' + numberspeed(game.x_vel),         250, 10, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  drawTextLine(app.renderer, 'Y-Velocity: ' + numberspeed(game.y_vel),         500, 10, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  drawTextLine(app.renderer, 'Fuel: '       + IntToStr(game.fuel),             750, 10, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  drawTextLine(app.renderer, 'Score: '      + IntToStr(game.score),           1000, 10, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  drawTextLine(app.renderer, 'New Eagle : ' + IntToStr(game.maxscoreShip),    1000, 50, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  drawTextLine(app.renderer, 'Gravity: '    + IntToStr(gravity_Pr),            750, 50, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  if game.autopilot then
    drawTextLine(app.renderer, 'Autopilot ON!',                                250, 50, 255, 255, 255, 1, TEXT_ALIGN_LEFT);
  if game.demoMode then
  begin
    r.x := xSizeHalf - 180; r.y := 180; r.w := 360; r.h := 70;
    transparency(r, 96);
    drawTextLine(app.renderer, '*** D E M O  -  M O D E ***',  xSizeHalf, 190, 255, 255, 255, 1, TEXT_ALIGN_Center);
    drawTextLine(app.renderer, 'Press ENTER to exit the Demo', xSizeHalf, 220, 255, 255, 255, 0, TEXT_ALIGN_Center);
  end;
end;

procedure draw_MoonSurface;
begin
  if game.opt_fancy_Terrain
    then SDL_RenderTexture(app.Renderer, game.Boden.Texture, NIL, @game.Boden.Rect)       { fancy Texture }
    else SDL_RenderTexture(app.Renderer, game.BodenGrey.Texture, NIL, @game.Boden.Rect);  {  grey Texture }
end;

procedure draw_LandingSpeedWarn;
begin
  if game.opt_lp_warn = True then
  begin
    if (game.landed = False) AND ((game.y_vel > land_speed) OR (ABS(game.x_vel) > x_velmax)) then
      SDL_RenderTexture(app.Renderer, speedTex, NIL, @game.Boden.Rect);
  end;
end;

procedure draw_Startmeldung;
VAR r : TSDL_FRect;
begin
  r.x := xSizeHalf - 180; r.y := 147; r.w := 360; r.h := 70;
  transparency(r, 96);
  if game.Timeout > 140 then
    drawTextLine(app.renderer, 'Difficulty: ' + IntToStr(game.Difficulty), xSizeHalf, 170, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
  if game.Timeout = 165 then
    begin stopAllSound; PlaySound(SND_READY); end;
  if (game.Timeout <= 140) AND (game.Timeout > 70) then
    drawTextLine(app.renderer, 'Ready !', xSizeHalf, 170, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
  if game.Timeout = 105 then
    begin stopAllSound; PlaySound(SND_READY); end;
  if (game.Timeout < 70) then
    drawTextLine(app.renderer, 'GO !!', xSizeHalf, 170, 255, 255, 255, 1, TEXT_ALIGN_CENTER);
  if game.Timeout  = 35 then begin stopAllSound; PlaySound(SND_GO); end;
end;

procedure draw_Pause;
VAR r : TSDL_FRect;
begin
  r.x := xSizeHalf - 180; r.y := 250; r.w := 360; r.h := 70;
  transparency(r, 96);
  drawTextLine(app.renderer, '* * *   P A U S E   * * *', xSizeHalf, 270, 255, 255, 255, 1, TEXT_ALIGN_Center);
end;

procedure draw_Menue;
VAR r : TSDL_FRect;
begin
  r.x := 0; r.y := 0; r.w := xSize; r.h := ySize;
  transparency(r, 196);
  drawWidgets;
end;

procedure draw_Game;
begin
  draw_Background;
  draw_MoonSurface;
  draw_LandingSpeedWarn;
  draw_Hud;
  draw_miniEagle;
  draw_LandingPad_Score;
  draw_Lander;
  if game.Menue = True then                              { drawWidgets }
    draw_Menue
  else
  begin
    if game.endGame = False then                         { endGame = False }
    begin
      if game.director  then draw_flightdirector;
      if game.pause     then draw_Pause;
      if game.autopilot then draw_Beacon;

      if game.startGame = True then                      { startGame = True }
        draw_Startmeldung
      else
      begin                                              { startGame = False }
        draw_Explosion;
        draw_Abfrage(False);                             { game running normal }
      end;
    end
    else draw_Abfrage(True);                             { Game end ==> Titlescreen }
  end;
end;

procedure draw_Title_screen;
begin
  game.Magigames.Rect.x := xSizeHalf - game.Magigames.Rect.w / 2;
  game.Magigames.Rect.y := ySize - game.Magigames.Rect.h - 20;

  SDL_RenderTexture(app.Renderer, game.Background.Texture, NIL, NIL);
  blitAtlasImageScaled(game.Logo.Textur, game.logo.Rect.x, game.logo.Rect.y, TRUNC(game.logo.Rect.w), TRUNC(game.logo.Rect.h));
  blitAtlasImageScaled(game.Magigames.Textur, game.Magigames.Rect.x, game.Magigames.Rect.y, TRUNC(game.Magigames.Rect.w), TRUNC(game.Magigames.Rect.h));

  drawTextLine(app.renderer, 'Arrow keys control the ship',                               xSizeHalf, 170, 255, 255, 255, 1, TEXT_ALIGN_Center);
  drawTextLine(app.renderer, 'Q = Quit    P = Pause    ESC = Options ',                   xSizeHalf, 205, 255, 255, 255, 1, TEXT_ALIGN_Center);
  drawTextLine(app.renderer, 'A = Autopilot     F = Flight director',                     xSizeHalf, 240, 255, 255, 255, 1, TEXT_ALIGN_Center);

  drawTextLine(app.renderer, 'Score for each round = landing pad score + remaining fuel', xSizeHalf, 440, 255, 255, 255, 0, TEXT_ALIGN_Center);
  drawTextLine(app.renderer, 'Safe Landing requires X velocity < 0.5 and ' +
                             'Y velocity < indicated by landing pad color',               xSizeHalf, 480, 255, 255, 255, 0, TEXT_ALIGN_Center);
  drawTextLine(app.renderer, 'Free Ship every ' + numberfill(Max_Score) + ' points',      xSizeHalf, 520, 255, 255, 255, 0, TEXT_ALIGN_CENTER);
end;

procedure drawPad(color : TSDL_Color; c : Integer);
VAR a, b : Integer;
begin
  for a := 0 to 60 do
    for b := 0 to BIG do
      draw_Pixel(app.Renderer, color, xSizeHalf + c + a, 600 + b);
end;

procedure draw_Title;
VAR a : Integer;
  s1, s2, s3 : Single;
begin
  if game.Menue = True then
  begin
    SDL_RenderTexture(app.Renderer, game.Background.Texture, NIL, NIL);
    draw_Menue;
  end
  else
  begin
    draw_Title_screen;
    drawTextLine(app.renderer, 'Press',   xSizeHalf - 80, 300, 255, 255, 255, 1, TEXT_ALIGN_Center);
    drawTextLine(app.renderer, 'to Play', xSizeHalf + 88, 300, 255, 255, 255, 1, TEXT_ALIGN_Center);
    if (game.Timeout MOD 60) < 40 then
      drawTextLine(app.renderer, 'ENTER', xSizeHalf, 300, 255, 255, 255, 1, TEXT_ALIGN_Center);

    s1 := land_speed; s2 := land_speed * 0.9; s3 := land_speed * 0.8;  { 100 %, 90% and 80% of landing_speed }
    a := tick MOD 610;
    if (a >  10) AND (a < 360) then begin drawTextLine(app.renderer, 'Landing Vel. = ' + numberspeed(s1), xSizeHalf - 240, 610, 255, 255, 255, 0, TEXT_ALIGN_Center); drawPad(Blue,   -270); end;
    if (a >  60) AND (a < 410) then begin drawTextLine(app.renderer, 'Red = Too Fast!',                   xSizeHalf -  80, 610, 255, 255, 255, 0, TEXT_ALIGN_Center); drawPad(Red,    -110); end;
    if (a > 110) AND (a < 460) then begin drawTextLine(app.renderer, 'Landing Vel. = ' + numberspeed(s3), xSizeHalf +  80, 610, 255, 255, 255, 0, TEXT_ALIGN_Center); drawPad(Green,    50); end;
    if (a > 160) AND (a < 510) then begin drawTextLine(app.renderer, 'Landing Vel. = ' + numberspeed(s2), xSizeHalf + 240, 610, 255, 255, 255, 0, TEXT_ALIGN_Center); drawPad(Magenta, 210); end;

    if (a =  10) OR (a =  60) OR (a = 110) OR (a = 160) then begin stopAllSound; PlaySound(SND_ON); end;
    if (a = 360) OR (a = 410) OR (a = 460) OR (a = 510) then begin stopAllSound; PlaySound(SND_OFF); end;
  end;
end;

procedure doLandingSpeed_Warn;    { Write in the landing pads as red if you're going too fast - if on }
VAR count, b : Byte;
  x : Integer;
begin
  SDL_SetRenderTarget(app.Renderer, speedTex);                        { Renders into Texture }
  SDL_SetRenderDrawBlendMode(app.Renderer, SDL_BLENDMODE_BLEND);
  SDL_SetTextureBlendMode(speedTex, SDL_BlendMode_Blend);
  SDL_SetRenderDrawColor(app.Renderer, 0, 0, 0, 0);
  SDL_RenderClear(app.Renderer);

  if (game.opt_lp_warn = True) then
  begin
    for count := 0 to game.curr_lev.num_landings do
      for x := game.curr_lev.landing_x[count] to (game.curr_lev.landing_x[count] + game.curr_lev.landing_w[count]) do
        for b := 0 to BIG do
          draw_Pixel(app.Renderer, Red, x, game.curr_lev.landing_y[count] + b);
  end;
  SDL_SetRenderDrawBlendMode(app.Renderer, SDL_BLENDMODE_NONE);
  SDL_SetRenderTarget(app.Renderer, NIL);                             { end of "Renders into Texture" }
end;

procedure doAbfrage(GameEnd : Boolean);
begin
  if (game.won OR game.loose) then
  begin
    DEC(game.Timeout);
    if game.Timeout > 0 then SDL_DELAY(1)
    else
    begin
      if game.demoMode OR GameEnd then
      begin
        game.autopilot := False;
        init_Title;
        init_Game_Var;
      end;
      if game.endGame
        then begin game.newround := True; game.Timeout := time110; end
        else begin game.newGame  := True; game.Timeout := time110; end;
      game.gravity := menu_Grav;                    { reset of game.gravity to "start" values }
    end;
  end;
end;

procedure doStartMeldung;
begin
  DEC(game.Timeout);
  if game.Timeout > 0 then SDL_Delay(1)
  else begin game.startGame := False; game.Timeout := time110; end;
end;

procedure init_Game;
begin
  if (NOT game.destroy) OR (game.newRound) OR (game.demoMode) then      { if won, then new Stage ! }
  begin
    game.curr_lev.num_landings := 0;
    if speedTex <> NIL then SDL_DestroyTexture(speedTex);
    speedTex := SDL_CreateTexture(app.Renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, xSize, ySize);
    random_level(game);
    dolandingspeed_warn;
  end;

  Eagle.x := xSizeHalf - (Eagle.Rect.w / 2);           { half screen - half Eagle }
  Eagle.y := 80;                                       { position of the Eagle }

  game.Boden.x := 0;       game.Boden.Rect.w := xSize; { position of the Moonsurface }
  game.Boden.y := 0;       game.Boden.Rect.h := ySize; { position of the Moonsutface }

  Explo[1].Rect.x := 0;    Explo[1].Rect.w := 320;     { position of the Explosion }
  Explo[1].Rect.y := 0;    Explo[1].Rect.h := 240;     { position of the Explosion }
                                                       { position of engine flames }
  game.thruster_m.Rect.x := 0;  game.thruster_l.Rect.x := 0;  game.thruster_r.Rect.x := 0;
  game.thruster_m.Rect.y := 0;  game.thruster_l.Rect.y := 0;  game.thruster_r.Rect.y := 0;
  game.thruster_m.Rect.w := 8;  game.thruster_l.Rect.w := 10; game.thruster_r.Rect.w := 10;
  game.thruster_m.Rect.h := 32; game.thruster_l.Rect.h := 7;  game.thruster_r.Rect.h := 7;
  game.B_thrust_m := False;
  game.B_thrust_l := False;
  game.B_thrust_r := False;

  game.miniship.Rect.y := 80;                          { game.miniship.Rect.x will be set in Draw miniEagle ! }

  game.x_vel     := 0;
  game.y_vel     := 0;
  game.Nr        := 0;
  game.beacon_x  := 0;
  game.beacon_y  := 0;
  game.Timeout   := time210;                           { 21 sec for drawStartmeldung }

  game.fuel      := game.curr_lev.fuel;
  game.pause     := False;
  game.destroy   := False;
  game.exitloop  := False;
  game.won       := False;
  game.loose     := False;
  game.landed    := False;
  game.newGame   := False;
  game.newRound  := False;
  game.demoMode  := False;
  game.menue     := False;
  game.endGame   := False;
  game.startGame := True;
  game.director  := True;
  game.title     := True;
  game.ai.state  := 0;
  game.crosshairs.Rect.x := 0;
  game.crosshairs.Rect.y := 0;
end;

procedure newStage;
begin
  init_Game_Var;
  init_Game;
  game.newRound := False;
end;

procedure logic_Game;
begin
  if game.Menue = False then
  begin
    if game.endGame   then doAbfrage(True);            { Game end ==> Titlescreen }
    if game.newGame   then init_Game;                  { after Explosion }
    if game.newRound  then newStage;                   { after lost game }
    if game.startGame then doStartmeldung;

    if game.demoMode then                              { Demo Mode }
    begin
      game.gravity := 0.05;
      game.autopilot := True;
      game.Startgame := False;
      if game.pause = False then
      begin
        game_ai2(_left, _right, _down, game);          { first horizontal, then vertical; game_ai2 }
        doLander;
        if ((app.keyboard[SDL_ScanCode_RETURN] = 1) OR (app.keyboard[SDL_ScanCode_KP_ENTER] = 1)) then
        begin
          if (NOT game.landed) then                    { do not destroy a landed eagle }
            game.destroy := true;
          game.Timeout := 10;                          { shorten the doAbfrage }
        end;
        doAbfrage(True);
      end;
    end;

    if (NOT game.startGame) AND (NOT game.endGame) AND (NOT game.demoMode) then
    begin
      if game.pause = False then
      begin
        if game.autopilot then
          game_ai1(_left, _right, _down, game);        { the "best" game-AI: game_ai1 }
        doLander;
        doAbfrage(False);                              { Game running normal }
      end
      else doAbfrage(True);                            { Game end ==> Titlescreen }
    end;
  end
  else doWidgets;                                      { Game Menue }

  if (app.keyboard[SDL_SCANCODE_ESCAPE] <> 0) then
  begin
    app.keyboard[SDL_SCANCODE_ESCAPE] := 0;
    game.Menue := True;
  end;
end;

procedure logic_Title;
begin
  if game.Menue = False then                           { no Game Menue }
  begin
    INC(tick);                                         { counter for Landing Speed warn in draw_Title }
    if tick >= Timeout_M then
      tick := 0;

    if 0 = (tick MOD 560) then                         { here demoMode }
    begin
      app.delegate.logic := @logic_Game;
      app.delegate.draw  := @draw_Game;
      init_Game;
      game.demoMode := True;
    end;

    DEC(game.Timeout);                                 { counter for div. Effects in Title-Screen }
    if game.Timeout <= 0 then                          { 60 sec have expired }
      game.Timeout := Timeout_M;
    if ((app.keyboard[SDL_ScanCode_RETURN] = 1) OR (app.keyboard[SDL_ScanCode_KP_ENTER] = 1)) then
    begin
      app.delegate.logic := @logic_Game;
      app.delegate.draw  := @draw_Game;
      init_Game;
    end;
  end
  else doWidgets;                                      { Game Menue }

  if (app.keyboard[SDL_SCANCODE_ESCAPE] <> 0) then
  begin
    app.keyboard[SDL_SCANCODE_ESCAPE] := 0;
    game.Menue := True;
  end;
end;

procedure init_Title;
begin
  app.delegate.logic := @logic_Title;
  app.delegate.draw  := @draw_Title;
  game.Timeout := Timeout_M;
end;

end.
