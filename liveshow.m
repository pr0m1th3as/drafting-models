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
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {} {} liveshow (@var{FILE})
## @deftypefnx {} {} liveshow (@var{FILE}, @var{name}, @var{value})
## @deftypefnx {} {@var{V} =} liveshow (@dots{})
## @deftypefnx {} {} liveshow ()
##
## Show the model a file builds, and show it again each time it is saved.
##
## @code{liveshow (@var{FILE})} runs @var{FILE} and shows the model it
## builds in a @code{model.Viewer}, titled with the file's name.  While the
## prompt is idle, the file is run again whenever it is saved, and the
## viewer redraws in place, keeping the camera.  A file that fails, or
## builds no model, prints why and leaves the last model on show.
##
## @var{FILE} may be a function or a script.  A function is called with no
## arguments and its first output is shown, so a model of this repository
## is shown as it is.  A script is run in a workspace of its own, and the
## model it leaves in the variable @code{A}, @code{S} or @code{M}, as
## drafting names an assembly, a shape and a mesh, is shown, the first of
## them that it leaves.  The model may be a @code{model.Assembly}, a
## @code{solid.Shape} or a @code{polymesh.Mesh}.  The folder of @var{FILE}
## is added to the load path, so the helpers beside it are found.
##
## Name/value pairs are passed to @code{model.Viewer}.  @code{@var{V} =
## liveshow (@dots{})} returns the viewer, for @code{opacity}, @code{pick} or
## @code{view}.  Calling @code{liveshow} again watches the new file instead.
##
## Nothing is assigned to the workspace.  The model on show is
## @code{@var{V}.Model}, which follows every rebuild, since the viewer
## returned is the one shown; a function's model is also had by calling it.
##
## @code{liveshow ()} stops watching; the window stays open.
##
## @seealso{model.Viewer, source}
## @end deftypefn

function V = liveshow (FILE, varargin)

  st = getappdata (0, "liveshow_state");
  if (isempty (st))
    st = struct ("hook", [], "file", "", "name", "", "text", NaN, ...
                 "viewer", []);
  endif

  ## Stop watching
  if (nargin == 0)
    if (! isempty (st.hook))
      remove_input_event_hook (st.hook);
      printf ("liveshow: stopped watching %s.\n", st.file);
    endif
    st.hook = [];
    setappdata (0, "liveshow_state", st);
    return;
  endif

  ## Input validation
  if (! ischar (FILE) || ! isrow (FILE))
    error ("liveshow: FILE must be a character vector.");
  endif
  file = make_absolute_filename (FILE);
  if (! exist (file, "file"))
    error ("liveshow: no such file '%s'.", FILE);
  endif

  if (! isempty (st.hook))
    remove_input_event_hook (st.hook);
  endif
  [folder, st.name] = fileparts (file);
  addpath (folder);
  st.file = file;
  st.text = NaN;
  st.viewer = model.Viewer (varargin{:});
  st.viewer.Name = st.name;
  st.hook = add_input_event_hook (@tick);
  setappdata (0, "liveshow_state", st);
  tick ();
  if (nargout > 0)
    V = st.viewer;
  endif

endfunction

## Rebuild when the watched file's text changes
function tick ()

  st = getappdata (0, "liveshow_state");
  [fid, msg] = fopen (st.file, "r");
  if (fid < 0)
    return;
  endif
  text = fread (fid, Inf, "char=>char").';
  fclose (fid);
  if (strcmp (text, st.text))
    return;
  endif
  st.text = text;
  setappdata (0, "liveshow_state", st);
  try
    st.viewer.Model = build (st.file, st.name);
    printf ("liveshow: %s shown at %s.\n", st.name,
            strftime ("%T", localtime (time ())));
  catch ex
    printf ("liveshow: %s: %s\n", st.name, ex.message);
  end_try_catch

endfunction

## Call the function and return its first output, or run the script in a
## workspace of its own and return its A, S or M
function __out__ = build (__file__, __name__)

  ## Read the file again, as it was saved
  clear (__name__);
  try
    __nout__ = nargout (__name__);
    __isfn__ = true;
  catch
    __isfn__ = false;
  end_try_catch

  if (__isfn__)
    if (__nout__ == 0)
      error ("the function returns nothing.");
    endif
    __out__ = feval (__name__);
    return;
  endif

  source (__file__);
  if (exist ("A", "var"))
    __out__ = A;
  elseif (exist ("S", "var"))
    __out__ = S;
  elseif (exist ("M", "var"))
    __out__ = M;
  else
    error ("the script leaves no variable A, S or M.");
  endif

endfunction
