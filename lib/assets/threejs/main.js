import "https://cdnjs.cloudflare.com/ajax/libs/three.js/0.148.0/three.min.js";
export function init(ctx, data) {
  //Hard coding these because iFrames resize? Unsure, but innerHeight was set to 0 initially.
  let w = 1000;
  let h = 1000;

  ctx.root.innerHTML = `
    <div id='scene' style='width: ${w}px; height: ${h}px;'></div>
  `;


  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(
    75,
    //window.innerWidth / window.innerHeight,
    w/h,
    0.1,
    1000
  );

  const renderer = new THREE.WebGLRenderer();
  //renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setSize(w,h);
  document.getElementById("scene").appendChild(renderer.domElement);
  //document.body.appendChild(renderer.domElement);

  const geometry = new THREE.BoxGeometry(1, 1, 1);
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
  const cube = new THREE.Mesh(geometry, material);
  scene.add(cube);

  camera.position.z = 5;

  function animate() {
    requestAnimationFrame(animate);

    cube.rotation.x += 0.01;
    cube.rotation.y += 0.01;

    renderer.render(scene, camera);
  }

  animate();
}
