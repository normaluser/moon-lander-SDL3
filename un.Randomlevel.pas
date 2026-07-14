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

unit un.Randomlevel;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES SDL3,
     un.Structs;

procedure random_level(VAR game1 : TGame_def);
procedure draw_Pixel(screen : PSDL_Renderer; RGB : TSDL_Color; x, y : Double);

// ******************** implementation ********************

implementation

USES SDL3_image,
     un.Defs;

procedure draw_Pixel(screen : PSDL_Renderer; RGB : TSDL_Color; x, y : Double);
begin
  SDL_SetRenderDrawColor(screen, RGB.r, RGB.g, RGB.b, RGB.a);
  SDL_RenderPoint(screen, x, y);
end;

procedure draw_Line(screen : PSDL_Renderer; RGB : TSDL_Color; x, y : Double);
begin
  SDL_SetRenderDrawColor(screen, RGB.r, RGB.g, RGB.b, RGB.a);
  SDL_RenderLine(screen, x, y, x, ySize);
end;

procedure draw_Terrain_Line(screen : PSDL_Renderer; x, y : Double);
CONST gradient_iterations = 3;
      dark_color = 80;
      gradient_color_variance = 40;
VAR color, y1 : Integer;
    height,
    gradient_height,gradient_ratio : Single;
begin
  gradient_height := ((ySize - y) / gradient_iterations);
  for y1 := TRUNC(y) to ySize do
  begin
    height := ySize - y1;
    gradient_ratio := (TRUNC(height) MOD TRUNC(gradient_height)) / gradient_height;
    color := round(gradient_ratio * gradient_color_variance) + dark_color;
    RGB.r := color; RGB.g := color; RGB.b := color; RGB.a := 255;
    draw_Pixel(screen, RGB, x, y1);
  end;
end;

procedure random_level(VAR game1 : TGame_def);
VAR a, b, s, x, y, yd, w, h, miny, maxy, num,
    yfluct, size, speed, xdiff, ydiff : Integer;
    //Fmt : PChar;
    distance : real;
begin
  game1.Boden.Texture := SDL_CreateTexture(app.Renderer,SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, xSize, ySize);
  game1.BodenGrey.Texture := SDL_CreateTexture(app.Renderer,SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, xSize, ySize);
  SDL_SetRenderTarget(app.Renderer, game1.Boden.Texture);              { Renders into texture }

  SDL_SetRenderDrawBlendMode(app.Renderer, SDL_BLENDMODE_BLEND);
  SDL_SetTextureBlendMode(game1.Boden.Texture, SDL_BLENDMODE_BLEND);
  SDL_SetTextureBlendMode(game1.BodenGrey.Texture, SDL_BLENDMODE_BLEND);
  SDL_SetRenderDrawColor(app.Renderer, 0, 0, 0, 0);
  SDL_RenderClear(app.Renderer);

  x := 0; y := 0; yd := 0; miny := 0; maxy := 0; size := 0; game.levelscore := 0;
  yfluct := (random(10) - 5);

  num := random(Anz_Back) + 1;
  backPic.Texture := IMG_LoadTexture(app.Renderer, PChar(backPicNam[num]));
  SDL_GetTextureSize(backPic.Texture, @w, @h);
  backPic.Rect.x := 0;
  backPic.Rect.y := 0;
  backPic.Rect.w := xSize;                             { Enlarge the images to scale to the width   }
  if w <> 0 then                                       { of the playing field with variable height. }
    backPic.Rect.h := h * xSize DIV w;                 { DIV by zero !! possible }

  game1.TBack := backPic;
  //Fmt := 'Loading %s'#13;
  //SDL_LogMessage(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO,  Fmt, [PChar(backPicNam[num])]);

  while ((y > (Terrain_ySize2 - 10)) OR (y < 10)) do y := random(Terrain_ySize4);

  miny := random(Terrain_ySize4) + 10;
  maxy := random(Terrain_ySize4) + Terrain_ySize4 - 10;

  if (y > (Terrain_ySize4)) then yd := -1 else yd := 1;

  x := 0;    { start to draw }
  repeat
    if ((x mod 3) = 0) then yfluct := (random(11) - 5);

    if  ( ((y < maxy) AND (y > miny   ))
       OR ((y > maxy) AND (yfluct <  1))
       OR ((y < maxy) AND (yfluct > -1)) ) then y := y + yfluct;

    { draw landscape }
    BodenArr[x] := y + Terrain_ySize2;                            { highest point of "moonsurface" }

    draw_Terrain_Line(app.Renderer, x, y + Terrain_ySize2);       { Renders into "normal" texture }
    SDL_SetRenderTarget(app.Renderer, game1.BodenGrey.Texture);
    RGB.r := 80; RGB.g := 80; RGB.b := 80; RGB.a := 255;
    draw_Line(app.Renderer, RGB, x, y + Terrain_ySize2);
    SDL_SetRenderTarget(app.Renderer, game1.Boden.Texture);

    if (yd = 1) then                    { check for change direction }
    begin
      if (y > maxy) then
      begin
        if ( (x < (xSize - 60)) AND (game1.curr_lev.num_landings <= ANZ)) then
        begin                           { landing pad }
          s := 15 - game1.difficulty;
          if s <= 0 then s := 0;        { not negative !! }
          size := 45 + s;

          game1.curr_lev.landing_x[game1.curr_lev.num_landings] := x;
          game1.curr_lev.landing_y[game1.curr_lev.num_landings] := y + Terrain_ySize2;
          game1.curr_lev.landing_w[game1.curr_lev.num_landings] := size;

          { get distance from center-top }
          xdiff := ((xSizeHalf) -  x);
          ydiff := (y);

          if (xdiff = 0) then begin distance := ydiff end
          else if (ydiff = 0) then begin distance := xdiff end
                              else distance := sqrt((xdiff * xdiff) + (ydiff * ydiff));
          game1.curr_lev.landing_speed[game1.curr_lev.num_landings] := land_speed;
          game1.curr_lev.landing_score[game1.curr_lev.num_landings] :=
            (((16 - (size - 45)) * 100) + (round(distance / 4) * ((game1.difficulty DIV 2) + 1)));

          { Default landing pad color is blue }
          RGB := Blue;

          { ----------- bonus colored landing pads if on ------- }
          if (game1.opt_lp_bonus) then
          begin
            if (game1.curr_lev.num_landings <> 0 ) then
            begin
              speed := random(3);
              if(speed = 1 ) then begin RGB := Magenta; end;  { Magenta is for landings at 90 % velocity }
              if(speed = 2 ) then begin RGB := Green;   end;  { Green   is for landings at 80 % velocity }

              { Set the landing speed and score }
              game1.curr_lev.landing_speed[game1.curr_lev.num_landings] := game1.curr_lev.landing_speed[game1.curr_lev.num_landings] - (speed * 0.1);
              game1.curr_lev.landing_score[game1.curr_lev.num_landings] := game1.curr_lev.landing_score[game1.curr_lev.num_landings] + TRUNC(speed * 100);
            end;
          end;     { End of Bonus colors Landing Pads }

          game1.curr_lev.landing_color[game1.curr_lev.num_landings] := RGB;

          for a := 0 to size do                        { Write the landing pads onto the Terrain }
          begin
            for b := 0 to BIG do
            begin
              draw_Pixel(app.Renderer, game1.curr_lev.landing_color[game1.curr_lev.num_landings], x, y  + Terrain_ySize2 + b);     { Renders into Texture }
              SDL_SetRenderTarget(app.Renderer, game1.BodenGrey.Texture);
              draw_Pixel(app.Renderer, game1.curr_lev.landing_color[game1.curr_lev.num_landings], x, y  + Terrain_ySize2 + b);     { Renders into Texture }
              SDL_SetRenderTarget(app.Renderer, game1.Boden.Texture);
            end;

            draw_Terrain_Line(app.Renderer, x, y + Terrain_ySize2 + succ(BIG));  { Renders into Texture }
            SDL_SetRenderTarget(app.Renderer, game1.BodenGrey.Texture);
            RGB.r := 80; RGB.g := 80; RGB.b := 80; RGB.a := 255;
            draw_Line(app.Renderer, RGB, x, y  + Terrain_ySize2 + succ(BIG));    { from platform downto ground }
            SDL_SetRenderTarget(app.Renderer, game1.Boden.Texture);

            BodenArr[x] := y + Terrain_ySize2 - BIG;   { highest point of "moonsurface" and thickness of the platform }
            INC(x);
          end;                                         { End of "Write the landing pads onto the Terrain" }
          DEC(X);
          INC(game1.curr_lev.num_landings);            { game.curr_lev.num_landings++; }
        end;                                           { ((x < (xSize - 60)) }

        yd := -1;
        miny := random(Terrain_ySize4) + 10;
        maxy := random(Terrain_ySize4) + (Terrain_ySize4) - 55;
      end;                                             { y > maxy }
    end;                                               { yd == 1  }

    if (yd = -1) then
    begin
      if (y < miny) then
      begin
        yd := 1;
        miny := random(Terrain_ySize4) + 10;
        maxy := random(Terrain_ySize4) + (Terrain_ySize4) - 10;
      end;                                             { y := y + yd; }
    end;                                               { Ende yd = -1 }

    y := TRUNC(y + 0.9 * (1.4 * yd));

    INC(x);                                            {  outer loop }
  until x > (xSize - 1);                               {  start to draw }

  DEC(game1.curr_lev.num_landings);                    { Number of actually existing platforms }
  game1.curr_lev.fuel := (Fuel_Full - (game1.difficulty * 25));
  if (game1.curr_lev.fuel < min_Fuel) then game1.curr_lev.fuel := min_Fuel;

  SDL_SetRenderTarget(app.Renderer, NIL);              { Stops rendering to the texture }
end;

end.
