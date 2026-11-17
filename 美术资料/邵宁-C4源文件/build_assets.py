#!/usr/bin/env python3
"""Create native-resolution, layered pixel assets for Shao Ning C4 (game mod, no large-image downscaling)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from collections import Counter,deque
from xml.etree.ElementTree import Element, SubElement, tostring
import json, hashlib, zipfile, shutil, math

ROOT=Path('/mnt/data/shaoning_c4_register_game_v1')
SOURCE=Path('/mnt/data/shaoning_c4_stage1_work/shaoning_idle_front.png')
if not SOURCE.exists(): SOURCE=Path(__file__).resolve().parent/'shaoning_idle_front_reference.png'
if ROOT.exists(): shutil.rmtree(ROOT)
chars=ROOT/'gotdot/actors/shaoning/actions'; props=ROOT/'gotdot/props'; scene=ROOT/'gotdot/actors/shaoning'; source=ROOT/'source'; meta=ROOT/'meta'
for p in (chars, props, source, meta):p.mkdir(parents=True,exist_ok=True)

OUT=(22,20,20,255); INK=(36,33,34,255)
CARD_DARK=(52,43,42,255); CARD_MID=(79,63,62,255); CARD_HI=(102,83,76,255)
PAPER=(239,226,201,255); PAPER_EDGE=(205,189,165,255); PAPER_SHADOW=(221,204,177,255)
MASK=(103,110,110,255); MASK_HI=(117,123,121,255)
WARM=(186,126,75,255); WARM_DARK=(147,95,56,255)
SKIN=(243,212,191,255); SKIN_SH=(181,159,145,255)
CLOTH=(113,121,114,255); CL_MID=(94,105,100,255); CL_DARK=(74,82,79,255); CL_HI=(104,115,109,255)
FONTPATH='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'

# One-bit anti-alias-free Chinese text; no font file is distributed.
def textpix(im,xy,s,size=17,fill=INK,maxlen=None):
    if maxlen is None:maxlen=im.width-xy[0]
    mask=Image.new('L',(maxlen,size+8),0)
    ImageDraw.Draw(mask).text((0,-2),s,font=ImageFont.truetype(FONTPATH,size),fill=255)
    mask=mask.point(lambda a:255 if a>105 else 0)
    color=Image.new('RGBA',mask.size,fill)
    im.paste(color,xy,mask)

def png(im,loc):
    loc.parent.mkdir(parents=True,exist_ok=True)
    im.save(loc,optimize=True)

def pixpoly(draw,points,fill,outline=OUT,width=1):
    draw.polygon(points,fill=fill)
    if outline:draw.line(points+[points[0]],fill=outline,width=width,joint='curve')

# ---- Actor action (72x108) ----
base=Image.open(SOURCE).convert('RGBA')
assert base.size==(72,108)
orig=base.copy()
# Remove only hanging forearms, keeping the torso, shirt, head, trousers and shoes pixel-identical.
a=base.load()
for y in range(42,68):
    for x in range(21,52):
        erase=(x<=27 and y>=45) or (x<=29 and y>=51 and x>=23) or (x>=46 and y>=44) or (x>=44 and y>=53)
        # Rebuild only side-of-body arms. Preserve interior cardigan and pockets.
        if erase:
            a[x,y]=(0,0,0,0)
# Reinstate intended torso edge seams as needed (wiping forearms could affect last hem pixels)
d=ImageDraw.Draw(base)
d.line([(28,51),(28,58)],fill=CL_DARK,width=1)
d.line([(44,53),(44,58)],fill=CL_DARK,width=1)

sleeves=Image.new('RGBA',(72,108),(0,0,0,0));D=ImageDraw.Draw(sleeves)
# viewer-left arm from shoulder to a gently bent pinch above the folder
pixpoly(D,[(24,40),(27,38),(30,41),(31,45),(34,46),(36,46),(38,48),(36,52),(32,52),(27,50),(23,47)],CLOTH)
D.line([(26,41),(26,46),(29,49),(34,49)],fill=CL_DARK,width=1)
D.line([(27,39),(29,41),(30,46)],fill=CL_HI,width=1)
D.line([(33,51),(36,50)],fill=CL_DARK,width=1)
# viewer-right shoulder bends under and around folder, bottom hand supports folder
pixpoly(D,[(45,39),(48,40),(49,46),(49,51),(52,55),(52,58),(48,59),(45,54),(44,47)],CL_MID)
D.line([(47,42),(47,50),(50,55)],fill=CL_DARK,width=1)
D.line([(46,44),(46,48)],fill=CL_HI,width=1)

folder=Image.new('RGBA',(72,108),(0,0,0,0));F=ImageDraw.Draw(folder)
# scaled world representation: brown front folio, exposed top corner of Thu visitor sheet
pixpoly(F,[(37,43),(56,43),(58,46),(58,62),(39,62),(37,60)],CARD_DARK)
F.line([(39,60),(56,60)],fill=CARD_HI,width=1)
F.line([(39,43),(55,43)],fill=CARD_HI,width=1)
pixpoly(F,[(39,44),(54,44),(56,46),(56,54),(42,54),(39,57)],PAPER,outline=INK)
F.line([(42,51),(50,51)],fill=PAPER_EDGE,width=1)
F.line([(42,53),(48,53)],fill=PAPER_SHADOW,width=1)
# fold on upper-right corner of paper
F.polygon([(52,44),(56,48),(52,48)],fill=PAPER_SHADOW)
F.line([(52,44),(52,48),(56,48)],fill=INK,width=1)
# same clue, very simple 1x crescent ring fragment
F.point((50,46),fill=WARM);F.point((49,47),fill=WARM);F.point((50,48),fill=WARM_DARK);F.point((51,48),fill=WARM)

hands=Image.new('RGBA',(72,108),(0,0,0,0));H=ImageDraw.Draw(hands)
# top pinch: thumb/forefinger visually cross folder's exposed upper-left edge
pixpoly(H,[(35,46),(37,46),(39,45),(41,46),(41,48),(39,49),(37,48),(36,50),(34,49)],SKIN)
H.point((40,47),fill=SKIN_SH)
H.line([(35,49),(36,50)],fill=SKIN_SH,width=1)
# lower right palm visibly supports the bottom folder edge; no floating prop
pixpoly(H,[(49,60),(51,59),(53,59),(55,61),(55,63),(53,64),(50,64),(48,62)],SKIN)
H.line([(51,62),(53,62)],fill=SKIN_SH,width=1)

actor=Image.alpha_composite(Image.alpha_composite(Image.alpha_composite(base,sleeves),folder),hands)
png(actor,chars/'shaoning_show_page_front.png')
# keep all component layers for editable ORA
png(base,source/'actor_base_arm_removed.png')
png(sleeves,source/'actor_bent_sleeves.png')
png(folder,source/'actor_folder_mini.png')
png(hands,source/'actor_gripping_hands.png')

# Independent miniature folder in game space (not double-layer over action frame)
world=Image.new('RGBA',(30,36),(0,0,0,0));w=ImageDraw.Draw(world)
pixpoly(w,[(3,2),(26,2),(28,4),(28,32),(26,34),(3,34),(1,32),(1,4)],CARD_DARK)
w.line([(3,3),(26,3)],fill=CARD_HI)
for y,label in [(4,'upper'),(21,'lower')]:
    w.rectangle((5,y,24,y+11),fill=PAPER,outline=PAPER_EDGE,width=1)
    w.line((8,y+5,19,y+5),fill=(140,135,128,255),width=1)
    w.line((8,y+8,15,y+8),fill=(140,135,128,255),width=1)
for x in (9,20):
    w.rectangle((x-1,16,x+1,20),fill=(80,85,88,255),outline=INK)
    w.point((x,17),fill=PAPER)
png(world,props/'visitor_register_folder_world.png')

# Evidence detail: Wed upper, missing center page, 2 empty clips, Fri lower.
fol=Image.new('RGBA',(240,280),(0,0,0,0));d=ImageDraw.Draw(fol)
pixpoly(d,[(16,6),(223,6),(231,14),(231,265),(222,273),(16,273),(8,265),(8,14)],CARD_DARK,width=3)
d.rectangle((15,12,224,265),outline=CARD_HI,width=2)
for ypos in (23,163):
    d.rectangle((26,ypos,216,ypos+94),fill=PAPER,outline=INK,width=2)
    d.line([(29,ypos+3),(212,ypos+3)],fill=PAPER_EDGE,width=2)
    d.polygon([(208,ypos),(216,ypos+8),(208,ypos+8)],fill=PAPER_SHADOW)
    d.line([(208,ypos),(208,ypos+8),(216,ypos+8)],fill=CARD_MID,width=1)
for x in (69,169):
    # empty metal clips; never obscure Wed/Fri date
    d.rectangle((x-11,130,x+11,151),fill=(100,101,101,255),outline=INK,width=2)
    d.rectangle((x-7,134,x+7,145),fill=CARD_DARK,outline=(197,199,194,255),width=2)
    d.rectangle((x-3,147,x+3,152),fill=(68,69,69,255))
for ypos,day in ((23,'周三'),(163,'周五')):
    d.rectangle((38,ypos+9,87,ypos+33),fill=(83,86,91,255))
    textpix(fol,(44,ypos+11),day,size=18,fill=(241,236,220,255),maxlen=48)
    d.line([(104,ypos+22),(190,ypos+22)],fill=(149,153,152,255),width=3)
    for yy in (ypos+45,ypos+62,ypos+79):
        d.line([(43,yy),(199,yy)],fill=(145,149,149,255),width=2)
        for xx in (43,84,151,198):
            d.line([(xx,yy-8),(xx,yy+5)],fill=(155,157,157,255),width=1)
png(fol,props/'visitor_register_folder_detail.png')

# Canonical coffee ring fragment: stamp this SAME mask into Thursday page, shared future photo UI.
stain=Image.new('RGBA',(26,24),(0,0,0,0));q=ImageDraw.Draw(stain)
q.arc((3,3,21,21),16,247,fill=WARM,width=3)
q.arc((5,5,20,20),25,185,fill=(205,156,109,255),width=1)
q.point((11,23),fill=(216,171,119,255));q.point((20,14),fill=WARM_DARK)
png(stain,source/'canonical_thursday_coffee_stain.png')

# Three standalone candidate sheets, date and corner visible; all other content deliberately masked.
for day in ['wednesday','thursday','friday']:
    page=Image.new('RGBA',(144,168),(0,0,0,0));p=ImageDraw.Draw(page)
    pixpoly(p,[(10,6),(118,6),(133,21),(133,154),(120,162),(10,162),(4,156),(4,12)],PAPER,outline=INK,width=2)
    p.line([(8,10),(112,10)],fill=PAPER_EDGE,width=2)
    p.polygon([(118,6),(118,21),(133,21)],fill=PAPER_SHADOW)
    p.line([(118,6),(118,21),(133,21)],fill=CARD_MID,width=1)
    cn={'wednesday':'周三','thursday':'周四','friday':'周五'}[day]
    p.rectangle((16,18,71,46),fill=(81,85,89,255))
    textpix(page,(22,21),cn,size=20,fill=(242,239,225,255),maxlen=47)
    if day=='thursday':
        page.alpha_composite(stain,(103,20))
    # intentionally cover private content, leaving page date and clue-bearing corner only
    p.rectangle((16,54,121,149),fill=(119,126,128,255))
    p.rectangle((21,59,116,144),outline=(147,153,155,255),width=2)
    p.line([(32,81),(103,81)],fill=(150,157,157,255),width=3)
    p.line([(32,102),(89,102)],fill=(150,157,157,255),width=3)
    p.line([(32,123),(100,123)],fill=(150,157,157,255),width=3)
    png(page,props/f'visitor_page_{day}.png')

# Backside rule. Exact wording from story, no invented dates or personal details.
rule=Image.new('RGBA',(328,184),(0,0,0,0));r=ImageDraw.Draw(rule)
pixpoly(r,[(12,5),(314,5),(321,12),(321,169),(313,177),(12,177),(5,170),(5,13)],PAPER,outline=INK,width=3)
r.rectangle((13,13,313,167),outline=PAPER_EDGE,width=2)
r.rectangle((24,23,304,54),fill=(79,82,84,255))
textpix(rule,(94,24),'原页收存规则',size=22,fill=(241,237,223,255),maxlen=185)
lines=['含联系方式的原页用完','请收入前台内袋，','日常查阅只看来访日期与事项']
for i,s in enumerate(lines):textpix(rule,(26,65+i*30),s,size=18,fill=INK,maxlen=293)
r.line([(26,157),(302,157)],fill=PAPER_EDGE,width=2)
png(rule,props/'visitor_register_storage_rule.png')

# In-game character scene. Does not overwrite front_desk.tscn or existing idle scenes.
tscn='''[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://actors/shaoning/actions/shaoning_show_page_front.png" id="1_action"]\n\n[node name="ShaoNingShowPage" type="Node2D"]\n\n[node name="Sprite" type="Sprite2D" parent="."]\ntexture_filter = 1\nposition = Vector2(-36, -104)\ncentered = false\ntexture = ExtResource("1_action")\n'''
(scene/'shaoning_show_page_pose.tscn').write_text(tscn,encoding='utf-8')

# OpenRaster sources for editing layered figure.
def make_ora(path,layers):
    xml=Element('image',{'w':'72','h':'108','name':'shaoning_show_page_front','version':'0.0.1'})
    stack=SubElement(xml,'stack')
    files=[]
    for idx,(name,im) in enumerate(reversed(layers)):
        p=f'data/layer{idx}.png'
        SubElement(stack,'layer',{'name':name,'src':p,'visibility':'visible','composite-op':'svg:src-over','opacity':'1.0','x':'0','y':'0'})
        import io
        b=io.BytesIO(); im.save(b,format='PNG');files.append((p,b.getvalue()))
    with zipfile.ZipFile(path,'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        z.writestr('stack.xml',tostring(xml,encoding='utf-8'))
        import io
        b=io.BytesIO();actor.save(b,format='PNG');merged=b.getvalue();z.writestr('mergedimage.png',merged)
        for p,layerbytes in files:z.writestr(p,layerbytes)
        z.writestr('Thumbnails/thumbnail.png',merged)
make_ora(source/'shaoning_show_page_editable.ora', [('Base body with old arms removed',base),('Bent sleeves',sleeves),('Clipped folder and Thu corner',folder),('Hands over folder',hands)])

meta_obj={
 'project':'被引向的真相','batch':'C4 邵宁展示登记页纸角 + D2 登记夹线索','version':'1.0',
 'character':{'size':[72,108],'anchor_image_px':[36,104],'height_px':98,'actor_png_contains_small_page_and_folder':True,
 'draw_order':['base','new sleeves','mini folder','hands'],'no_double_layer_rule':'Do not overlay visitor_register_folder_world.png on the actor pose'},
 'world_folder':{'size':[30,36]},
 'evidence':{'detail_size':[240,280],'candidate_page_size':[144,168], 'storage_rule_size':[328,184],
 'weekday_labels':['周三','周四','周五'], 'coffee_stain_only':'visitor_page_thursday.png',
 'coffee_stain_origin_in_thursday_page':[103,20], 'coffee_stain_source':'source/canonical_thursday_coffee_stain.png',
 'info_policy':'Candidates display only weekday/date corner. All other contents are covered; no visitor PII'},
 'story_rule_exact':'含联系方式的原页用完请收入前台内袋，日常查阅只看来访日期与事项',
 'status':'Static PNGs and Godot resource-path checks done; runtime not tested; GitHub not modified'
}
(meta/'alignment_and_story.json').write_text(json.dumps(meta_obj,ensure_ascii=False,indent=2),encoding='utf-8')

# QA: actual sizes and binary alpha; sprite feet, head identity, trousers identity; text/asset filenames.
files=sorted(ROOT.rglob('*.png'))
checks={}
for f in files:
    im=Image.open(f).convert('RGBA')
    alphas=set(a for *_,a in im.getdata())
    assert alphas.issubset({0,255}),f'non-binary-alpha: {f} {sorted(alphas)[:6]}'
    isopaque=[(x,y) for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))[3]]
    bbox=(min(x for x,y in isopaque), min(y for x,y in isopaque), max(x for x,y in isopaque), max(y for x,y in isopaque))
    checks[str(f.relative_to(ROOT))]={'size':[im.width,im.height],'rgba_binary_alpha':True,'opaque_bbox':bbox,'opaque_colors':len(set(im.getdata()))-1,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
assert Image.open(chars/'shaoning_show_page_front.png').size==(72,108)
assert max(y for y in range(108) if any(actor.getpixel((x,y))[3] for x in range(72)))==104
assert all(actor.getpixel((x,y))==orig.getpixel((x,y)) for y in list(range(0,35))+list(range(72,108)) for x in range(72))
(meta/'qa_report.json').write_text(json.dumps({'summary':{'file_count':len(files),'sprite_alpha_binary':True,'feet_baseline_y':104,'orig_head_and_lower_legs_byte_identical':True,'runtime_tested':False,'zip_verified':True},'assets':checks},ensure_ascii=False,indent=2),encoding='utf-8')

readme='''# 邵宁 C4 展示登记页纸角 · Godot 像素素材 v1

项目：《被引向的真相》，第二章《少掉的一页》。这批是**实际游戏尺寸的透明像素 PNG**，不是高清概念图压缩。GitHub 原仓库尚未修改。

## 直接使用
将 `gotdot/` 下的文件合并至 Godot 工程的 `gotdot/` 同名目录（使场景内路径以 `res://actors/…` 和 `res://props/…` 开头）。

- `actors/shaoning/actions/shaoning_show_page_front.png`：**72×108**，脚底 `(36,104)`，人物和小夹本体已经画在同一动作帧上。动作时切换 Sprite 贴图；完毕切回 `idle/shaoning_idle_front.png`。**不要**将下列独立登记夹再次叠加到她手上。
- `actors/shaoning/shaoning_show_page_pose.tscn`：可单独实例化的 Godot 4 静态场景，已设置 `texture_filter=1`（Nearest），Sprite 偏移 `(-36,-104)` 让节点原点位于脚底。注意：这个独立场景不会自动替换 `front_desk.tscn` 现有 NPC，也不包含剧情交互。
- `props/visitor_register_folder_world.png`：30×36 独立登记夹小道具，适合柜台摆放，**不用于动作帧叠加**。
- `props/visitor_register_folder_detail.png`：240×280 证物放大图，**上页周三，下页周五，中间两只空夹扣**。
- `props/visitor_page_{wednesday,thursday,friday}.png`：144×168 候选原页，其他个人信息全部遮盖，露出日期和纸角。只有周四页带月牙形咖啡渍。
- `props/visitor_register_storage_rule.png`：328×184，登记夹背面收存规则的可读放大图。文字已直接烘焙至 PNG；也可在 Godot UI 中从 JSON 文字重新排版。

## 证据一致性（重要）
- 周四候选页的污渍从 `source/canonical_thursday_coffee_stain.png` 盖入，坐标 `(103,20)`；将来制作群聊原图／局部裁剪图时，请重用这一张污渍源图，**不要另画形状**。
- 未提供剧情里不存在的具体年份和月份，也没有绘制访客联系方式。
- 背面收存规则原文：**含联系方式的原页用完请收入前台内袋，日常查阅只看来访日期与事项**。

## 质量与来源
- 角色头部（y=0–34）和裤腿鞋子（y=72–107）逐像素保留邵宁已定版母版；修改上半身手臂及展示动作。
- 角色仍为 72×108，脚底 y=104；所有 PNG 为 RGBA 真透明、仅 0/255 alpha、硬边；近邻缩放，Godot `scale=1`。
- `source/shaoning_show_page_editable.ora` 为分层可编辑图；另附四张动作分层 PNG、可复用的污渍源图和 `meta/alignment_and_story.json`、QA 报告。
- 美术来源：以仓库邵宁 C4 站姿定版帧为母版，程序辅助逐像素编辑和重绘道具；AI 辅助参考概念图，但正式素材非概念图直接缩小。授权记录需按项目 AI 辅助素材登记。

**验收边界**：静态文件尺寸、alpha、脚底、场景贴图路径与 ZIP 已检查；没有实际启动 Godot / 在安卓设备上验证遮挡或点击区域，不能视为实机验收。
'''
(ROOT/'README_接入说明.md').write_text(readme,encoding='utf-8')

# External QA previews, deliberately kept OUTSIDE the delivery zip.
review=Path('/mnt/data/shaoning_c4_register_review')
review.mkdir(exist_ok=True)
# 6x four pose types, with nearest interpolation
from PIL import ImageOps
preview=Image.new('RGB',(2*72*6+60,108*6+88),(35,35,38))
for idx,img in enumerate((orig,actor)):
    x=20+idx*(72*6+20)
    preview.paste(Image.new('RGB',(72*6,108*6),(72,72,75)),(x,35))
    enlarged=img.resize((72*6,108*6),Image.Resampling.NEAREST)
    preview.paste(enlarged,(x,35),enlarged)
png(preview,review/'pose_before_after_6x.png')
# evidence montage, leave background separate
small_names=['visitor_register_folder_detail.png','visitor_page_wednesday.png','visitor_page_thursday.png','visitor_page_friday.png','visitor_register_storage_rule.png']
mont=Image.new('RGB',(760,690),(38,40,43))
for i,name in enumerate(small_names):
    im=Image.open(props/name).convert('RGBA')
    if i==0:pos=(26,27)
    elif i in (1,2,3):pos=(295+(i-1)*150,35)
    else:pos=(330,278)
    mont.paste(im,pos,im)
png(mont,review/'props_overview.png')
# copy build script source to package for truly editable procedural assets
shutil.copyfile(__file__,source/'build_assets.py')
# deterministic zip, only game files, code/source, qa/meta; no preview
zip_path=Path('/mnt/data/shaoning_c4_show_register_game_ready_v1.zip')
with zipfile.ZipFile(zip_path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for f in sorted(ROOT.rglob('*')):
        if f.is_file():z.write(f,str(f.relative_to(ROOT)))
with zipfile.ZipFile(zip_path) as z:
    assert z.testzip() is None
    assert any(n=='gotdot/actors/shaoning/actions/shaoning_show_page_front.png' for n in z.namelist())
    assert all(not n.endswith('preview.png') for n in z.namelist())
print(json.dumps({'zip':str(zip_path),'size':zip_path.stat().st_size,'file_count':len(list(ROOT.rglob('*'))),'png_count':len(files),'actor_size':actor.size,'actor_alpha':sorted(set(a for *_,a in actor.getdata())),'actor_feet':104,'actor_bbox':actor.getbbox()},ensure_ascii=False,indent=2))
