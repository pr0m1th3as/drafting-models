// The photo carousel of a model page: a track that scrolls a photo at a time,
// swiped on a touch screen, stepped with the buttons or the arrow keys, going
// round from the last photo to the first, with a thumbnail of each photo
// below it marking the one in view

for (const carousel of document.querySelectorAll(".carousel")) {
  const track = carousel.querySelector(".track");
  const slides = track.querySelectorAll(".slide");
  const thumbs = carousel.querySelectorAll(".thumb");
  const prev = carousel.querySelector(".prev");
  const next = carousel.querySelector(".next");
  const n = slides.length;

  const current = () => Math.round(track.scrollLeft / track.clientWidth);

  const show = (i) => {
    i = ((i % n) + n) % n;
    track.scrollTo({ left: i * track.clientWidth });
  };

  const update = () => {
    const i = current();
    thumbs.forEach((t, j) => {
      t.setAttribute("aria-current", String(j === i));
    });
    const t = thumbs[i];
    if (t) {
      const strip = t.parentElement;
      const left = t.offsetLeft - (strip.clientWidth - t.clientWidth) / 2;
      strip.scrollTo({ left: Math.max(0, left), behavior: "smooth" });
    }
  };

  prev.addEventListener("click", () => show(current() - 1));
  next.addEventListener("click", () => show(current() + 1));
  thumbs.forEach((t, j) => t.addEventListener("click", () => show(j)));
  track.addEventListener("scroll", update, { passive: true });
  carousel.addEventListener("keydown", (e) => {
    if (e.key === "ArrowLeft") show(current() - 1);
    if (e.key === "ArrowRight") show(current() + 1);
  });
  track.tabIndex = 0;
  update();

  if (n < 2) {
    prev.hidden = true;
    next.hidden = true;
    carousel.querySelector(".thumbs").hidden = true;
  }
}
