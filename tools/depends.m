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
## @deftypefn {} {@var{D} =} depends (@var{NAME})
##
## The packages the model @var{NAME} declares that it needs.
##
## The @code{## Making it} section of @file{models/NAME/README.md} holds one
## line in the syntax of a package's @file{DESCRIPTION}, such as
##
## @example
## Depends: drafting (>= 0.2.2), parts (>= 0.1.0)
## @end example
##
## naming every package the model needs, drafting always among them, each
## with the oldest version it works with, or none.  The first line of the
## section's first code block loads the same packages, as
## @code{pkg load drafting parts}.
##
## @var{D} is a struct array with the fields @code{name} and @code{version},
## one per package in the order written; @code{version} is empty where none
## is given.  A line missing or written otherwise, drafting missing from it,
## or a @code{pkg load} line naming other packages is an error naming the
## model.
## @end deftypefn

function D = depends (NAME)

  if (nargin != 1 || ! ischar (NAME))
    error ("depends: NAME must be the name of a model.");
  endif
  root = fileparts (fileparts (mfilename ("fullpath")));
  file = fullfile (root, "models", NAME, "README.md");
  if (! exist (file, "file"))
    error ("depends: %s has no README.md.", NAME);
  endif

  ## The Making it section
  lines = strsplit (fileread (file), "\n", "collapsedelimiters", false);
  k = find (strcmp (strtrim (lines), "## Making it"), 1);
  if (isempty (k))
    error ("depends: the README of %s has no '## Making it' section.", NAME);
  endif
  e = find (strncmp (lines(k+1:end), "## ", 3), 1);
  if (isempty (e))
    sec = lines(k+1:end);
  else
    sec = lines(k+1:k+e-1);
  endif

  ## The Depends line
  t = regexp (sec, '^Depends:\s*(.*?)\s*$', "tokens", "once");
  j = find (! cellfun (@isempty, t));
  if (numel (j) != 1)
    error (strcat ("depends: the Making it section of %s needs one", ...
                   " 'Depends:' line."), NAME);
  endif
  items = strtrim (strsplit (t{j}{1}, ","));
  D = struct ("name", {}, "version", {});
  for i = 1:numel (items)
    m = regexp (items{i}, ['^([a-zA-Z][\w.-]*)', ...
                           '(\s*\(\s*>=\s*(\d+(\.\d+)*)\s*\))?$'], ...
                "tokens", "once");
    if (isempty (m))
      error (strcat ("depends: %s declares '%s'; write a package as NAME", ...
                     " or NAME (>= VERSION)."), NAME, items{i});
    endif
    v = regexp (m{2}, '\d+(\.\d+)*', "match", "once");
    D(end+1) = struct ("name", lower (m{1}), "version", v);
  endfor
  if (! any (strcmp ({D.name}, "drafting")))
    error ("depends: %s must declare drafting in its 'Depends:' line.", NAME);
  endif

  ## The pkg load line of the first code block
  f = find (strncmp (strtrim (sec), "```", 3), 1);
  if (isempty (f))
    error ("depends: the Making it section of %s has no code block.", NAME);
  endif
  code = sec(f+1:end);
  code = code(! cellfun (@isempty, strtrim (code)));
  load = {};
  if (! isempty (code))
    load = regexp (code{1}, '^\s*pkg\s+load\s+([^;]+?)\s*;?\s*$', ...
                   "tokens", "once");
  endif
  if (isempty (load))
    error (strcat ("depends: the first code block of %s's Making it", ...
                   " section must start with a 'pkg load' line."), NAME);
  endif
  load = lower (strsplit (strtrim (load{1})));
  if (! isempty (setxor (load, {D.name})))
    error (strcat ("depends: %s loads %s but declares %s; its 'pkg load'", ...
                   " line must name the packages of its 'Depends:' line."), ...
           NAME, strjoin (load, ", "), strjoin ({D.name}, ", "));
  endif

endfunction
