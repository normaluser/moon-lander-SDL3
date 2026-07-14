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

unit un.Text;

{$Mode objfpc} {$H+}    { "$H+" necessary due to conversion from String to PChar !!; AnsiString }
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES SDL3, SDL3_Image;

TYPE TAlignment = (TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT);
     TFontName  = (FONT_SMALL, FONT_BIG, FONT_MAX);

procedure drawTextLine(renderer : PSDL_Renderer; text : String; x, y, r, g, b, fontType : Integer; align : TAlignment);
procedure init_Fonts;

// ******************** implementation ********************

implementation

USES sysutils,
     un.Structs,
     un.Utils;

CONST NUM_GLYPHS   = 128;

VAR glyphs       : Array[0..Pred(ORD(FONT_MAX)), 0..NUM_GLYPHS] of TSDL_RECT;
    fontTextures : Array[0..Pred(ORD(FONT_MAX))] of PSDL_Texture;

// *****************   TEXT   *****************

procedure calcTextDimensions(text : String; fontType : Integer; VAR w, h : Integer);
VAR i, le, character : Integer;
    g : TSDL_Rect;
begin
  w := 0;
  h := 0;
  i := 0;
  le := length(text);

  for i := 1 to le do
  begin
    character := ORD(text[i]);
    g := glyphs[fontType][character];
    w := w + g.w;
    h := MAX(g.h, h);
  end;
end;

procedure drawTextLine(renderer : PSDL_Renderer; text : String; x, y, r, g, b, fontType : Integer; align : TAlignment);
VAR i, le, character, w, h : Integer;
    glyph : TSDL_Rect;
    glyph1, dest : TSDL_FRect;
begin
  if (align <> TEXT_ALIGN_LEFT) then
  begin
    calcTextDimensions(text, fontType, w, h);
    if (align = TEXT_ALIGN_CENTER) then
      x := x - (w DIV 2)
    else if (align = TEXT_ALIGN_RIGHT) then
      x := x - w;
  end;

  SDL_SetTextureColorMod(fontTextures[fontType], r, g, b);
  le := length(text);

  for i:= 1 to le do
  begin
    character := ORD(text[i]);
    glyph := glyphs[fontType][character];
    dest.x := x;
    dest.y := y;
    dest.w := glyph.w;
    dest.h := glyph.h;
    glyph1.x := glyph.x;
    glyph1.y := glyph.y;
    glyph1.w := glyph.w;
    glyph1.h := glyph.h;
    SDL_RenderTexture(renderer, fontTextures[fontType], @glyph1, @dest);
    INC(x, TRUNC(glyph.w));
  end;
end;

procedure initFont(renderer : PSDL_Renderer; fontType : Integer);
VAR g : TSDL_Rect;
    F : File;
    countread : Integer;

begin
  if fonttype = 0 then
  begin
    fontTextures[fontType] := img_loadtexture(renderer, 'fonts/small.png');
    {$i-}
    Assign (F,'fonts/small.dat');
    FileMode := fmOpenRead;
    Reset(F, sizeof(g));
    {$i+}
    If IOresult <> 0 then errorMessage('fonts/small.dat not found!');
    BlockRead(F, glyphs[0], 123, countread);     { ascii "z" = 122 + 1 ==> last record }
    close(F);
  end;

  if fonttype = 1 then
  begin
    fontTextures[fontType] := img_loadtexture(renderer, 'fonts/big.png');
    {$i-}
    Assign (F,'fonts/big.dat');
    FileMode := fmOpenRead;
    Reset(F, sizeof(g));
    {$i+}
    If IOresult <> 0 then errorMessage('fonts/big.dat not found!');
    BlockRead(F, glyphs[1], 123, countread);     { ascii "z" = 122 + 1 ==> last record }
    close(F);
  end;
end;

procedure init_Fonts;
begin
  initFont(app.renderer, ORD(FONT_SMALL));
  initFont(app.renderer, ORD(FONT_BIG));
end;

end.
