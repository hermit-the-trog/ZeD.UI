// shared: the halftone patterns, starbursts (data-burst="n,R,r,squash"), the coupon's scissors
(function(){
  const NS="http://www.w3.org/2000/svg", ink="#232a3a";
  const defs=`<svg width="0" height="0" style="position:absolute"><defs>
   <pattern id="ht1" width="3" height="3" patternUnits="userSpaceOnUse"><circle cx="1.5" cy="1.5" r=".55" fill="${ink}"/></pattern>
   <pattern id="ht2" width="3" height="3" patternUnits="userSpaceOnUse"><circle cx="1.5" cy="1.5" r=".9" fill="${ink}"/></pattern>
   <pattern id="ht3" width="3" height="3" patternUnits="userSpaceOnUse"><rect width="3" height="3" fill="${ink}"/><circle cx="1.5" cy="1.5" r=".7" fill="#f5ecd2"/></pattern>
   <pattern id="hatch" width="4" height="4" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="1.2" height="4" fill="${ink}"/></pattern>
  </defs></svg>`;
  document.body.insertAdjacentHTML("afterbegin", defs);
  document.querySelectorAll("[data-burst]").forEach(el=>{
    const [n,R,r,sq]=el.dataset.burst.split(",").map(Number);
    const w=el.viewBox.baseVal.width,h=el.viewBox.baseVal.height,cx=w/2,cy=h/2,p=[];
    for(let i=0;i<n*2;i++){const a=Math.PI*i/n-Math.PI/2,rr=i%2?r:R;p.push((cx+Math.cos(a)*rr).toFixed(1)+","+(cy+Math.sin(a)*rr*(sq||1)).toFixed(1))}
    const pg=document.createElementNS(NS,"polygon");pg.setAttribute("points",p.join(" "));pg.setAttribute("fill",el.dataset.fill||ink);
    el.prepend(pg);
  });
  document.querySelectorAll(".coupon").forEach(el=>{
    if(el.dataset.noscissors!==undefined) return;
    el.insertAdjacentHTML("afterbegin",`<svg class="sc" viewBox="0 0 18 16"><g fill="none" stroke="${ink}" stroke-width="1.4"><circle cx="4" cy="4" r="2.6"/><circle cx="4" cy="12" r="2.6"/><path d="M6.2,5.3 L17,12.5 M6.2,10.7 L17,3.5"/></g></svg>`);
  });
  if(location.hash==="#final") document.documentElement.classList.add("final");
})();
