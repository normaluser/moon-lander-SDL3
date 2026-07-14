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

program MoonLander;
{ without memory holes; tested with: fpc -Criot -gl -gh moonlander.pas }

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

USES SDL3,
{$IFDEF WINDOWS}
  crt,
{$ENDIF}
  un.Structs,
  un.Init,
  un.Input,
  un.Draw;

{$IF DEFINED(UNIX)}
  procedure clrscr;
  begin
    write(#27'[2J'#27'[1;1H');
    //writeln ('Screen erased');
  end;
{$ENDIF}

// ************************* CAPFRAMERATE *************************

procedure CapFrameRate(VAR remainder : Double; VAR Ticks : UInt32);
VAR wait, FrameTime : LongInt;
begin
  wait := 16 + Trunc(remainder);
  remainder := remainder - Trunc(remainder);
  frameTime := SDL_GetTicks - Ticks;
  DEC(wait, frameTime);
  if (wait < 1) then wait := 1;
  SDL_Delay(wait);
  remainder := remainder + 0.667;
  gTicks := SDL_GetTicks;
end;

begin                                                  { main program }
  clrscr;
  randomize;
  init_all;

  gRemainder := 0;
  gTicks := SDL_GetTicks;

  while game.exitloop = False do                       { main loop }
  begin
    prepareScene;
    doInput;
    app.delegate.logic;
    app.delegate.draw;
    presentScene;
    CapFrameRate(gRemainder, gTicks);
  end;                                                 { End of main loop }

  emptyArray;
  atExit;
end.
