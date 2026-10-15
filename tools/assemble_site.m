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
## @deftypefn {} {} assemble_site (@var{BUILT}, @var{OUT})
##
## Put the site together in the folder @var{OUT}, ready to publish.
##
## @var{BUILT} is a site that @code{build_site} wrote: the pages, the 3MF
## files and its record.  @var{OUT} receives a copy of them, the stylesheet
## and scripts of @file{site/assets/}, and the photos of every model built,
## taken from @file{models/<name>/photos/} as they are in the repository.
## Nothing in @var{BUILT} is changed, and the photos are stored only once,
## in the repository.
##
## @var{OUT} is emptied first, so it must be a folder of its own, not
## @var{BUILT} and not a folder of the repository.
##
## @example
## pkg load drafting
## addpath tools
## build_site ('_site')
## assemble_site ('_site', '_public')
## @end example
##
## @seealso{build_site}
## @end deftypefn

function assemble_site (BUILT, OUT)

  if (nargin != 2 || ! ischar (BUILT) || ! ischar (OUT))
    error ("assemble_site: BUILT and OUT must be the names of folders.");
  endif
  root = fileparts (fileparts (mfilename ("fullpath")));
  built = canonicalize_file_name (BUILT);
  if (isempty (built) || ! isfolder (built))
    error ("assemble_site: there is no built site in '%s'.", BUILT);
  endif
  out = make_absolute_filename (OUT);
  if (strcmp (out, built) || strcmp (out, root)
      || strncmp (out, [root, filesep], numel (root) + 1)
         && ! strncmp (out, [root, filesep, "_"], numel (root) + 2))
    error (strcat ("assemble_site: OUT must be a folder of its own, not", ...
                   " BUILT and not a folder of the repository."));
  endif

  if (isfolder (out))
    confirm_recursive_rmdir (false, "local");
    rmdir (out, "s");
  endif
  mkdir (out);

  ## The built files, without the files of the branch's checkout
  for e = dir (built)'
    if (! any (strcmp (e.name, {'.', '..', '.git'})))
      copyfile (fullfile (built, e.name), out);
    endif
  endfor

  ## The stylesheet and scripts
  copyfile (fullfile (root, "site", "assets"), out);

  ## The photos of every model built, from the repository
  m = dir (fullfile (built, "models"));
  m = m([m.isdir] & ! strncmp ({m.name}, ".", 1));
  for k = 1:numel (m)
    src = fullfile (root, "models", m(k).name, "photos");
    if (isfolder (src))
      copyfile (src, fullfile (out, "models", m(k).name));
    endif
  endfor
  printf ("assembled %d models in %s\n", numel (m), OUT);

endfunction
