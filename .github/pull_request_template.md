<!-- For a new model; see CONTRIBUTING.md. For anything else, describe the change. -->

**Model:** `models/<folder_name>/`, one line on what it is.

- [ ] `<folder_name>.m` takes no arguments and returns a `model.Assembly`
      or a `solid.Shape`; any other `.m` files are in the same folder and
      called by it.
- [ ] Every solid has its colour set.
- [ ] `## Making it` starts with a `Depends:` line naming every package the
      model needs, drafting among them, and its code begins with a
      `pkg load` line naming the same.
- [ ] `photos/` holds one to ten real photos of the item as made: JPEG,
      1200 pixels high and at most 1600 wide, at most 300 KB, metadata
      stripped.
- [ ] `README.md` has the title, the `By` line, the description and the
      sections CONTRIBUTING.md lists.
- [ ] No STL, 3MF or STEP files are committed.
- [ ] The model and photos are mine to share under GPL-3.0-or-later.
