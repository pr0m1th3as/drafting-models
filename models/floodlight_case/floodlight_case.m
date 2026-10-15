## Copyright (C) 2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of drafting-models.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {drafting-models} {@var{A} =} floodlight_case ()
## @deftypefnx {drafting-models} {[@var{A}, @var{body}, @var{lid}, @var{knob}] =} floodlight_case ()
##
## A case for a small LED floodlight, whose lid turns over into its stand.
##
## @code{@var{A} = floodlight_case ()} returns the assembly: the box, the
## lid resting on the box's corner columns and the knob under the lid's post,
## the three printed parts, with the heat-set inserts and screws that hold
## them, from the @code{parts} package.  @var{body}, @var{lid} and @var{knob}
## are the printed parts themselves, as they are printed.
##
## The lid is held by four M4 countersunk screws in heat-set inserts in the
## box's corner columns, and its holes are countersunk on both faces, so it
## screws down either way up.  Right way up, the light is stored inside the
## box.  Turned over, the post under the lid stands up, the light's bracket
## rests on it, and the knob clamps the bracket with an M8 hex screw pressed
## into its pocket and turned into the post's M8 thread.
##
## Nothing is written.  For the slicer, the printed parts alone:
##
## @example
## @group
## [~, body, lid, knob] = floodlight_case ();
## write (body, 'body.3mf');
## write (lid, 'lid.3mf');
## write (knob, 'knob.3mf');
## @end group
## @end example
## @end deftypefn

function [A, body, lid, knob] = floodlight_case ()

  ## Box: inside, walls, floor and inner corner radius, mm
  L = 220;
  W = 170;
  H = 65;
  wall = 5;
  bottom = 2;
  r = 7.5;

  ## Box: the bottom rim bevelled 5 x 45, the inner edge of the top 4.8 x 45
  c = 5;
  ct = 4.8;

  ## Box: floor raised by 3 mm, with a pocket 3 deep back down to the old
  ## floor; its extents are measured from the inner corner at the least x and y
  raise = 3;
  px = [14.5, 205.5];
  py = [19.5, 150.5];
  pr = 15;

  ## Box: a 15 x 15 column in each inner corner, from the raised floor to where
  ## the top chamfer starts, its edge facing into the box rounded
  cs = 15;
  cr = 4;

  ## Box: a hole for an M4 heat-set insert in the top of each column, drawn
  ## 5.8 mm across so that it prints 5.4 for its lead-in, 9 deep for its
  ## 8.1 mm length
  hd = 5.8;
  hdepth = 9;

  ## Lid: thickness, gap to the box all round, and the 45 degree chamfer on
  ## both faces, mm; its corners follow the box's, less the gap
  T = 12;
  lr = r + wall;
  lc = 5;

  ## Lid: a cylinder under its centre, standing down from its lower face into
  ## the box, rounded into that face, and the bottom of its tapped hole rounded
  bd = 28;
  bh = 36.2;
  bf = 10;
  tf = 1;

  ## Knob: the bottom 10 mm of the cylinder as a part of its own, diamond
  ## knurled with 30 V grooves 0.8 deep winding each way at 45 degrees, the
  ## edge of its lower face rounded, and in that face a hexagonal pocket 5.5
  ## deep holding the head of an M8 hexagon screw, 13 across flats
  kh = 10;
  ks = 13;
  kd = 5.5;
  kn = 30;
  kdep = 0.8;
  kf = 2;

  ## Hardware: the length of the M4 heat-set inserts, of the M4 countersunk
  ## cross-head screws holding the lid, ISO 7046, and of the M8 hexagon head
  ## screw in the knob, ISO 4017, mm
  il = 8.1;
  sl = 20;
  ml = 25;

  ## Heights of the raised floor and of the column tops, and the screw axes
  z0 = bottom + raise;
  z1 = H + bottom - ct;
  XY = [L/2 - cs/2, W/2 - cs/2] .* [1, 1; -1, 1; -1, -1; 1, -1];

  ## The box: the cavity above the raised floor, its upright edges rounded,
  ## then walls grown outwards around it
  body = solid.box (L, W, H - raise, 'Anchor', 'base');
  body = fillet (body, edges (body, 'Direction', [0, 0, 1]), r);
  body = shell (body, faces (body, 'Normal', [0, 0, 1]), wall, ...
                'Outward', true, ...
                'Thickness', {faces(body, 'Normal', [0, 0, -1]), z0});
  body = translate (body, [0, 0, z0]);

  ## The pocket, drawn on the raised floor from its inner corner
  R = geom.Region ([px(1), py(1); px(2), py(1); px(2), py(2); px(1), py(2)]);
  R = fillet (R, pr);
  R.UCS = geom.UCS ([0, 0, 1], [-L/2, -W/2, z0]);
  body = pocket (body, R, raise);

  ## The bottom rim and the inner edge of the top
  F = faces (body, 'Normal', [0, 0, -1]);
  body = chamfer (body, edges (body, 'Face', F), c);
  zt = H + bottom;
  body = chamfer (body, edges (body, 'Within', [-L/2, -W/2, zt, L/2, W/2, zt]),
                  ct);

  ## The corner columns, standing on the raised floor against the walls
  C = solid.box (cs, cs, z1 - z0);
  C = fillet (C, edges (C, 'Within', [-1, -1, -1, 1, 1, z1 - z0 + 1]), cr);
  C = translate (C, [L/2 - cs, W/2 - cs, z0]);
  C = union (C, mirror (C, [1, 0, 0]));
  C = union (C, mirror (C, [0, 1, 0]));
  body = union (body, C);

  ## The insert holes, centred in the tops of the columns
  body = hole (body, [XY, repmat(z1, 4, 1)], hd, hdepth);
  body.Colour = [0.30, 0.50, 0.75];

  ## The lid, centred on the origin, its corners rounded and both faces' rims
  ## chamfered
  lid = solid.box (L + 2*wall, W + 2*wall, T, 'Anchor', 'centroid');
  lid = fillet (lid, edges (lid, 'Direction', [0, 0, 1]), lr);
  F = [faces(lid, 'Normal', [0, 0, 1]), faces(lid, 'Normal', [0, 0, -1])];
  lid = chamfer (lid, edges (lid, 'Face', F), lc);
  lid = union (lid, translate (solid.cylinder (bd/2, bh), [0, 0, -T/2 - bh]));
  E = edges (lid, 'Type', 'circle', ...
             'Within', [-bd/2, -bd/2, -T/2, bd/2, bd/2, -T/2]);
  lid = fillet (lid, E, bf);

  ## An M8 thread 24 deep up the centre of the cylinder from the knob's top, in
  ## a flat-bottomed tapping hole drilled 26 deep, its bottom rounded
  U = geom.UCS ([0, 0, -1], [0, 0, -T/2 - bh + kh]);
  lid = hole (lid, U, 'M8', 26, 'Material', 'plastic', 'Tip', false);
  E = edges (lid, 'Type', 'circle', ...
             'Within', [-4, -4, -T/2 - bh + kh + 1, 4, 4, -T/2]);
  lid = fillet (lid, E, tf);
  lid = thread (lid, U, 'M8', 24);

  ## Holes over the inserts: 4.3 through, the fine clearance of ISO 273, with
  ## a 90 degree seat for an ISO 7046 cross-head screw on each face, the
  ## countersink of the medium series, whose mouth the head fits through
  csk = solid.holespec ('M4', 'Clearance', 'medium', 'Countersink', true);
  spec = {'M4', Inf, 'At', XY, 'Clearance', 'fine', ...
          'Countersink', csk.countersink};
  lid = hole (lid, geom.UCS ([0, 0, 1], [0, 0, T/2]), spec{:});
  lid = hole (lid, geom.UCS ([0, 0, -1], [0, 0, -T/2]), spec{:});
  lid.Colour = [0.85, 0.85, 0.85];

  ## The knob, cut from the foot of the cylinder; the thread in it is bored out
  ## to the medium clearance of ISO 273, since the screw's head cannot turn into
  ## the hexagonal pocket along a thread
  zf = -T/2 - bh;
  K = solid.cylinder (bd, kh + 1, geom.UCS ([0, 0, 1], [0, 0, zf - 1]));
  knob = intersect (lid, K);
  lid = subtract (lid, K);
  knob = hole (knob, geom.UCS ([0, 0, 1], [0, 0, zf + kh]), 'M8', Inf, ...
               'Clearance', 'medium');

  ## The pocket for the screw's head
  a = [0:60:300]';
  R = geom.Region (ks / sqrt (3) * [cosd(a), sind(a)]);
  R.UCS = geom.UCS ([0, 0, -1], [0, 0, zf]);
  knob = pocket (knob, R, kd);

  ## The knurl, last: crossed with raised points, DIN 82 RGE, at 45 degrees,
  ## its pitch square to the grooves giving kn of them each way; the lower edge
  ## is rounded and the knurl runs out over the curve
  F = setdiff (faces (knob, 'Type', 'cylinder'),
               faces (knob, 'Within', [-bd/4, -bd/4, zf, bd/4, bd/4, zf + kh]));
  E = edges (knob, 'Type', 'circle', 'Within', [-bd, -bd, zf, bd, bd, zf]);
  knob = knurl (knob, F, pi * bd * cosd (45) / kn, kdep, 'Angle', 45, ...
                'Fillet', {E, kf});
  knob.Colour = [0.80, 0.35, 0.20];

  ## The hardware: an insert flush in the top of each column, a screw in the
  ## lid over each insert, and the M8 screw's head at the top of the knob's
  ## pocket, its shank up into the post.  The screw's head is wider at the
  ## top than the countersink, so it stands proud by hp, where the two cones
  ## meet
  sd = parts.screw.countersunk ('data', 'M4', sl, 'Drive', 'crossH');
  hp = (sd.dkt(1) - csk.countersink(1)) / 2;
  insert = parts.insert.heatset ('solid', 'M4', il);
  insert.Colour = [0.80, 0.65, 0.30];
  screw = parts.screw.countersunk ('solid', 'M4', sl, 'Drive', 'crossH');
  screw.Colour = [0.60, 0.62, 0.65];
  kscrew = parts.screw.hex ('solid', 'M8', ml, 'FullThread', true);
  kscrew.Colour = [0.60, 0.62, 0.65];

  ## Together: the lid resting on the columns, the knob under its cylinder
  A = model.Assembly ('floodlight_case');
  A = add (A, 'body', body, geom.UCS ([0, 0, 1], [0, 0, 0]));
  A = add (A, 'lid', lid, geom.UCS ([0, 0, 1], [0, 0, z1 + T/2]));
  A = add (A, 'knob', knob, geom.UCS ([0, 0, 1], [0, 0, z1 + T/2]));
  for ii = 1:4
    A = add (A, 'inserts', insert, geom.UCS ([0, 0, 1], [XY(ii,:), z1]));
    A = add (A, 'lid_screws', screw, ...
             geom.UCS ([0, 0, 1], [XY(ii,:), z1 + T + hp]));
  endfor
  A = add (A, 'knob_screw', kscrew, ...
           geom.UCS ([0, 0, -1], [0, 0, z1 + T/2 + zf + kd]));

endfunction

%!shared A, body, lid, knob, z
%! [A, body, lid, knob] = floodlight_case ();
%! z = 65 + 2 - 4.8 + 12 / 2;

%!test  # every part is one valid solid
%! assert_equal (isvalid (body), true);
%! assert_equal (isvalid (lid), true);
%! assert_equal (isvalid (knob), true);
%! assert_equal (numsolids (body), 1);
%! assert_equal (numsolids (lid), 1);
%! assert_equal (numsolids (knob), 1);

%!test  # the volumes, in mm3
%! assert_equal (volume (body), 402701.053, -1e-6);
%! assert_equal (volume (lid), 491708.124, -1e-6);
%! assert_equal (volume (knob), 4638.466, -1e-6);

%!test  # the parts do not overlap where they are placed
%! L = translate (lid, [0, 0, z]);
%! K = translate (knob, [0, 0, z]);
%! assert_equal (volume (intersect (body, L)), 0);
%! assert_equal (volume (intersect (body, K)), 0);
%! assert_equal (volume (intersect (L, K)), 0);

%!test  # four inserts and four screws, one M8 screw in the knob
%! assert_equal (numparts (A), 6);
%! assert_equal (numinstances (A), 12);

%!test  # a lid screw seats in its countersink, clear of the lid
%! S = parts.screw.countersunk ('solid', 'M4', 20, 'Drive', 'crossH');
%! S = translate (S, [102.5, 77.5, z + 6 + 0.4]);
%! assert_equal (volume (intersect (S, translate (lid, [0, 0, z]))), 0);
%! S = translate (S, [0, 0, -0.1]);
%! assert_equal (volume (intersect (S, translate (lid, [0, 0, z]))) > 0, true);

%!test  # the M8 screw's head sits in the knob's pocket, clear of the knob
%! S = parts.screw.hex ('solid', 'M8', 25, 'FullThread', true);
%! S = translate (mirror (S, [0, 0, 1]), [0, 0, z - 36.2 - 6 + 5.5]);
%! assert_equal (volume (intersect (S, translate (knob, [0, 0, z]))), 0);
