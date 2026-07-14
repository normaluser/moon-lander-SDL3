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

unit un.Init;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure init_All;
procedure init_SDL;
procedure emptyArray;
procedure atExit;

// ******************** implementation ********************

implementation

uses SDL3, SDL3_Image, SDL3_Mixer, sysutils,
     un.Structs,
     un.Defs,
     un.Utils,
     un.Sound,
     un.Text,
     un.Menue,
     un.Texture,
     un.Parameters,
     un.Stage;

procedure init_SDL;
VAR i : Byte;
begin
  if NOT SDL_Init(SDL_INIT_VIDEO) then
    errorMessage(SDL_GetError());

  for i := 0 to max_Sound do
  begin
    S_Mix[i]  := SDL_malloc(SizeOf(TMix));
    S_Mix[i]^ := Default(TMix);
  end;

  SDL_SetHint(SDL_HINT_MAIN_CALLBACK_RATE, '5');

  app.Window := SDL_CreateWindow('Moon Lander [Atlas]', xSize, ySize, SDL_WINDOW_RESIZABLE);
  if app.Window = NIL then
    errorMessage(SDL_GetError());

  app.Renderer := SDL_CreateRenderer(app.Window, NIL);
  if app.Renderer = NIL then
    errorMessage(SDL_GetError());

  SDL_HideCursor;
end;

procedure emptyArray;
VAR i : Integer;
    c, b : PAtlasImage;
begin
  for i := 0 to NUMATLASBUCKETS do
  begin
    c := atlases[i]^.next;    { Dispose the list }
    while (c <> NIL) do
    begin
      b := c^.next;
      DISPOSE(c);
      c := b;
    end;
    DISPOSE(atlases[i]);      { Dispose element / header of the Array }
  end;
end;

procedure atExit;
begin
  if ExitCode <> 0 then emptyArray;
  SDL_DestroyTexture(atlasTex);
  SDL_DestroyTexture(speedTex);
  SDL_DestroyTexture(game.BodenGrey.Texture);
  SDL_DestroyTexture(game.Boden.Texture);
  SDL_DestroyTexture(game.Background.Texture);
  SDL_DestroyRenderer(app.Renderer);
  SDL_DestroyWindow(app.Window);
  MIX_Quit;   { Quits the Music / Sound }
  SDL_Quit;   { Quits the SDL }
  if Exitcode <> 0 then WriteLn(#10,'Exitcode: ',exitcode, #10, 'SDL ErrorCode: ',SDL_GetError(),#10);
  SDL_ShowCursor;
end;

procedure pathTest;
begin
  if NOT FileExists(Atlas_Path) then ErrorMessage(Atlas_Path + ' not found!');
  if NOT FileExists(Texture_Path) then ErrorMessage(Texture_Path + ' not found!');
end;

procedure init_All;
begin
  pathTest;
  init_SDL;
  init_Sounds;
  init_Fonts;
  init_Atlas;
  init_Background;
  init_Game_Var;
  init_Title;
  init_Widgets;
end;

end.
