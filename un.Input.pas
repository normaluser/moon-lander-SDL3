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

unit un.Input;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

procedure doInput;

// ******************** implementation ********************

implementation

USES SDL3,
     un.Defs,
     un.Structs;

procedure toggle(VAR wert : Boolean);
begin
  if wert = True then wert := False
  else wert := True;
end;

procedure doInput;
begin
  while SDL_PollEvent(@SDL_Event) do
  begin
    CASE SDL_Event._Type of

      SDL_EVENT_QUIT:          game.exitloop := True;      { close Window }
    //SDL_MOUSEBUTTONDOWN: game.exitloop := True;          { if Mousebutton pressed }

      SDL_EVENT_KEY_DOWN:
        begin
          if (SDL_Event.key.scancode < MAX_KEYBOARD_KEYS) AND (SDL_Event.key._repeat = FALSE) then
            app.keyboard[SDL_Event.key.scancode] := 1;

          if (app.keyboard[SDL_ScanCode_Q] = 1) then game.exitloop := True;
          if (app.keyboard[SDL_ScanCode_P] = 1) OR (app.keyboard[SDL_ScanCode_p] = 1) then toggle(game.pause);
          if (app.keyboard[SDL_ScanCode_F] = 1) OR (app.keyboard[SDL_ScanCode_f] = 1) then toggle(game.director);
          if (app.keyboard[SDL_ScanCode_A] = 1) OR (app.keyboard[SDL_ScanCode_a] = 1) then toggle(game.autopilot);
        end;   { SDL_Keydown }

      SDL_EVENT_KEY_UP:
        begin
          engine_on := 0; _left := 0; _right := 0; _down := 0;
          if (SDL_Event.key.scancode < MAX_KEYBOARD_KEYS) AND (SDL_Event.key._repeat = FALSE) then
            app.keyboard[SDL_Event.key.scancode] := 0;
        end;   { SDL_Keyup }
    end;  { CASE Event }
  end;    { SDL_PollEvent }
end;

end.
