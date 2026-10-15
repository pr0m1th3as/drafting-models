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
## @deftypefn {} {} requirements (@var{OUT}, @var{NAMES})
##
## Write what must be installed to build and test the models @var{NAMES}.
##
## @var{NAMES} is a cell array of model names, or empty for every model.  The
## packages each model declares with @code{depends}, and the packages those
## depend on in turn, are looked up in the Octave Packages index, the one
## @code{pkg install} reads.  Two files are written in the folder @var{OUT}:
## @file{octave-packages.txt}, one package per line, each after the packages
## it depends on, to install in that order; and @file{system-packages.txt},
## the system packages their newest releases list for this Ubuntu, such as
## Open CASCADE's for drafting.
##
## A model asking for a version newer than the newest in the index, or for a
## package the index does not hold, is an error naming the model.
##
## @seealso{depends}
## @end deftypefn

function requirements (OUT, NAMES)

  if (nargin != 2 || ! ischar (OUT) || ! (iscellstr (NAMES) || isempty (NAMES)))
    error ("requirements: give the output folder and a cell array of names.");
  endif
  root = fileparts (fileparts (mfilename ("fullpath")));
  if (isempty (NAMES))
    d = dir (fullfile (root, "models"));
    d = d([d.isdir] & ! strncmp ({d.name}, ".", 1));
    NAMES = {d.name};
  endif

  [index, ok] = urlread ("https://packages.octave.org/packages.json");
  if (! ok)
    [index, ok] = urlread (["https://gnu-octave.github.io/packages/", ...
                            "packages.json"]);
  endif
  if (! ok)
    error ("requirements: the Octave Packages index cannot be read.");
  endif
  index = jsondecode (index);

  ## This system's key in the index, such as ubuntu2604
  osr = fileread ("/etc/os-release");
  id = regexp (osr, '(?m)^ID="?(\w+)"?', "tokens", "once");
  ver = regexp (osr, '(?m)^VERSION_ID="?([\d.]+)"?', "tokens", "once");
  key = "";
  if (! isempty (id) && ! isempty (ver))
    key = [id{1}, strrep(ver{1}, ".", "")];
  endif

  order = {};
  system = {};
  for k = 1:numel (NAMES)
    for p = depends (NAMES{k})
      latest = newest (index, p.name, NAMES{k});
      if (! isempty (p.version)
          && compare_versions (latest.id, p.version, "<"))
        error (strcat ("requirements: %s needs %s %s or later, but the", ...
                       " newest in the index is %s."), ...
               NAMES{k}, p.name, p.version, latest.id);
      endif
      [order, system] = visit (index, p.name, NAMES{k}, key, order, system);
    endfor
  endfor

  if (! isfolder (OUT))
    mkdir (OUT);
  endif
  write_lines (fullfile (OUT, "octave-packages.txt"), order);
  write_lines (fullfile (OUT, "system-packages.txt"), unique (system));
  printf ("Octave packages: %s\n", strjoin (order, " "));
  printf ("system packages: %s\n", strjoin (unique (system), " "));

endfunction

## A package after the packages it depends on, with their system packages
function [order, system] = visit (index, name, model, key, order, system)

  if (any (strcmp (order, name)))
    return;
  endif
  latest = newest (index, name, model);
  deps = {};
  if (isfield (latest, "depends"))
    deps = cellstr (latest.depends);
  endif
  for j = 1:numel (deps)
    dep = lower (regexp (deps{j}, '^\s*([\w.-]+)', "tokens", "once"){1});
    if (! any (strcmp (dep, {'octave', 'pkg'})))
      [order, system] = visit (index, dep, model, key, order, system);
    endif
  endfor
  if (! isempty (key) && isfield (latest, key))
    system = [system, cellstr(latest.(key))(:)'];
  endif
  order{end+1} = name;

endfunction

function latest = newest (index, name, model)

  field = matlab.lang.makeValidName (name);
  if (! isfield (index, field))
    error ("requirements: %s needs %s, which the index does not hold.", ...
           model, name);
  endif
  v = index.(field).versions;
  if (iscell (v))
    v = v{1};
  endif
  latest = v(1);

endfunction

function write_lines (file, c)

  fid = fopen (file, "w");
  fprintf (fid, "%s\n", c{:});
  fclose (fid);

endfunction
