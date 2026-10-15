# Made with drafting

Things designed in code with [drafting](https://github.com/pr0m1th3as/drafting),
a CAD package for GNU Octave, and then made: printed, machined, put to
use. Each model is an Octave function that returns its parts, writes
nothing unless asked, and carries tests that check it.

| Model | What it is | By |
|---|---|---|
| [Floodlight case](models/floodlight_case/) | A case for a small LED floodlight whose lid turns over into its stand; a knurled knob and a printed M8 thread. | Andreas Bertsatos |

**Made something with drafting?** Add it: see [Adding your model](CONTRIBUTING.md).

## Using a model

Install drafting (`pkg install drafting`, after Open CASCADE's development
packages; see its README), then from the model's folder:

```
pkg load drafting
A = floodlight_case ();
show (A);
write (A, 'floodlight_case.3mf');
```

Each model's README says what to buy and how it was printed or made.

## Designing a model

`liveshow` shows a model and shows it again each time its file is saved,
keeping the camera. From the root of this repository:

```
pkg load drafting
V = liveshow ('models/floodlight_case/floodlight_case.m');
```

It takes a function, showing its first output, or a script, showing the
variable `A`, `S` or `M` it leaves (an assembly, a shape or a mesh). It
assigns nothing to the workspace: the model on show is `V.Model`.
`liveshow ()` stops watching.

## The site

The site, at <https://pr0m1th3as.github.io/drafting-models/>, is built
from the models on every push to `main`: a page for each model with its
photos, a 3D view and its README, and a card for each on the home page.
Each push builds only the models that changed. What is built, the pages,
the 3MF files and small copies of the photos, is kept on the branch
`built-site`; the photos and the stylesheet and scripts stay in the
repository, and are put beside the built files only in the folder that is
published. To build it locally and look at it, with ImageMagick installed
for the small copies of the photos:

```
pkg load drafting
addpath tools
build_site ('_site')
assemble_site ('_site', '_public')
```

then serve `_public`, for example with `python3 -m http.server -d _public`,
and open the address it prints.

## Tests

Each push and pull request checks the models it changes against the
rules of [CONTRIBUTING.md](CONTRIBUTING.md) and runs their tests, with the
newest drafting release. Every model is checked once a week, so a drafting
release that breaks an older design shows up here. Locally, one model or
all of them:

```
octave tools/run_tests.m floodlight_case
octave tools/run_tests.m
```

## Adding your model

One folder with your model's function and a few photos of the real item:
see [CONTRIBUTING.md](CONTRIBUTING.md), and the floodlight case for a
complete example.

## Licence

GPL-3.0-or-later, like drafting. See [LICENSE](LICENSE).
