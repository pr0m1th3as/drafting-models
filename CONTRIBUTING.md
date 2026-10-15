# Adding your model

Anything you designed with drafting and then made is welcome: a printed
bracket, a machined part, a case, a jig. The floodlight case,
[`models/floodlight_case/`](models/floodlight_case/), is a complete example
to copy from.

## The rules

A model is one folder, `models/<folder_name>/`, holding:

- **`<folder_name>.m`**, the primary source of the model. Called with no
  arguments, it returns a `model.Assembly` or a `solid.Shape`. The folder's
  name is the function's name: lowercase words joined by underscores, such
  as `cable_clip`, not in use already, and not differing from another
  model's name only in case.
- **Any other `.m` files the design needs**, in the same folder. A design
  may be spread over several files, but `<folder_name>.m` calls them and
  puts the model together: it is the one file the site's build calls.
- **`photos/`**, with at least one real photo of the item as made and at
  most ten. A render does not count: this repository is for things that
  were made.
  - JPEG, 1200 pixels high, at most 300 KB each, with no metadata. A
    landscape photo is 1600 x 1200, and a portrait one may be narrower,
    such as 900 x 1200. Every photo has the same height, so the carousel
    stays steady.
  - Name them as you like. They are shown in the model's carousel in
    alphabetical order, so `01_in_use.jpg`, `02_detail.jpg` sets the order.
  - ImageMagick makes one from a phone photo, stripping its metadata,
    which often holds the place it was taken. Landscape, cropped to 4:3:

    ```
    convert in.jpg -auto-orient -strip -resize 1600x1200^ -gravity center \
      -extent 1600x1200 -define jpeg:extent=300kb out.jpg
    ```

    Portrait:

    ```
    convert in.jpg -auto-orient -strip -resize x1200 \
      -define jpeg:extent=300kb out.jpg
    ```

- **`README.md`**, from which the model's page is made, laid out as in
  [The README](#the-readme) below.

**Colours.** Give every solid the colour you want it shown in, with its
`Colour` property, before `<folder_name>.m` returns. The site shows the
model as your function colours it. A model sets no transparency: visitors
fade or hide its parts in the page's viewer.

## The README

Each `##` heading on its own line. Use `## Printing` for printed parts and
`## Machining` for machined ones, or both when a model has both kinds.
`## Making it` shows how to build the model in Octave and write its parts
for making; the page shows it between the photos and the 3D view.

**Packages.** `## Making it` starts with a `Depends:` line, written as in
an Octave package's `DESCRIPTION`, naming every package the model needs,
drafting always among them, each with the oldest version it works with:

```
Depends: drafting (>= 0.2.2), parts (>= 0.1.0)
```

Only `(>= VERSION)` is taken, and a package may be named without one. The
first line of the section's first code block loads the same packages,
`pkg load drafting parts`, so that what readers copy matches what is
declared. Every package must be in the
[Octave Packages](https://gnu-octave.github.io/packages/) index: the
checks install the newest release of each, with the system libraries the
index lists for it, and run your model in an Octave that loads only these,
so a package used but not declared is caught. The page shows the line as
the packages the model requires.

````markdown
# <Title>

By *<your name>*

<A short description: what the item is and what it does.>

## How it goes together

<How the parts fit, and anything done by hand after making them, such as
setting inserts or running a tap through a thread.>

## Materials

<Everything not printed or machined, with sizes.>

## Tools

<Anything beyond a screwdriver.>

## Printing

| Part | Filament | Layer height | Print time |
|---|---|---|---|
| <part> | <filament> | <layer height> | <time> |

## Machining

<For machined parts: material, machine, operations.>

## Making it

Depends: drafting (>= <version>)

```
pkg load drafting
<the call to your function, and the write of each part to a file>
```

<Anything the reader should know when changing the model.>
````

## What the site shows

The site's build calls `<folder_name>.m` and writes the model to a 3MF
file meshed for the browser: coarse enough to load and turn quickly, not
for printing. To print, call the function yourself and write your own 3MF,
which drafting meshes accurately by default:

```
pkg load drafting
addpath (fullfile (pwd, 'models', '<folder_name>'))
write (<folder_name> (), '<folder_name>.3mf');
```

## Also welcome

- **`%!test` blocks** at the end of `<folder_name>.m`: that every part is a
  valid solid, its volume, and that parts placed together do not overlap.
  They run on every push and pull request against the newest drafting.
  `octave tools/run_tests.m <folder_name>` checks your model against the
  rules above and runs its tests locally.

## What not to commit

STL, 3MF and STEP files. The function makes them, and `.gitignore` keeps
them out.

## Licence

Everything here is GPL-3.0-or-later, like drafting. By opening a pull
request you confirm that the model and the photos are yours to share under
it.

## The pull request

One model per pull request. A maintainer checks that it follows the rules
above, not whether the design is a good one: that part is yours.
