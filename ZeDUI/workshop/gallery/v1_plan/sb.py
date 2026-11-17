import json,glob,re,os,html
src='src/spreads'
SP={}
for f in glob.glob(src+'/[0-9]*.json'):
    d=json.load(open(f)); SP[d['id']]=d
STOP=set('the a an of and to in on at is are it its for with by or as that this from your you each one two'.split())
W=lambda s:set(w for w in re.findall(r"[a-z]+",s.lower()) if w not in STOP and len(w)>2)
def title(d): return [b['chapter'][1] for b in d['left']['blocks'] if 'chapter' in b][0]
STORY={'hero','old_job','the_plan','the_route','open_for_business','customers','smoke_break','night_shift','driving_in','fixing_the_car','barricading','stocking_shelves','pumping_gas','keeping_count'}
# hand notes: id -> (must show / change, status)   status: keep | check | retake | new
N={
'hero':("The whole screen in play: both windows on their first tabs, the belt, Angel standing in the Fossoil forecourt in daylight. Nothing else open.","check"),
'desk':("The main menu as the desk: every icon visible, pointer on nothing. No tooltip.","keep"),
'options_menu':("ZeD setup with the Find field empty, Look group at top; second shot the game's Interface page with a grayed 'Does nothing with ZeD active' row in frame.","keep"),
'inventory_compare':("Same character, same spot, same container, same items in both shots: vanilla first, then ZeD. One open stack. This pair also feeds pitch image 1, so take it wide and clean.","retake"),
'context_menus':("Right-click the same item in vanilla and in ZeD. ZeD strip with the round 1b icons; the label above the strip readable.","keep"),
'health_compare':("Same wound in vanilla and ZeD (a bandaged scratch reads best). Feeds pitch image 3.","check"),
'moodles':("Three or more moodles showing, one balloon open with its tail on the moodle. Feeds pitch image 3.","check"),
'crafting':("A recipe open with ingredients partly missing, so the have/need marks show. Take the vanilla B42 crafting window on the same recipe too (new), for pitch image 4.","retake"),
'building':("A recipe open, the ghost of the piece visible in the world behind the window.","check"),
'driving_in':("The wagon's dashboard at the foot, fuel needle on E; second shot the cabin seat picker (pop-out, no window). The printed text still says 'Enter Vehicle window'; it gets rewritten.","check"),
'customers':("Angel, Light + Blue, outside the Fossoil store with survivors queuing; belt in frame, both hands empty.","keep"),
'controller_map':("The controller map from the window menu, pad glyphs readable at half size.","keep"),
'controller':("Pad connected: the Character wheel with the Belt slice; a window's help line showing pad prompts. Feeds pitch image 2.","keep"),
'full_or_simple':("Each pair framed identically, Immersive and Simple, so only the style differs.","keep"),
'multiplayer':("Server tab with other players listed; chat open. Names must be QA's own test names.","check"),
'night_shift':("Angel, Dark + Blue, night, at the Fossoil: dashboard lit amber, watch light on.","keep"),
'stocking_shelves':("Angel, Light + Blue, inside the Fossoil: backpack column and three shelf columns, one item mid-drag.","keep"),
'themes':("One scene, same windows, repeated per theme and accent so only the color changes.","keep"),
}
PARTS=[
("Before you play","Stage 0. Every run passes through these.",['desk','options_menu','sandbox_ingame','mod_manager','mod_settings','turn_off','load_order'],None),
("The first ten minutes","Stage 1. What nearly every player touches in every run, and what they complain about most.",['inventory_compare','item_cards','grid_view','context_menus','equip_doll','belt','customers','action_bar_compare','moodles','health_compare','watches'],("cin_ang_open","Angel, Light + Blue: the Fossoil in the morning, both windows on Loot","keep")),
("The first day","Stage 2. Bags and containers, food, books, TV and radio, sleep.",['every_window','bubbles','messages','questions','stocking_shelves','loadouts','cooking','ovens','radios','reading_writing','skills','old_job','the_plan','thermal'],("cin_mck_kitchen","McKline, High Contrast + Red: his kitchen, Cooking and the oven","keep")),
("The first week","Stage 3. The map, barricades, crafting, and the first car.",['the_route','barricading','crafting','building','foraging_furniture','driving_in','vehicle_tab','fixing_the_car','pumping_gas','dashboards','car_radio','smoke_break'],("cin_koh_vehicle","Kohners, the broken-down car: Equipment and Vehicle","keep")),
("Settling in","Stages 4 and 5. Only long runs get here.",['laundry','farm','fishing','two_way_radios','night_shift','keeping_count'],("cin_lau_lake","Laura, Light + Teal: the lake, a walkie and Fishing","keep")),
("On a controller","For the pad and Steam Deck player. Pitch image 2 points here.",['controller_map','controller','quick_actions','controller_highlight'],("cin_pad_wheel","NEW: a survivor mid-street, pad connected, the Here and now wheel open, no windows","new")),
("Your way","Themes, styles, and what you can turn off. Then multiplayer and uploading.",['themes','open_for_business','see_through','hidden_actions','full_or_simple','survival_guide','multiplayer','uploader'],("cin_koh_dusk","Kohners, Dark + Pink: driving at dusk, the dashboard and the car radio, no windows","keep")),
]
assert sorted(['hero']+[c for p in PARTS for c in p[2]])==sorted(SP)
FEATURE=['hero','desk','customers','moodles','stocking_shelves','cooking','the_route','driving_in','pumping_gas','fishing','night_shift','controller','open_for_business']
BACK={}
for k,v in {'lot':'hero every_window see_through controller_highlight hidden_actions grid_view inventory_compare foraging_furniture item_cards equip_doll building health_compare thermal loadouts context_menus action_bar_compare themes crafting',
 'field':'cooking radios two_way_radios vehicle_tab belt bubbles moodles watches questions car_radio dashboards reading_writing keeping_count sandbox_ingame fishing',
 'roof':'messages controller full_or_simple quick_actions survival_guide controller_map','farm':'farm','house':'laundry ovens',
 'fossoil':'skills old_job the_plan the_route driving_in fixing_the_car barricading stocking_shelves open_for_business pumping_gas customers smoke_break night_shift',
 'menu':'desk options_menu mod_manager mod_settings turn_off load_order uploader','void':'multiplayer'}.items():
    for i in v.split(): BACK[i]=k
BTXT={'lot':"Backdrop now: QA's parking lot (glass roof, a few cars). The full capture has open game under the windows, so it re-crops wide, but the place is plain.",
 'field':"Backdrop now: QA's test field (mowed grass, a road, a doghouse). Re-crops wide, but the place is plain.",
 'roof':"Backdrop now: QA's flat sand roof. Re-crops wide, but there is nothing to look at.",
 'farm':"Backdrop: the farm plot with crops and animals. Re-crops wide and reads well.",'house':"Backdrop: the house interior with the appliance in the room. Re-crops wide and reads well.",
 'fossoil':"Backdrop: the Fossoil, West Point. Re-crops wide and reads well.",'menu':"A menu screen on the desk: already shown whole. No crop change.",
 'void':"Backdrop now: half the captures are a black void with one tile lit. Retake in a street with other players in view."}
RETAKE={'equip_doll':"The tall window covers the character and the street. Retake with the window to one side and the character standing clear.",
 'health_compare':"The tall Health window covers the character. Retake with the character clear beside it, a visible wound.",
 'old_job':"Both tall panels cover the middle of the screen. Retake each with Angel clear beside the window, the Fossoil behind.",
 'skills':"Uses the same two tall captures as Old Job: retake once, use in both.",'fishing':"The line is cast on mowed grass. Retake at water.",'multiplayer':None,'inventory_compare':None,'crafting':None}
def lines(x,y,w,n):
    return ''.join('<rect class="ln" x="%d" y="%d" width="%d" height="10"/>'%(x,y+k*34,w if k%5!=4 else w*0.6) for k in range(n))
def lay(d):
    P=[(p['src'],(p['box'][2]-p['box'][0])/3840.0) for s in('left','right') for p in d[s].get('prints',[]) if 'box' in p]
    seen=[];
    for a in P:
        if a[0] not in [x[0] for x in seen]: seen.append(a)
    P=seen; n=len(P); feat=d['id'] in FEATURE
    o=['<svg viewBox="0 0 1920 1080" role="img" aria-label="layout sketch">','<rect class="desk" x="0" y="0" width="1920" height="1080"/>','<rect class="page" x="48" y="28" width="912" height="1012"/><rect class="page" x="960" y="28" width="912" height="1012"/>']
    R=[]
    if feat:
        o.append(lines(258,170,632,14 if n>1 else 22))
        R.append((960,28,912,1012))
        if n>1: R.append((258,690,632,300))
    else:
        o.append(lines(258,170,632,8))
        if n==1: R=[(1010,250,800,450)]; o.append(lines(1030,760,632,6))
        else:
            R=[(1010,90,800,450),(1010,570,800,450)]
            for k in range(min(n-2,2)): R.append((258+k*326,560,306,172))
            if n==2: o.append(lines(258,480,632,12))
    o.append('<line class="spine" x1="960" y1="28" x2="960" y2="1040"/>')
    for k,(x,y,w,h) in enumerate(R,1):
        fs=110 if w>500 else 70
        o.append('<rect class="print" x="%d" y="%d" width="%d" height="%d"/><text x="%d" y="%d" font-size="%d" font-weight="700">%d</text>'%(x,y,w,h,x+w/2,y+h/2+fs*.35,fs,k))
    o.append('</svg>')
    names=[]
    for k,(nm,sh) in enumerate(P):
        role='full page, half the screen at full height' if (feat and k==0) else ('wide, at least 45% of the screen' if k<2 else ('closer look, small' if k<4 else 'cut or move to another spread'))
        names.append('%s: now %d%% of the screen wide; %s'%(nm.replace('.png',''),round(sh*100),role))
    return ''.join(o),names,n,feat
def rects(d):
    out=[]
    for side in('left','right'):
        for p in d[side].get('prints',[]):
            try:
                b=p['box']; s=p['scale']; x,y=p['at']; out.append((x,y,(b[2]-b[0])*s,(b[3]-b[1])*s,p['src']))
            except Exception: pass
    return out
LAST=[]
def svg(rs,new=False,full=False):
    LAST[:]=[r[4] for r in rs]
    o=['<svg viewBox="0 0 1920 1080" role="img" aria-label="layout sketch">','<rect class="desk" x="0" y="0" width="1920" height="1080"/>']
    if not full: o.append('<rect class="page" x="48" y="28" width="912" height="1012"/><rect class="page" x="960" y="28" width="912" height="1012"/><line class="spine" x1="960" y1="28" x2="960" y2="1040"/>')
    for x,y,w,h,lab in rs:
        o.append('<rect class="%s" x="%d" y="%d" width="%d" height="%d"/>'%('pnew' if new else 'print',x,y,w,h))
        k=rs.index((x,y,w,h,lab))+1; fs=min(110,max(48,int(min(w,h)*0.5)))
        o.append('<text x="%d" y="%d" font-size="%d" font-weight="700">%d</text>'%(x+w/2,y+h/2+fs*0.35,fs,k))
    o.append('</svg>'); return ''.join(o)
frames=[]
def add(kind,name,stage,shot,status,sv,caps=None,extra=None,files=None,lay=None): frames.append(dict(lay=list(LAST),kind=kind,name=name,stage=stage,shot=shot,status=status,svg=sv,caps=caps or [],extra=extra or [],files=files or []))
# pitch
add('pitch',"Before and after","Pitch","One moment, one place, split down the spine: the game's own inventory and loot on the left page, ZeD-GUI on the right. Same character, same container, same items. The screenshots fill the pages; the book shows only as a frame. Must still read at 116 x 65.","retake",svg([(70,150,870,760,'vanilla: inventory + loot'),(980,150,870,760,'ZeD: Character + World + belt')],True),["One line only: 'The same moment, before and after.'"],["No ink notes. No sticky."],['van_01','zed_01_hero_mid'])
add('pitch',"On a controller","Pitch","Pad connected. Left: the Character wheel open in play. Right: the inventory with the pointing hand on a row and the help line showing the pad prompts. Glyphs readable at half size.","keep",svg([(90,170,820,720,'Character wheel, in play'),(1010,170,820,720,'inventory, pointing hand + help line')],True),["'Everything works on a pad. Nothing needs a mouse.'"],["Ink: at most 2 (the hand, the help line)."],['zqa_g3_wheel_character_eat','zqa_g3_footer_pad'])
add('pitch',"What you look at every minute","Pitch","Four crops, one per quarter: the context menu strip, the Health tab, a moodle with its balloon, the action bar over the head. Each a different system, each large.","check",svg([(80,150,410,360,'context strip'),(520,150,410,360,'Health tab'),(990,150,410,360,'moodle balloon'),(1430,150,410,360,'action bar'),(80,560,850,380,'vanilla context menu, for scale'),(990,560,850,380,'belt + watch')],True),["'Menus, health, moodles and the action bar.'"],["Ink: one word per crop, no arrows."],['zed_20_ctx_strip','van_20'])
add('pitch',"Crafting and building","Pitch","The B42 crafting window as the game draws it, left; the Crafting tab on the same recipe, right. Under them, the Building tab with a recipe open.","new",svg([(80,150,850,500,'vanilla B42 crafting window (NEW)'),(990,150,850,500,'Crafting tab, same recipe'),(520,690,880,280,'Building tab')],True),["'Crafting and building, in the World window.'"],["Ink: at most 3."],['van_craft_b42 (new)'])
add('pitch',"Before you install","Pitch","A printed manual page, no story: the build it runs on, single player and multiplayer, adding to and removing from a save, turning parts off, other UI mods, controller and Steam Deck, languages. Right page: ZeD setup, so the reader sees the switches. The facts are the director's to confirm; none are filled in here.","new",svg([(1030,180,640,700,'ZeD setup: the groups, Immersive or Simple')],True),["Table, not a caption: one row per question, one line each."],["No ink. One sticky: the single line a visitor most needs."],['mm4_01_options_zed'])
add('front',"The cover","Front","The desk, the book and the discs. Unchanged.","keep",svg([(360,90,1200,900,'00a cover')],False,True))
add('front',"Contents","Front","New printed spread: the seven parts and their chapters with page numbers. No capture needed.","new",svg([],True),[],["No ink, no sticky."])
def chap(i,stage):
    d=SP[i]; sv,names,npr,feat=lay(d); note,status=N.get(i,("Re-crop the beta 19 capture wide. Check it at the 1.0 sweep for old icons, dark pop-ups or an older layout.","check"))
    caps=[b['caption'][1] for s in('left','right') for b in d[s]['blocks'] if 'caption' in b]
    ink=sum(1 for s in('left','right') for m in d[s].get('marks',[]) if 'text' in m)
    rep=0;st=0
    for s in('left','right'):
        pg=d[s]; t=pg.get('sticky')
        if t:
            st+=1; other=set().union(*[W(m['text']) for m in pg.get('marks',[]) if 'text' in m]+[W(c) for c in caps]+[set()])
            if len(W(t['text'])&other)/max(1,len(W(t['text'])))>=0.6: rep+=1
    extra=["Notes now: %d ink, %d sticky%s."%(ink,st,(", %d sticky repeats the ink or caption"%rep) if rep else "")]
    if ink>8: extra.append("Cut ink to 4 a page.")
    b=BACK[i]; extra.append(BTXT[b])
    if i in RETAKE or b=='void': status='retake'
    elif b in('lot','field','roof'): status='check'
    else: status='keep'
    if RETAKE.get(i): extra.append(RETAKE[i])
    if feat and b in('lot','field','roof'): extra.append("A feature spread fills a page with this place. Retake somewhere lived-in."); status='retake'
    if feat: extra.insert(0,"Feature spread: text and at most one small picture on one page, one picture filling the other.")
    if npr>4: extra.append("%d pictures now. At the wider crop the spread holds two large and two small: pick."%npr)
    if i in STORY: extra.append("Cast: Angel Cross, Light + Blue (Dark + Blue at night), the Fossoil, West Point.")
    add('chapter',title(d),stage,note,status,sv,caps,extra,None); frames[-1]['lay']=names; frames[-1]['old']=d['n']; frames[-1]['id']=i
    return ink,st,rep
tot=[0,0,0]
t=chap('hero',"Front"); tot=[a+b for a,b in zip(tot,t)]
secs=[('The pitch','Images 1 to 5. The whole argument for a visitor who looks at nothing else: each image a different system, screenshots large, almost no notes.',0,5),('Front matter','',5,8)]
for k,(pt,sub,ids,scene) in enumerate(PARTS,1):
    a=len(frames)
    if scene: add('scene',"Part %d opener"%k,"Scene","Full-bleed movie frame, no book, no notes. "+scene[1]+".",scene[2],svg([(0,120,1920,840,scene[0])],scene[2]=='new',True),files=[scene[0]])
    for i in ids:
        t=chap(i,"Part %d"%k); tot=[x+y for x,y in zip(tot,t)]
    secs.append(("Part %d: %s"%(k,pt),sub,a,len(frames)))
a=len(frames)
add('scene',"Closing scene","Scene","Full-bleed. Angel, Light + Blue, night: Angel meets a group of survivors on a server.","keep",svg([(0,120,1920,840,'cin_ang_close')],False,True),files=['cin_ang_close'])
add('front',"The end","Front","The director's closing picture, placed by hand. Unchanged.","keep",svg([(360,90,1200,900,'69_the_end')],False,True))
secs.append(("The close","",a,len(frames)))
json.dump(dict(frames=[{k:v for k,v in f.items() if k!='svg'} for f in frames],sections=secs),open('storyboard_v1.json','w'),indent=1)
cnt={s:sum(1 for f in frames if f['status']==s) for s in('keep','check','retake','new')}
LAB={'keep':'Re-crop','check':'Re-crop, plain place','retake':'Retake','new':'New shot'}
nfeat=sum(1 for f in frames if f.get('id') in FEATURE)
H=[]
H.append('''<title>ZeD-GUI Gallery Storyboard</title><meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;500;700&family=Fira+Sans+Condensed:wght@400;500;600&display=swap">
<style>
/* layout: a contact sheet. One card per gallery picture, in upload order, grouped by part; each card a scaled sketch of the spread over its shot notes. */
:root{--bg:#f3f1ec;--card:#fbfaf7;--fg:#1f1f24;--dim:#5d5d66;--line:#cfcbc2;--accent:#a8660a;--paper:#e9e4d6;--desk:#3a3530;--print:#2a2a2e;--printfg:#d4d4d8;--new:#1f5fc4;--retake:#b3261e;--check:#8a6a00;--keep:#2f6f3e;--mono:'Fira Mono',ui-monospace,monospace;--sans:'Fira Sans Condensed','Arial Narrow',sans-serif}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#1a1a1e;--card:#222226;--fg:#d4d4d8;--dim:#9a9aa3;--line:#3a3a40;--accent:#d4922a;--paper:#cfc9b8;--desk:#111114;--print:#2a2a2e;--printfg:#d4d4d8;--new:#5aa2ff;--retake:#ff6b6b;--check:#f0b429;--keep:#6fbf7f;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#1a1a1e;--card:#222226;--fg:#d4d4d8;--dim:#9a9aa3;--line:#3a3a40;--accent:#d4922a;--paper:#cfc9b8;--desk:#111114;--print:#2a2a2e;--printfg:#d4d4d8;--new:#5aa2ff;--retake:#ff6b6b;--check:#f0b429;--keep:#6fbf7f;color-scheme:dark}
body{background:var(--bg);color:var(--fg);font-family:var(--sans);font-size:16px;line-height:1.4}
.wrap{max-width:1500px;margin:0 auto;padding-block:28px 60px;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));display:flex;flex-direction:column;gap:26px}
h1{font-family:var(--mono);font-size:22px;font-weight:700;letter-spacing:.04em;text-transform:uppercase;margin:0;color:var(--accent)}
h2{font-family:var(--mono);font-size:15px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;margin:0}
.lead{max-width:68ch;margin:0}.sub{color:var(--dim);margin:2px 0 0;max-width:80ch}
.facts{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:14px 28px;border-top:1px solid var(--line);border-bottom:1px solid var(--line);padding-block:14px}
.facts div{min-width:0}.facts b{font-family:var(--mono);font-size:12px;letter-spacing:.06em;text-transform:uppercase;color:var(--dim);display:block;font-weight:500}
.bar{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.bar button{font:500 13px var(--mono);color:var(--fg);background:var(--card);border:1px solid var(--line);border-radius:4px;padding:5px 12px;cursor:pointer}
.bar button[aria-pressed="true"]{border-color:var(--accent);color:var(--accent)}.bar button:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
section{display:flex;flex-direction:column;gap:12px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}
.f{background:var(--card);border:1px solid var(--line);display:flex;flex-direction:column;min-width:0}
.f svg{display:block;width:100%;height:auto}
.desk{fill:var(--desk)}.page{fill:var(--paper)}.ln{fill:var(--desk);opacity:.22}.spine{stroke:var(--desk);stroke-width:6;opacity:.35}
.print{fill:var(--print)}.pnew{fill:none;stroke:var(--new);stroke-width:8;stroke-dasharray:28 16}
.f svg text{font-family:var(--mono);text-anchor:middle;fill:var(--printfg)}.f svg .pnew+text{fill:var(--new)}
.b{padding:10px 12px 12px;display:flex;flex-direction:column;gap:6px}
.top{display:flex;justify-content:space-between;gap:8px;align-items:baseline;font-family:var(--mono);font-size:12px;color:var(--dim)}
.num{font-weight:700;color:var(--fg);font-variant-numeric:tabular-nums}
.t{font-family:var(--mono);font-weight:700;font-size:15px;margin:0}
.st{font-family:var(--mono);font-size:11px;font-weight:700;letter-spacing:.06em;text-transform:uppercase}
.st.keep{color:var(--keep)}.st.check{color:var(--check)}.st.retake{color:var(--retake)}.st.new{color:var(--new)}
.f p{margin:0}.k{font-family:var(--mono);font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--dim);margin-top:4px}
.f ul,.f ol{margin:0;padding-left:18px}.files{font-family:var(--mono);font-size:11.5px;color:var(--dim);overflow-wrap:anywhere}
</style><div class="wrap">''')
H.append('<header><h1>ZeD-GUI gallery storyboard</h1><p class="lead">%d pictures in upload order, drafted from the research: the first five sell the mod, then the book follows a run from the main menu to the long haul. Each card sketches the proposed spread: wider crops, and a full-page picture on about one spread in five.</p></header>'%len(frames))
H.append('<div class="facts"><div><b>Shots</b>%d re-crop as they are, %d re-crop but sit in a plain test place, %d retakes, %d new</div><div><b>Capture standard</b>4K, UI scale 1.75x, Dark + PZ Teal, list view, font 19px, unless a card says otherwise</div><div><b>Notes today</b>%d ink notes and %d sticky notes across the 63 chapters; %d sticky notes repeat the ink or caption beside them</div><div><b>Crops today</b>191 pictures; the middle one shows 22%% of the screen across, and 173 show under 40%%. One shows the whole screen.</div><div><b>Crop rule</b>A picture shows the window with the game around it and the character in frame: at least 45%% of the screen wide, printed up to 800 px. All 160 captures are full 4K frames, and most already have the game open under the windows, so this is mostly a re-crop. A tight crop is allowed only as a small closer look beside a wide one.</div><div><b>Feature spreads</b>13 of the 63 chapters, about one in five: text and at most one small picture on one page, one picture filling the facing page (half the 4K screen at full height).</div><div><b>Notes rule</b>Caption says what the figure is. Ink points at one detail, four a page at most. Sticky gives one takeaway and never repeats the ink.</div></div>'%(cnt['keep'],cnt['check'],cnt['retake'],cnt['new'],tot[0],tot[1],tot[2]))
H.append('<div class="bar" role="group" aria-label="Filter shots"><button id="f-all" data-f="all" aria-pressed="true">All %d</button>'%len(frames)+''.join('<button id="f-%s" data-f="%s" aria-pressed="false">%s %d</button>'%(s,s,LAB[s],cnt[s]) for s in('new','retake','check','keep'))+'<button id="f-feat" data-f="feat" aria-pressed="false">Feature spreads %d</button>'%nfeat+'</div>')
for name,sub,a,b in secs:
    H.append('<section><div><h2>%s</h2>%s</div><div class="grid">'%(html.escape(name),'<p class="sub">%s</p>'%html.escape(sub) if sub else ''))
    for n in range(a,b):
        f=frames[n]
        H.append('<article class="f" data-s="%s" data-feat="FEAT">%s<div class="b"><div class="top"><span class="num">%02d</span><span>%s%s</span><span class="st %s">%s</span></div><p class="t">%s</p><p>%s</p>'%(f['status'],f['svg'],n+1,html.escape(f['stage']),(' · was ch. %d'%f['old']) if 'old' in f else '',f['status'],LAB[f['status']],html.escape(f['name']),html.escape(f['shot'])))
        H[-1]=H[-1].replace('data-feat="FEAT"','data-feat="%d"'%(1 if f.get('id') in FEATURE else 0))
        if f['caps']: H.append('<div class="k">%s</div><ul>%s</ul>'%('Figures' if f['kind']=='chapter' else 'Caption',''.join('<li>%s</li>'%html.escape(c.replace('*','')) for c in f['caps'])))
        if f['extra']: H.append('<div class="k">Notes</div><ul>%s</ul>'%''.join('<li>%s</li>'%html.escape(c) for c in f['extra']))
        if f['files']: H.append('<p class="files">%s</p>'%html.escape(' · '.join(x.replace('.png','') for x in f['files'])))
        if f.get('lay'): H.append('<div class="k">In the sketch</div><ol class="files">%s</ol>'%''.join('<li>%s</li>'%html.escape(x.replace('.png','')) for x in f['lay']))
        H.append('</div></article>')
    H.append('</div></section>')
H.append('''</div><script>
document.querySelectorAll('.bar button').forEach(function(b){b.addEventListener('click',function(){var v=b.dataset.f;
document.querySelectorAll('.bar button').forEach(function(x){x.setAttribute('aria-pressed',x===b?'true':'false')});
document.querySelectorAll('.f').forEach(function(c){c.hidden=!(v==='all'||c.dataset.s===v||(v==='feat'&&c.dataset.feat==='1'))});
document.querySelectorAll('section').forEach(function(s){s.hidden=!s.querySelector('.f:not([hidden])')})})});
</script>''')
open('storyboard.html','w').write('\n'.join(H))
print(len(frames),cnt,tot,os.path.getsize('storyboard.html'))
