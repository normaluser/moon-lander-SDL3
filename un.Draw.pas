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

unit un.Draw;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES SDL3,
     un.Structs;

procedure prepareScene;
procedure presentScene;
procedure blitAtlasImage(atlas : PAtlasImage; x, y : Double; center : Integer);
procedure blitAtlasImageScaled(atlas : PAtlasImage; x, y : Double; w, h : Integer);

// ******************** implementation ********************

implementation

procedure blitAtlasImage(atlas : PAtlasImage; x, y : Double; center : Integer);
VAR dest : TSDL_FRect;
    p    : TSDL_Point;
begin
  dest.x := x;
  dest.y := y;
  dest.w := atlas^.Rec.w;
  dest.h := atlas^.Rec.h;

  if atlas^.Rot = 0 then
  begin
    if center <> 0 then
    begin
      dest.x := dest.x - (dest.w / 2);
      dest.y := dest.y - (dest.h / 2);
    end;

    SDL_RenderTexture(app.Renderer, atlas^.Tex, @atlas^.Rec, @dest);
  end
  else
  begin
    if center <> 0 then
    begin
      dest.x := dest.x - (dest.h / 2);
      dest.y := dest.y - (dest.w / 2);
    end;
    p.x := 0;
    p.y := 0;
    dest.y := dest.y + atlas^.Rec.w;

    SDL_RenderTextureRotated(app.Renderer, atlas^.Tex, @atlas^.Rec, @dest, -90, @p, SDL_FLIP_NONE);
  end;
end;

procedure blitAtlasImageScaled(atlas : PAtlasImage; x, y : Double; w, h : Integer);
VAR dest : TSDL_FRect;
    p    : TSDL_Point;
begin
  dest.x := TRUNC(x);
  dest.y := TRUNC(y);
  dest.w := w;
  dest.h := h;

  if (atlas^.rot = 1) then
  begin
    p.x := 0;
    p.y := 0;
    dest.y := dest.y + w;
    SDL_RenderTextureRotated(app.Renderer, atlas^.tex, @atlas^.Rec, @dest, -90, @p, SDL_FLIP_NONE);
  end
  else
  begin
    SDL_RenderTexture(app.Renderer, atlas^.tex, @atlas^.Rec, @dest);
  end;
end;

procedure prepareScene;
begin
  SDL_SetRenderDrawColor(app.Renderer, 0, 0, 0, 255);
  SDL_RenderClear(app.Renderer);
end;

procedure presentScene;
begin
  SDL_RenderPresent(app.Renderer);
end;

end.
