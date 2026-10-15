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
## @deftypefn  {} {} check_model (@var{NAME})
## @deftypefnx {} {@var{why} =} check_model (@var{NAME})
##
## Check the model @var{NAME} against the rules of @file{CONTRIBUTING.md}
## and run its tests, where it has any.
##
## The packages its README declares, with @code{depends}, are loaded and
## their versions checked; nothing else should be loaded, so that a package
## used but not declared shows up, which is why @file{tools/run_tests.m}
## calls this in an Octave of its own for each model.  Then its function
## must return a @code{model.Assembly} or a @code{solid.Shape}, its one to
## ten photos must be JPEG, 1200 pixels high, at most 1600 wide and 300 KB,
## with no metadata, and its tests must pass.
##
## The result is printed.  @var{why} lists the reasons the model fails,
## empty when it passes.
##
## @seealso{depends}
## @end deftypefn

function varargout = check_model (NAME)

  if (nargin != 1 || ! ischar (NAME))
    error ("check_model: NAME must be the name of a model.");
  endif
  root = fileparts (fileparts (mfilename ("fullpath")));
  folder = fullfile (root, "models", NAME);
  if (! isfolder (folder))
    error ("check_model: no model is named %s.", NAME);
  endif
  why = {};

  ## The README, and the packages it declares, loaded and checked
  if (! exist (fullfile (folder, "README.md"), "file"))
    why{end+1} = "no README.md";
    D = struct ("name", {}, "version", {});
  else
    try
      D = depends (NAME);
    catch ex
      why{end+1} = regexprep (ex.message, '^depends: ', "");
      D = struct ("name", {}, "version", {});
    end_try_catch
  endif
  loaded = true;
  for p = D
    try
      pkg ("load", p.name);
      v = pkg ("describe", p.name){1}.version;
      printf ("%s %s\n", p.name, v);
      if (! isempty (p.version) && compare_versions (v, p.version, "<"))
        why{end+1} = sprintf ("needs %s %s or later, and %s is installed", ...
                              p.name, p.version, v);
        loaded = false;
      endif
    catch
      why{end+1} = sprintf ("needs %s, which is not installed", p.name);
      loaded = false;
    end_try_catch
  endfor

  ## The primary source, and what it returns
  file = fullfile (folder, [NAME, ".m"]);
  if (! exist (file, "file"))
    why{end+1} = sprintf ("no %s.m", NAME);
  elseif (loaded && ! isempty (D))
    addpath (folder);
    try
      M = feval (NAME);
      if (! (isa (M, "model.Assembly") || isa (M, "solid.Shape")))
        why{end+1} = sprintf ("%s returns a %s", NAME, class (M));
      endif
    catch ex
      why{end+1} = sprintf ("%s fails: %s", NAME, ex.message);
    end_try_catch
  endif

  ## The photos
  p = [dir(fullfile (folder, "photos", "*.jpg")); ...
       dir(fullfile (folder, "photos", "*.jpeg"))];
  if (isempty (p))
    why{end+1} = "no JPEG photo in photos/";
  elseif (numel (p) > 10)
    why{end+1} = sprintf ("photos/ holds %d photos, over 10", numel (p));
  endif
  meta = {'Comment', 'Software', 'Make', 'Model', 'DateTime', ...
          'ImageDescription', 'Artist', 'Copyright'};
  for j = 1:numel (p)
    info = imfinfo (fullfile (p(j).folder, p(j).name));
    if (info.Height != 1200 || info.Width > 1600)
      why{end+1} = sprintf (strcat ("photos/%s is %d x %d, not 1200 high", ...
                                    " and at most 1600 wide"), ...
                            p(j).name, info.Width, info.Height);
    endif
    if (p(j).bytes > 300 * 1024)
      why{end+1} = sprintf ("photos/%s is %.0f KB, over 300 KB", ...
                            p(j).name, p(j).bytes / 1024);
    endif
    tags = cellfun (@(f) ! isempty (info.(f)), meta);
    if (any (tags) || ! isempty (fieldnames (info.DigitalCamera))
        || ! isempty (fieldnames (info.GPSInfo)))
      why{end+1} = sprintf ("photos/%s holds metadata", p(j).name);
    endif
  endfor

  ## The tests, where there are any
  if (exist (file, "file") && loaded && ! isempty (D))
    text = fileread (file);
    if (! isempty (regexp (text, '^%!', "lineanchors", "once")))
      if (! test (NAME, "quiet", stdout))
        why{end+1} = "tests fail";
      endif
    endif
  endif

  if (isempty (why))
    printf ("%s: PASS\n", NAME);
  else
    printf ("%s: FAIL\n", NAME);
    printf ("  %s\n", why{:});
  endif
  if (nargout > 0)
    varargout{1} = why;
  endif

endfunction
