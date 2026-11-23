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
    const ri=r+(R-r)*0.45;   // (shallower points: an outlined burst keeps its words clear of the stroke) (One ink, the director, Nov 22 2026)
    for(let i=0;i<n*2;i++){const a=Math.PI*i/n-Math.PI/2,rr=i%2?ri:R;p.push((cx+Math.cos(a)*rr).toFixed(1)+","+(cy+Math.sin(a)*rr*(sq||1)).toFixed(1))}
    // the burst is a printed outline with its words in ink inside, never a solid star with paper words in it: the book
    // prints in one ink, no reversed type (One ink, the director, Nov 22 2026)
    const pg=document.createElementNS(NS,"polygon");pg.setAttribute("points",p.join(" "));pg.setAttribute("fill","none");
    pg.setAttribute("stroke",ink);pg.setAttribute("stroke-width","1.5");pg.setAttribute("stroke-linejoin","miter");
    el.style.overflow="visible";   // (the stroke's outer half runs past the viewBox at the points)
    el.prepend(pg);
  });
  document.querySelectorAll(".coupon").forEach(el=>{
    if(el.dataset.noscissors!==undefined) return;
    el.insertAdjacentHTML("afterbegin",`<svg class="sc" viewBox="0 0 18 16"><g fill="none" stroke="${ink}" stroke-width="1.4"><circle cx="4" cy="4" r="2.6"/><circle cx="4" cy="12" r="2.6"/><path d="M6.2,5.3 L17,12.5 M6.2,10.7 L17,3.5"/></g></svg>`);
  });
  // one ink (One ink, the director, Nov 22 2026): "The F1 guide, advertisements, use white ink. There should only be black ink." Every block
  // of ink with words in it (a masthead, a bar, the phone footer) prints as a ruled box instead, its words in ink on
  // the paper; paper-colored marks inside such a block (the little squares between words) print in ink. The ads keep
  // their layout: the box is an inset outline, so nothing moves.
  const INK_C="rgb(35, 42, 58)", PAPER_C="rgb(245, 236, 210)";
  const blocks=[];
  document.querySelectorAll("#ad, #ad *").forEach(el=>{
    const cs=getComputedStyle(el);
    if(cs.backgroundColor===INK_C && el.textContent.trim()!==""){
      el.style.background="transparent";
      el.style.boxShadow="inset 0 0 0 1.5px "+ink;
      blocks.push(el);
    }
  });
  document.querySelectorAll("#ad, #ad *").forEach(el=>{
    const cs=getComputedStyle(el);
    if(cs.color===PAPER_C) el.style.color=ink;
    if(el.closest(".inv, .foot") || blocks.some(b=>b.contains(el))){   // (.inv and .foot are boxes in ad.css already)
      if(cs.backgroundColor===PAPER_C) el.style.background=ink;
      for(const side of ["Top","Right","Bottom","Left"])
        if(cs["border"+side+"Color"]===PAPER_C && cs["border"+side+"Style"]!=="none") el.style["border"+side+"Color"]=ink;
    }
  });
  if(location.hash==="#final") document.documentElement.classList.add("final");
})();
