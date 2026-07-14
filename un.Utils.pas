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

unit un.Utils;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

function Min(a, b: Integer): Integer; INLINE;
function Max(a, b: Integer): Integer; INLINE;
function Min(a, b: Single):  Single;  INLINE;
function Max(a, b: Single):  Single;  INLINE;

function numberspeed(a : Single) : String; INLINE;
function numberfill(a : Integer) : String; INLINE;

procedure errorMessage(Message1 : PChar);
procedure logMessage(Message1 : PChar);


// ******************** implementation ********************

implementation

USES SDL3, sysutils;

function Min(a, b: Integer): Integer; INLINE;
begin
  if a < b then Min := a else Min := b;
end;

function Max(a, b: Integer): Integer; INLINE;
begin
  if a > b then Max := a else Max := b;
end;

function Min(a, b: Single): Single; INLINE;
begin
  if a < b then Min := a else Min := b;
end;

function Max(a, b: Single): Single; INLINE;
begin
  if a > b then Max := a else Max := b;
end;

procedure errorMessage(Message1 : PChar);
begin
  SDL_ShowSimpleMessageBox(SDL_MessageBox_Error,'Error Box',Message1,NIL);
  HALT(1);
end;

procedure logMessage(Message1 : PChar);
VAR Fmt : PChar;
begin
  Fmt := 'File not found: %s, #13';
  SDL_LogError(0, Fmt, Message1);
end;

function numberspeed(a : Single) : String;
begin
  numberspeed := Format('%.2f', [a]);
end;

function numberfill(a : Integer) : String;
begin
  numberfill := Format('%.3d', [a]);
end;

end.
