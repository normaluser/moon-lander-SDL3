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

unit un.Texture;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES SDL3,
     un.Structs;

procedure digitalisiere_Eagle(width, hight : Integer; Rect : TSDL_FRect);
procedure draw_Background;
procedure init_Background;
procedure init_Atlas;

// ******************** implementation ********************

implementation

USES SDL3_image,
     jsontools,
     sysutils,
     un.Utils,
     un.Defs,
     un.Draw;

procedure digitalisiere_Eagle(width, hight : Integer; Rect : TSDL_FRect);
VAR Image  : PSDL_Surface;
    pixel  : PUInt32;
    Col    : UInt32;
    x,y    : Integer;
begin
  Image := SDL_CreateSurface(width, hight, SDL_PIXELFORMAT_RGBA8888);
  SDL_RenderReadPixels(app.Renderer, @Rect);
  pixel := PUInt32(Image^.pixels);  { assign the Startpointer of the Image to pixel }

  setLength(EagleArr, width, hight);
  for y := 0 to (pred(hight)) do
  begin
    for x := 0 to (pred(width)) do
    begin
      Col := UInt32(pixel[y * Image^.w + x]);
      if Col = $FF then EagleArr[x,y] := 0              { depends on the background color !!!!! }
      else EagleArr[x,y] := 1;
    end;
  end;
  SDL_DestroySurface(Image);
end;

function HashCode(Value : String) : UInt32;                              { DJB hash function }
VAR i, x : UInt32;
begin
  Result := 0;
  for i := 1 to Length(Value) do
  begin
    Result := (Result SHL 4) + ORD(Value[i]);
    x := Result AND $F0000000;
    if (x <> 0) then
      Result := Result XOR (x SHR 24);
    Result := Result AND (NOT x);
  end;
  HashCode := Result;
end;

function getAtlasImage(filename : String) : PAtlasImage;
VAR a : PAtlasImage;
    i : UInt32;
begin
  i := HashCode(filename) MOD NUMATLASBUCKETS;
  a := atlases[i]^.next;
  getAtlasImage := NIL;
  while (a <> NIL) do
  begin
    if a^.fnam = filename then
      getAtlasImage := a;
    a := a^.next;
  end;
end;

procedure init_Texture;
VAR i : Byte;
    fname : String;
begin
  for i := 1 to Max_Exp do                                               { load explosion }
  begin
    fname := 'gfx/exp' + intToStr(i) + '.png';
    Explo[i].Textur := getAtlasImage(PChar(fname));
  end;

  game.Logo.Textur := getAtlasImage('gfx/logo.png');                     { load background }
  game.logo.Rect.w := game.logo.textur^.Rec.w + 180;                     { enlarge !!  }
  game.logo.Rect.h := game.logo.textur^.Rec.h + 40;                      { enlarge !!  }
  game.logo.Rect.x := xSizeHalf - game.logo.Rect.w / 2;
  game.logo.Rect.y := 20;

  game.Magigames.Textur  := getAtlasImage('gfx/magigames_steel.gif');    { load background }
  game.Magigames.Rect.w  := game.Magigames.textur^.Rec.w * 2;            { enlarge !!  }
  game.Magigames.Rect.h  := game.Magigames.textur^.Rec.h * 2;            { enlarge !!  }

  game.thruster_m.Textur := getAtlasImage('gfx/thruster1.png');
  game.thruster_l.Textur := getAtlasImage('gfx/thruster_left.png');
  game.thruster_r.Textur := getAtlasImage('gfx/thruster_right.png');
  game.crosshairs.Textur := getAtlasImage('gfx/crosshairs.png');

  game.miniship1.Textur  := getAtlasImage('gfx/minieagle.png');
  game.lander1.Textur    := getAtlasImage('gfx/eagle.png');
  game.miniship2.Textur  := getAtlasImage('gfx/minirocket.png');
  game.lander2.Textur    := getAtlasImage('gfx/rocket.png');

  game.miniship.Textur   := game.miniship1.Textur;
  Eagle.Textur           := game.lander1.Textur;

  Eagle.Rect.x := 0;
  Eagle.Rect.y := 0;
  Eagle.Rect.w := eagle.textur^.rec.w;
  Eagle.Rect.h := eagle.textur^.rec.h;

  blitAtlasImage(eagle.Textur, Eagle.Rect.x, Eagle.Rect.y, 0);
  digitalisiere_Eagle(TRUNC(Eagle.Rect.w), TRUNC(Eagle.Rect.h), Eagle.Rect);
end;

procedure draw_Background;
begin
  SDL_RenderTexture(app.Renderer, game.TBack.Texture, NIL, @game.TBack.Rect);
end;

procedure load_Background_Names;
VAR Info : TSearchRec;
begin
  Anz_Back := 1;
  backPicNam[Anz_Back] := 'gfx/red_plain.jpg';                { emergency - background pic    }

  If FindFirst ('images/*.jpg', faAnyFile, Info) = 0 then     { if there are pictures then... }
  begin
    Anz_Back := 0;
    Repeat                                                    { load all pictures }
      INC(Anz_Back);
      With Info do
      begin
        if Anz_Back <= Max_Back then
        begin
          backPicNam[Anz_Back] := 'images/' + Name;
        end;
      end;
    Until FindNext(info) <> 0;
    FindClose(Info);
  end;
end;

function loadTexture(Pfad : String) : PSDL_Texture;
//VAR Fmt : PChar;
begin
  loadTexture := IMG_LoadTexture(app.Renderer, PChar(Pfad));
  if loadTexture = NIL then errorMessage(SDL_GetError());
  //Fmt := 'Loading %s'#13;
  //SDL_LogMessage(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO,  Fmt, [PChar(Pfad)]);
end;

procedure init_Background;
begin
  load_Background_Names;
  game.Background.Texture := LoadTexture('gfx/red_plain.jpg');            { load background }
  init_Texture;
end;

procedure initAtlasImage(VAR e : PAtlasImage);
begin
  e^.FNam := ''; e^.Rot := 0; e^.Tex := NIL; e^.next := NIL;
end;

procedure loadAtlasTexture;
begin
  atlasTex := IMG_LoadTexture(app.Renderer, Texture_Path);
  if atlasTex = NIL then
    errorMessage(SDL_GetError());
end;

procedure loadAtlasData;
VAR i, x, y, w, h, r : Integer;
    a, AtlasNew : PAtlasImage;
    N, C : TJsonNode;
    filename : String;
begin
  if FileExists(Atlas_Path) then
  begin
    { Get the JSON data }
    N := TJsonNode.Create;
    N.LoadFromFile(Atlas_Path);

    for c in n do
    begin
      filename  := c.Find('filename').AsString;
      x := c.Find('x').AsInteger;
      y := c.Find('y').AsInteger;
      w := c.Find('w').AsInteger;
      h := c.Find('h').AsInteger;
      r := c.Find('rotated').AsInteger;

      i := HashCode(filename) MOD NUMATLASBUCKETS;

      a := atlases[i];            { must be created and initialized before! }

      while (a^.next <> NIL) do
        begin a := a^.next; end;

      NEW(AtlasNEW);
      initAtlasImage(AtlasNEW);

      AtlasNEW^.Fnam := filename;
      AtlasNEW^.Rec.x := x;
      AtlasNEW^.Rec.y := y;
      AtlasNEW^.Rec.w := w;
      AtlasNEW^.Rec.h := h;
      AtlasNEW^.Rot   := r;
      AtlasNEW^.Tex   := atlasTex;
      AtlasNEW^.next  := NIL;

      a^.next := atlasNEW;
    end;
    N.free;
  end
  else
    errorMessage('Atlas-Json not found!');
end;

procedure init_Atlas;
VAR i : Integer;
begin
  for i := 0 to NUMATLASBUCKETS do
  begin
    NEW(atlases[i]);
    initAtlasImage(atlases[i]);                                       { create and initialize PAtlasImage }
  end;

  loadAtlasTexture;
  loadAtlasData;
end;

end.
