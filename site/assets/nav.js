// The header's toggler: below 992 px it opens and closes the links, as
// Bootstrap's navbar collapse does on the guide and the function reference

for (const nav of document.querySelectorAll(".site-nav")) {
  const toggler = nav.querySelector(".toggler");
  toggler.addEventListener("click", () => {
    const open = nav.classList.toggle("open");
    toggler.setAttribute("aria-expanded", String(open));
  });
}
