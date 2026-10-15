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
## @deftypefn  {} {} build_site (@var{OUT})
## @deftypefnx {} {} build_site (@var{OUT}, @var{CHANGES})
##
## Build the generated files of the site into the folder @var{OUT}.
##
## @code{build_site (@var{OUT})} builds every model.  Its function is called
## and the model it returns is written to @file{OUT/models/<name>/model.3mf},
## meshed for the browser, and its page, @file{index.html}, is made from its
## @file{README.md} and the names of its photos, filled from
## @file{site/templates/}.  Small copies of its photos are made with
## ImageMagick's @command{convert}, which must be installed: one for each in
## @file{OUT/models/<name>/thumbs/}, for the strip under the carousel, and
## @file{OUT/models/<name>/card.jpg} from the first, for its card on the home
## page.
##
## @var{OUT} holds only what is built: the pages, the 3MF files, the small
## copies of the photos and a record of the build.  The photos and
## @file{site/assets/} stay where they are in the repository, and
## @code{assemble_site} puts them beside the built files in the folder that
## is published.
##
## @code{build_site (@var{OUT}, @var{CHANGES})} builds only what changed,
## into a site built before in @var{OUT}.  @var{CHANGES} is a cell array of
## the paths, from the repository's root, that changed since that build:
## the models whose folders hold one of them are built again, a model whose
## folder is gone is removed, and every other page is kept as it is.  The
## whole site is built again when @file{site/} or this file changed, when
## drafting is of another version than the one the site was built with, or
## when @var{OUT} holds no record of a build.
##
## The home page, with a card for each model, is written every time, from
## the READMEs and photos alone.  @file{OUT/build.json} records the drafting
## version and the commit, from @env{GITHUB_SHA}, of the build.
##
## The environment variables @env{SITE_URL} and @env{REPO_URL} set the
## absolute addresses of the site, used in link previews, and of the
## repository, used in source links.
##
## @example
## pkg load drafting
## addpath tools
## build_site ('_site')
## assemble_site ('_site', '_public')
## @end example
##
## @seealso{assemble_site}
## @end deftypefn

function build_site (OUT, CHANGES)

  if (nargin < 1 || ! ischar (OUT))
    error ("build_site: OUT must be the name of a folder.");
  endif
  if (nargin > 1 && ! iscellstr (CHANGES))
    error ("build_site: CHANGES must be a cell array of paths.");
  endif

  site = getenv ("SITE_URL");
  if (isempty (site))
    site = "https://pr0m1th3as.github.io/drafting-models/";
  endif
  if (site(end) != "/")
    site(end+1) = "/";
  endif
  repo = getenv ("REPO_URL");
  if (isempty (repo))
    repo = "https://github.com/pr0m1th3as/drafting-models";
  endif

  root = fileparts (fileparts (mfilename ("fullpath")));
  common = struct ("repo", repo, ...
                   "drafting", pkg ("describe", "drafting"){1}.version, ...
                   "built", datestr (now (), "yyyy-mm-dd"));
  d = dir (fullfile (root, "models"));
  d = d([d.isdir] & ! strncmp ({d.name}, ".", 1));
  names = {d.name};

  ## What to build: every model, or the models that changed
  record = fullfile (OUT, "build.json");
  full = nargin < 2 || ! exist (record, "file");
  if (! full)
    last = jsondecode (fileread (record));
    full = ! strcmp (last.drafting, common.drafting) ...
           || any (strncmp (CHANGES, "site/", 5)) ...
           || any (strcmp (CHANGES, "tools/build_site.m"));
  endif
  if (full)
    build = names;
  else
    t = regexp (CHANGES, '^models/([^/]+)/', "tokens", "once");
    t = [t{:}];
    build = intersect (names, t);
  endif
  if (full)
    printf ("building every model\n");
  elseif (isempty (build))
    printf ("no model changed: the home page only\n");
  else
    printf ("building %s\n", strjoin (build, ", "));
  endif

  mkfolder (fullfile (OUT, "models"));

  ## The pages of models that are gone
  o = dir (fullfile (OUT, "models"));
  o = o([o.isdir] & ! strncmp ({o.name}, ".", 1));
  for gone = setdiff ({o.name}, names)
    confirm_recursive_rmdir (false, "local");
    rmdir (fullfile (OUT, "models", gone{1}), "s");
    printf ("%s: removed\n", gone{1});
  endfor

  cards = "";
  for k = 1:numel (names)
    name = names{k};
    folder = fullfile (root, "models", name);
    R = readme (fullfile (folder, "README.md"));
    p = [dir(fullfile (folder, "photos", "*.jpg")); ...
         dir(fullfile (folder, "photos", "*.jpeg"))];
    photos = sort ({p.name});
    F = common;
    F.title = esc (R.title);
    F.author = esc (R.author);
    F.summary = esc (first_sentence (plain (strjoin (R.intro, " "))));
    F.og_image = esc (sprintf ("%smodels/%s/photos/%s", site, name, ...
                               photos{1}));
    if (any (strcmp (name, build)))
      model_page (OUT, root, folder, name, R, photos, F, site, repo);
    endif
    cards = [cards, sprintf(["<a class=\"card\" href=\"models/%s/\">\n", ...
                             "<img src=\"models/%s/card.jpg\" alt=\"\"", ...
                             " loading=\"lazy\">\n", ...
                             "<div class=\"card-text\">\n", ...
                             "<h2>%s</h2>\n<p class=\"by\">By %s</p>\n", ...
                             "<p>%s</p>\n</div>\n</a>\n"], ...
                            name, name, F.title, F.author, F.summary)];
    if (k == 1)
      first_image = F.og_image;
    endif
  endfor

  F = common;
  F.cards = cards;
  F.og_url = esc (site);
  F.og_image = first_image;
  write_text (fullfile (OUT, "index.html"), fill ("index.html", F, root));
  write_text (record, jsonencode (struct ("drafting", common.drafting, ...
                                          "commit", getenv ("GITHUB_SHA"))));

endfunction

## A model's page, built anew: its 3MF meshed for the browser, the small
## copies of its photos and its page, in a folder of its own emptied first
function model_page (OUT, root, folder, name, R, photos, F, site, repo)

  ## Coarse enough to load and turn quickly in a browser, not for printing:
  ## the floodlight case is 0.35 MB at 0.05 mm against 2.9 MB at 0.01
  TOL = 0.05;

  dest = fullfile (OUT, "models", name);
  if (isfolder (dest))
    confirm_recursive_rmdir (false, "local");
    rmdir (dest, "s");
  endif
  mkfolder (dest);

  viewer = true;
  D = struct ("name", {}, "version", {});
  try
    D = depends (name);
    for p = D
      pkg ("load", p.name);
    endfor
    addpath (folder);
    M = feval (name);
    if (! (isa (M, "model.Assembly") || isa (M, "solid.Shape")))
      error ("it returns a %s", class (M));
    endif
    write (M, fullfile (dest, "model.3mf"), "Tolerance", TOL);
  catch ex
    printf ("%s: no 3D view: %s\n", name, ex.message);
    viewer = false;
  end_try_catch
  rmpath (folder);

  ## The small copies of the photos, cut as the stylesheet shows them, at
  ## twice their size for sharp screens: 88 x 66 in the strip, a card about
  ## 400 wide
  mkfolder (fullfile (dest, "thumbs"));
  for j = 1:numel (photos)
    shrink (fullfile (folder, "photos", photos{j}), ...
            fullfile (dest, "thumbs", photos{j}), 176, 132);
  endfor
  shrink (fullfile (folder, "photos", photos{1}), ...
          fullfile (dest, "card.jpg"), 800, 600);

  slides = "";
  thumbs = "";
  for j = 1:numel (photos)
    slides = [slides, sprintf(["<figure class=\"slide\"><img src=", ...
                               "\"photos/%s\" alt=\"Photo %d of %d\"", ...
                               " loading=\"%s\"></figure>\n"], ...
                              esc (photos{j}), j, numel (photos), ...
                              ifelse (j == 1, "eager", "lazy"))];
    thumbs = [thumbs, sprintf(["<button class=\"thumb\" type=\"button\"", ...
                               " aria-label=\"Photo %d\"><img src=", ...
                               "\"thumbs/%s\" alt=\"\"></button>\n"], ...
                              j, esc (photos{j}))];
  endfor

  F.description = md (R.intro);
  F.og_url = esc (sprintf ("%smodels/%s/", site, name));
  F.slides = slides;
  F.thumbs = thumbs;
  F.viewer_hidden = ifelse (viewer, "", " hidden");
  ## Making it sits between the photos and the model, its Depends line shown
  ## as the packages it requires, each linked to its page in the index
  making = strcmp (R.sections(:,1), "Making it");
  mk = R.sections(making,:);
  if (! isempty (mk))
    keep = cellfun (@isempty, regexp (mk{1,2}, '^Depends:', "once"));
    mk{1,2} = mk{1,2}(keep);
  endif
  F.making = sections_html (mk);
  if (! isempty (D))
    req = cell (1, numel (D));
    for j = 1:numel (D)
      req{j} = sprintf (["<a href=\"https://gnu-octave.github.io/packages/", ...
                         "%s/\">%s</a>"], esc (D(j).name), esc (D(j).name));
      if (! isempty (D(j).version))
        req{j} = [req{j}, " &ge; ", esc(D(j).version)];
      endif
    endfor
    head = "<h2>Making it</h2>\n";
    F.making = strrep (F.making, head, ...
                       sprintf (["%s<p class=\"requires\">Requires: %s", ...
                                 "</p>\n"], head, strjoin (req, ", ")));
  endif
  F.sections = sections_html (R.sections(! making,:));
  F.source = esc (sprintf ("%s/tree/main/models/%s", repo, name));
  write_text (fullfile (dest, "index.html"), fill ("model.html", F, root));
  printf ("%s: page written\n", name);

endfunction

## The title, author, introduction and sections of a model's README; the
## photos are shown by the carousel, so images are left out
function R = readme (file)

  lines = strsplit (fileread (file), "\n", "collapsedelimiters", false);
  image = ['^\s*(!\[[^\]]*\]\([^)]*\)|<img\b[^>]*>|</?p>)\s*$'];
  R = struct ("title", "", "author", "", "intro", {{}}, "sections", {{}});
  fence = false;
  for k = 1:numel (lines)
    s = lines{k};
    if (strncmp (strtrim (s), "```", 3))
      fence = ! fence;
    endif
    if (! fence && ! isempty (regexp (s, image, "once")))
      continue;
    elseif (! fence && strncmp (s, "# ", 2) && isempty (R.title))
      R.title = strtrim (s(3:end));
    elseif (! fence && strncmp (s, "## ", 3))
      R.sections(end+1,:) = {strtrim(s(4:end)), {}};
    elseif (! isempty (R.sections))
      R.sections{end,2}{end+1} = s;
    elseif (isempty (R.author) && ! isempty (regexp (s, '^By\s', "once")))
      R.author = plain (s(4:end));
    else
      R.intro{end+1} = s;
    endif
  endfor

endfunction

## The sections in the order the page shows them, the others after them;
## Materials and Tools side by side, and Printing and Machining
function html = sections_html (S)

  order = {'Making it', 'Materials', 'Tools', 'How it goes together', ...
           'Printing', 'Machining'};
  pairs = {{'Materials', 'Tools'}, {'Printing', 'Machining'}};
  rank = zeros (rows (S), 1);
  for k = 1:rows (S)
    r = find (strcmp (S{k,1}, order));
    rank(k) = ifelse (isempty (r), numel (order) + k, r);
  endfor
  [~, i] = sort (rank);
  S = S(i,:);

  block = @(k) sprintf (["<section class=\"part-section\">\n", ...
                         "<h2>%s</h2>\n%s</section>\n"], ...
                        esc (S{k,1}), md (S{k,2}));
  html = "";
  k = 1;
  while (k <= rows (S))
    paired = false;
    for p = 1:numel (pairs)
      if (k < rows (S) && strcmp (S{k,1}, pairs{p}{1})
          && strcmp (S{k+1,1}, pairs{p}{2}))
        html = [html, "<div class=\"pair\">\n", block(k), ...
                block(k+1), "</div>\n"];
        k += 2;
        paired = true;
        break;
      endif
    endfor
    if (! paired)
      html = [html, block(k)];
      k += 1;
    endif
  endwhile

endfunction

## The Markdown of a README as HTML: headings, paragraphs, lists, tables,
## fenced code, and inline code, bold, italics and links
function html = md (lines)

  html = "";
  para = {};
  list = {};
  ltag = "";
  k = 1;
  n = numel (lines);
  while (k <= n)
    s = lines{k};
    t = strtrim (s);
    h = regexp (s, '^(#{1,6}) (.*)$', "tokens", "once");
    li = regexp (s, '^\s*(-|\*|\d+\.) (.*)$', "tokens", "once");
    if (strncmp (t, "```", 3))
      [html, para] = flush_para (html, para);
      [html, list] = flush_list (html, list, ltag);
      lang = strtrim (t(4:end));
      code = {};
      k += 1;
      while (k <= n && ! strncmp (strtrim (lines{k}), "```", 3))
        code{end+1} = lines{k};
        k += 1;
      endwhile
      cls = "";
      if (! isempty (lang))
        cls = sprintf (" class=\"language-%s\"", esc (lang));
      endif
      html = [html, sprintf("<pre><code%s>%s</code></pre>\n", cls, ...
                            esc (strjoin (code, "\n")))];
    elseif (strncmp (t, "|", 1) && k < n
            && ! isempty (regexp (lines{k+1}, '^\s*\|?\s*:?-+', "once")))
      [html, para] = flush_para (html, para);
      [html, list] = flush_list (html, list, ltag);
      html = [html, "<table>\n<thead>\n", row_html(s, "th"), ...
              "</thead>\n<tbody>\n"];
      k += 2;
      while (k <= n && strncmp (strtrim (lines{k}), "|", 1))
        html = [html, row_html(lines{k}, "td")];
        k += 1;
      endwhile
      html = [html, "</tbody>\n</table>\n"];
      continue;
    elseif (isempty (t))
      [html, para] = flush_para (html, para);
      [html, list] = flush_list (html, list, ltag);
    elseif (! isempty (h))
      [html, para] = flush_para (html, para);
      [html, list] = flush_list (html, list, ltag);
      m = numel (h{1});
      html = [html, sprintf("<h%d>%s</h%d>\n", m, inline (esc (h{2})), m)];
    elseif (! isempty (li))
      [html, para] = flush_para (html, para);
      tag = ifelse (any (strcmp (li{1}, {'-', '*'})), "ul", "ol");
      if (! isempty (list) && ! strcmp (tag, ltag))
        [html, list] = flush_list (html, list, ltag);
      endif
      ltag = tag;
      list{end+1} = li{2};
    elseif (! isempty (list) && ! isempty (regexp (s, '^\s', "once")))
      list{end} = [list{end}, " ", t];
    else
      [html, list] = flush_list (html, list, ltag);
      para{end+1} = t;
    endif
    k += 1;
  endwhile
  [html, para] = flush_para (html, para);
  [html, list] = flush_list (html, list, ltag);

endfunction

function html = row_html (s, tag)

  s = strtrim (s);
  s = regexprep (s, '^\||\|$', "");
  c = strtrim (strsplit (s, "|"));
  html = "<tr>";
  for k = 1:numel (c)
    html = [html, sprintf("<%s>%s</%s>", tag, inline (esc (c{k})), tag)];
  endfor
  html = [html, "</tr>\n"];

endfunction

function [html, para] = flush_para (html, para)

  if (! isempty (para))
    html = [html, sprintf("<p>%s</p>\n", inline (esc (strjoin (para, " "))))];
    para = {};
  endif

endfunction

function [html, list] = flush_list (html, list, tag)

  if (! isempty (list))
    html = [html, sprintf("<%s>\n", tag)];
    for k = 1:numel (list)
      html = [html, sprintf("<li>%s</li>\n", inline (esc (list{k})))];
    endfor
    html = [html, sprintf("</%s>\n", tag)];
    list = {};
  endif

endfunction

## Inline Markdown on escaped text: code spans first, so that nothing inside
## one is read as markup
function s = inline (s)

  p = strsplit (s, "`");
  for k = 1:numel (p)
    if (mod (k, 2) == 0)
      p{k} = sprintf ("<code>%s</code>", p{k});
    else
      t = regexprep (p{k}, '\[([^\]]+)\]\(([^)\s]+)\)', '<a href="$2">$1</a>');
      t = regexprep (t, '\*\*(.+?)\*\*', '<strong>$1</strong>');
      p{k} = regexprep (t, '\*([^*\s][^*]*?)\*', '<em>$1</em>');
    endif
  endfor
  s = [p{:}];

endfunction

## Markdown inline text as plain text, for cards and link previews
function s = plain (s)

  s = regexprep (s, '!\[[^\]]*\]\([^)]*\)', "");
  s = regexprep (s, '\[([^\]]*)\]\([^)]*\)', '$1');
  s = regexprep (s, '[*_`]', "");
  s = strtrim (regexprep (s, '\s+', " "));

endfunction

function s = first_sentence (s)

  t = regexp (s, '^(.+?[.!?])(\s|$)', "tokens", "once");
  if (! isempty (t))
    s = t{1};
  endif

endfunction

function s = esc (s)

  s = strrep (s, "&", "&amp;");
  s = strrep (s, "<", "&lt;");
  s = strrep (s, ">", "&gt;");
  s = strrep (s, "\"", "&quot;");

endfunction

## A template of site/templates with each ${key} replaced by its field of F
function text = fill (name, F, root)

  text = fileread (fullfile (root, "site", "templates", name));
  for key = fieldnames (F)'
    text = strrep (text, ["${", key{1}, "}"], F.(key{1}));
  endfor
  left = regexp (text, '\$\{\w+\}', "match", "once");
  if (! isempty (left))
    error ("build_site: %s has no value for %s.", name, left);
  endif

endfunction

function write_text (file, text)

  fid = fopen (file, "w");
  fputs (fid, text);
  fclose (fid);

endfunction

## A copy of the photo SRC in DST, scaled to cover W x H and centred, as
## object-fit: cover shows it
function shrink (SRC, DST, W, H)

  q = @(s) ["'", strrep(s, "'", "'\\''"), "'"];
  cmd = sprintf (["convert %s -resize %dx%d^ -gravity center", ...
                  " -extent %dx%d -strip -quality 82 %s"], ...
                 q (SRC), W, H, W, H, q (DST));
  [status, out] = system (cmd);
  if (status != 0)
    error ("build_site: convert could not shrink %s: %s", SRC, strtrim (out));
  endif

endfunction

function mkfolder (d)

  if (! isfolder (d))
    mkdir (d);
  endif

endfunction

function out = ifelse (cond, a, b)

  if (cond)
    out = a;
  else
    out = b;
  endif

endfunction
