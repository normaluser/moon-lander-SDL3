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

unit un.Defs;

{$Mode objfpc} {$H+}
{$COPERATORS OFF}

// ******************** interface *************************

interface

USES SDL3;

CONST xSize      = 1280;
      ySize      = 800;       //900;            { hight better for laptops }

      way_x      = 0.07;      //0.05;
      way_y      = 0.10;      //0.13            { => Thrust against Gravity  }
      gravity    = 0.0;
      x_velmax   = 0.5;                         { LandingSpeed warning if speed to high }
//    y_velmax   = 1.0;                         { LandingSpeed warning if speed to high }
      difficu    = 0.00001;                     { progressive Gravity CONST will be added }
      BIG        = 4;                           { LandingPad thickness }
      ANZ        = 5;                           { LandingPad Nr => 0..Anz = Anz+1 }
      land_speed = 1;                           { Landing speed }
      Fuel_Full  = 700;
      min_Fuel   = 400;
      Max_Exp    = 26;                          { Explosion pics nr }
      Max_Back   = 99;                          { background pics nr }
      Max_Score  = 10000;                       { new Eagle each 10.000 Points }
      Timeout_M  = 65534;
      time210    = 210;
      time110    = 110;
      xSizeHalf         = xSize DIV 2;
      Terrain_ySize2    = ySize DIV 2;
      Terrain_ySize4    = ySize DIV 4;
      MAX_LINE_LENGTH   = 1024;
      MAX_KEYBOARD_KEYS = 350;
      NUMATLASBUCKETS   = 37;

      Parameter_Path    = 'data/parameter.json';
      Atlas_Path        = 'data/atlas.json';
      Texture_Path      = 'gfx/atlas.png';

      SND_EAGLE_LANDED  = 0;     { eagle_has_landed.wav }
      SND_EXPLOSION     = 1;     { explosion2.wav       }
      SND_JETS          = 2;     { jet_lp.wav           }
      SND_ON            = 3;     { Blaster_1.wav        }
      SND_OFF           = 4;     { Retro_3.wav          }
      SND_READY         = 5;     { beep1b.wav           }
      SND_GO            = 6;     { honk                 }
      SND_NEW_EAGLE     = 7;     { space_bubbles_2.wav  }
      MAX_SOUND         = 8;     { 8 Sounds with Music  }

      Magenta : TSDL_Color = ( r:255; g:  0; b:255; a:255 );
      Green   : TSDL_Color = ( r:  0; g:255; b:  0; a:255 );
      Blue    : TSDL_Color = ( r:  0; g:  0; b:255; a:255 );
      Red     : TSDL_Color = ( r:255; g:  0; b:  0; a:255 );
      Cross   : TSDL_Color = ( r:  0; g:192; b:  0; a:255 );
      White   : TSDL_Color = ( r:255; g:255; b:255; a:255 );

// ******************** implementation ********************

implementation

end.
