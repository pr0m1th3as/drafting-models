## Check models against the rules of CONTRIBUTING.md and run their tests
## where they have any, each in an Octave of its own that loads only the
## packages the model declares; exit 1 if any model fails
##
##   octave tools/run_tests.m              every model in models/
##   octave tools/run_tests.m NAME ...     those models only
tools = fileparts (mfilename ("fullpath"));
root = fullfile (fileparts (tools), "models");
d = dir (root);
d = d([d.isdir] & ! strncmp ({d.name}, ".", 1));
names = {d.name};
args = argv ();
if (! isempty (args))
  unknown = setdiff (args, names);
  if (! isempty (unknown))
    error ("run_tests: no model is named %s.", strjoin (unknown, ", "));
  endif
  names = args(:)';
endif
octave = fullfile (OCTAVE_HOME (), "bin", "octave-cli");
bad = {};
for k = 1:numel (names)
  code = sprintf ("addpath ('%s'); exit (! isempty (check_model ('%s')))", ...
                  strrep (tools, "'", "''"), names{k});
  status = system (sprintf ('"%s" --norc --no-history --eval "%s"', ...
                            octave, code));
  if (status != 0)
    bad{end+1} = names{k};
  endif
endfor
if (! isempty (bad))
  printf ("failed: %s\n", strjoin (bad, ", "));
endif
exit (! isempty (bad));
