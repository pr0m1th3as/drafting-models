// The 3D view of a model page: the model's 3MF, meshed for the screen by the
// site's build, turned with the mouse or a finger, each part shown, faded or
// hidden

import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { ThreeMFLoader } from "three/addons/loaders/3MFLoader.js";
import { toCreasedNormals } from "three/addons/utils/BufferGeometryUtils.js";

const MODES = ["Shown", "Faded", "Hidden"];
const CREASE = THREE.MathUtils.degToRad(30);

function main() {
  const viewer = document.querySelector(".viewer");
  if (!viewer || viewer.hidden) return;
  const stage = viewer.querySelector(".stage");
  const status = stage.querySelector(".status");
  const list = viewer.querySelector(".parts");

  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  } catch (e) {
    status.textContent = "This browser cannot show the 3D view.";
    return;
  }
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  stage.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  scene.add(new THREE.HemisphereLight(0xffffff, 0x8a8f99, 1.6));
  const camera = new THREE.PerspectiveCamera(35, 1, 0.1, 1000);
  // A light that moves with the camera, so the side in view is always lit
  const key = new THREE.DirectionalLight(0xffffff, 2.2);
  key.position.set(0.6, 1.0, 0.8);
  key.target.position.set(0, 0, -1);
  camera.add(key, key.target);
  scene.add(camera);

  const controls = new OrbitControls(camera, renderer.domElement);
  const render = () => renderer.render(scene, camera);
  controls.addEventListener("change", render);

  const resize = () => {
    const w = stage.clientWidth;
    const h = stage.clientHeight;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    render();
  };
  new ResizeObserver(resize).observe(stage);

  new ThreeMFLoader().load(
    stage.dataset.model,
    (model) => {
      // 3MF is z-up, the scene y-up
      model.rotation.x = -Math.PI / 2;
      const pivot = new THREE.Group();
      pivot.add(model);
      scene.add(pivot);

      const parts = new Map();
      model.traverse((o) => {
        if (!o.isMesh) return;
        const old = Array.isArray(o.material) ? o.material[0] : o.material;
        o.material = new THREE.MeshStandardMaterial({
          color: old.color.clone(),
          roughness: 0.55,
          metalness: 0.0,
          side: THREE.DoubleSide,
        });
        o.geometry = toCreasedNormals(o.geometry, CREASE);
        // Every placement of a part has a parent of its own, named after
        // the part, so the placements are gathered by that name
        const part = o.parent;
        const key = part.name || part;
        if (!parts.has(key)) parts.set(key, { name: part.name, meshes: [] });
        parts.get(key).meshes.push(o);
      });

      fit(pivot, camera, controls);
      partList(list, parts, render);
      viewer.querySelector(".reset").addEventListener("click", () => {
        controls.reset();
        render();
      });
      status.remove();
      resize();
    },
    undefined,
    () => {
      status.textContent = "The 3D view could not be loaded.";
    }
  );
}

// Look at the whole model from the front, to the right and above
function fit(object, camera, controls) {
  const box = new THREE.Box3().setFromObject(object);
  const centre = box.getCenter(new THREE.Vector3());
  const radius = box.getBoundingSphere(new THREE.Sphere()).radius;
  const distance = (1.15 * radius) / Math.sin(THREE.MathUtils.degToRad(35 / 2));
  const direction = new THREE.Vector3(1.0, 0.9, 1.5).normalize();
  camera.position.copy(centre).addScaledVector(direction, distance);
  camera.near = distance / 100;
  camera.far = distance * 100;
  camera.updateProjectionMatrix();
  controls.target.copy(centre);
  controls.update();
  controls.saveState();
}

// One row per part: its colour, its name, and whether it is shown, faded or
// hidden
function partList(list, parts, render) {
  for (const { name, meshes } of parts.values()) {
    const li = document.createElement("li");
    const swatch = document.createElement("span");
    swatch.className = "swatch";
    swatch.style.background = "#" + meshes[0].material.color.getHexString();
    const label = document.createElement("span");
    label.textContent = name || "part";
    const mode = document.createElement("span");
    mode.className = "mode";
    const buttons = MODES.map((m) => {
      const b = document.createElement("button");
      b.type = "button";
      b.textContent = m;
      b.setAttribute("aria-pressed", String(m === "Shown"));
      b.addEventListener("click", () => {
        for (const other of buttons) {
          other.setAttribute("aria-pressed", String(other === b));
        }
        for (const mesh of meshes) {
          mesh.visible = m !== "Hidden";
          mesh.material.transparent = m === "Faded";
          mesh.material.opacity = m === "Faded" ? 0.2 : 1.0;
          mesh.material.depthWrite = m !== "Faded";
          mesh.material.needsUpdate = true;
        }
        render();
      });
      mode.appendChild(b);
      return b;
    });
    li.append(swatch, label, mode);
    list.appendChild(li);
  }
}

main();
