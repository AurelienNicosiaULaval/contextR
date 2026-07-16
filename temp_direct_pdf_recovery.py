#!/usr/bin/env python3
from __future__ import annotations
import concurrent.futures as cf
import csv, hashlib, io, json, subprocess, sys, tempfile
from pathlib import Path
from urllib.parse import urlparse
import requests
from pypdf import PdfReader

OUT=Path('notes_master_math_france_direct'); OUT.mkdir(parents=True,exist_ok=True)
RECORDS=[
{'num':1,'title':'Cours de probabilités','path':'01 - Proba-stat/01.1 Probabilites M1/01 - Cours de probabilites - Yves Coudene (2015).pdf','urls':['https://perso.lpsm.paris/~coudene/probabilites.pdf','http://perso.lpsm.paris/~coudene/probabilites.pdf','https://www.lpsm.paris/~coudene/probabilites.pdf','http://www.proba.jussieu.fr/pageperso/coudene/probabilites.pdf']},
{'num':5,'title':'Probabilités approfondies : martingales et chaînes de Markov','path':'01 - Proba-stat/01.2 Processus, Markov et martingales/05 - Probabilites approfondies martingales et chaines de Markov - Thomas Duquesne (2012).pdf','urls':['https://perso.lpsm.paris/~broutinn/teaching/4M011_poly_duquesne.pdf','http://perso.lpsm.paris/~broutinn/teaching/4M011_poly_duquesne.pdf','https://www.lpsm.paris/~broutinn/teaching/4M011_poly_duquesne.pdf']},
{'num':11,'title':'Statistique, Partie 2 : approche bayésienne','path':'01 - Proba-stat/01.5 Bayesien et MCMC/11 - Statistique, Partie 2 approche bayesienne - Anna Ben-Hamou; Arnaud Guyader.pdf','urls':['https://perso.lpsm.paris/~aguyader/files/teaching/M1/PolycopiePartie2.pdf','http://perso.lpsm.paris/~aguyader/files/teaching/M1/PolycopiePartie2.pdf','https://www.lpsm.paris/~aguyader/files/teaching/M1/PolycopiePartie2.pdf']},
{'num':15,'title':'Calcul stochastique et processus de diffusion','path':'01 - Proba-stat/01.3 Calcul stochastique et diffusions/15 - Calcul stochastique et processus de diffusion - Nicolas Fournier.pdf','urls':['https://perso.lpsm.paris/~nfournier/PolyCS.pdf','http://perso.lpsm.paris/~nfournier/PolyCS.pdf','https://www.lpsm.paris/~nfournier/PolyCS.pdf','http://www.proba.jussieu.fr/pageperso/fournier/PolyCS.pdf']},
{'num':19,'title':'Modélisation et statistique bayésienne computationnelle','path':'01 - Proba-stat/01.5 Bayesien et MCMC/19 - Modelisation et statistique bayesienne computationnelle - Nicolas Bousquet (2026).pdf','urls':['https://perso.lpsm.paris/~bousquet/poly-complet-2026-V1.pdf','http://perso.lpsm.paris/~bousquet/poly-complet-2026-V1.pdf','https://www.lpsm.paris/~bousquet/poly-complet-2026-V1.pdf']},
{'num':25,'title':'Méthodes de tenseurs pour les problèmes en grande dimension','path':'03 - EDP et calcul scientifique/25 - Methodes de tenseurs pour les problemes en grande dimension (2024).pdf','urls':['https://www.ljll.fr/MathModel/enseignement/cours/TenseursM2_2024.pdf','http://www.ljll.fr/MathModel/enseignement/cours/TenseursM2_2024.pdf','https://www.ljll.math.upmc.fr/MathModel/enseignement/cours/TenseursM2_2024.pdf','http://www.ljll.math.upmc.fr/MathModel/enseignement/cours/TenseursM2_2024.pdf']},
{'num':33,'title':'Contrôle optimal : théorie et applications','path':'02 - Analyse, optimisation et outils/Optimisation et controle/33 - Controle optimal theorie et applications - Emmanuel Trelat.pdf','urls':['https://www.ljll.fr/~trelat/fichiers/livreopt.pdf','http://www.ljll.fr/~trelat/fichiers/livreopt.pdf','https://www.ljll.math.upmc.fr/~trelat/fichiers/livreopt.pdf','http://www.ljll.math.upmc.fr/~trelat/fichiers/livreopt.pdf','https://www.ljll.math.upmc.fr/trelat/fichiers/livreopt.pdf']},
{'num':34,'title':'Méthodes mathématiques et numériques pour les plasmas','path':'03 - EDP et calcul scientifique/34 - Methodes mathematiques et numeriques pour les plasmas - Bruno Despres (2021).pdf','urls':['https://www.ljll.fr/despres/BD_fichiers/m2_plasma.pdf','http://www.ljll.fr/despres/BD_fichiers/m2_plasma.pdf','https://www.ljll.math.upmc.fr/despres/BD_fichiers/m2_plasma.pdf','http://www.ljll.math.upmc.fr/despres/BD_fichiers/m2_plasma.pdf']},
{'num':35,'title':'Équations aux dérivées partielles elliptiques','path':'03 - EDP et calcul scientifique/35 - Equations aux derivees partielles elliptiques - Herve Le Dret (2010).pdf','urls':['https://www.ljll.fr/ledret/M2Elliptique/chapitre4.pdf','http://www.ljll.fr/ledret/M2Elliptique/chapitre4.pdf','https://www.ljll.math.upmc.fr/ledret/M2Elliptique/chapitre4.pdf','http://www.ljll.math.upmc.fr/ledret/M2Elliptique/chapitre4.pdf']},
]
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/126 Safari/537.36'

def validate(data:bytes):
 p=data.find(b'%PDF-')
 if p<0 or p>4096: raise ValueError(f'non PDF {data[:30]!r}')
 data=data[p:]
 n=len(PdfReader(io.BytesIO(data),strict=False).pages)
 if n<1: raise ValueError('aucune page')
 return data,n

def curl(url,mode):
 with tempfile.NamedTemporaryFile(suffix='.pdf',delete=False) as f: tmp=Path(f.name)
 cmd=['curl','-L','--fail','--retry','3','--retry-all-errors','--connect-timeout','15','--max-time','150','-A',UA,'-H','Accept: application/pdf,*/*;q=0.8','-o',str(tmp)]
 if mode=='ipv4': cmd += ['-4','--http1.1']
 elif mode=='doh': cmd += ['-4','--http1.1','--doh-url','https://cloudflare-dns.com/dns-query']
 elif mode=='ipv6': cmd += ['-6','--http1.1']
 cmd.append(url)
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
 try:
  if p.returncode!=0: raise RuntimeError((p.stderr or p.stdout)[-1200:])
  data=tmp.read_bytes(); data,n=validate(data); return data,n,url,f'curl-{mode}'
 finally: tmp.unlink(missing_ok=True)

def wget(url):
 with tempfile.NamedTemporaryFile(suffix='.pdf',delete=False) as f: tmp=Path(f.name)
 cmd=['wget','-4','--max-redirect=20','--timeout=30','--tries=3','--user-agent='+UA,'-O',str(tmp),url]
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
 try:
  if p.returncode!=0: raise RuntimeError((p.stderr or p.stdout)[-1200:])
  data=tmp.read_bytes(); data,n=validate(data); return data,n,url,'wget-ipv4'
 finally: tmp.unlink(missing_ok=True)

def resolved_ips(host):
 out=[]
 for endpoint in ['https://dns.google/resolve','https://cloudflare-dns.com/dns-query']:
  try:
   headers={'accept':'application/dns-json'}
   r=requests.get(endpoint,params={'name':host,'type':'A'},headers=headers,timeout=20)
   for a in r.json().get('Answer',[]):
    if a.get('type')==1 and a.get('data') not in out: out.append(a['data'])
  except Exception: pass
 return out

def curl_resolve(url,ip):
 u=urlparse(url); port='443' if u.scheme=='https' else '80'
 with tempfile.NamedTemporaryFile(suffix='.pdf',delete=False) as f: tmp=Path(f.name)
 cmd=['curl','-L','--fail','-4','--http1.1','--connect-timeout','15','--max-time','150','--resolve',f'{u.hostname}:{port}:{ip}','-A',UA,'-o',str(tmp),url]
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
 try:
  if p.returncode!=0: raise RuntimeError((p.stderr or p.stdout)[-1200:])
  data=tmp.read_bytes(); data,n=validate(data); return data,n,url,f'curl-resolve-{ip}'
 finally: tmp.unlink(missing_ok=True)

def recover(rec):
 errors=[]
 for url in rec['urls']:
  for mode in ['ipv4','doh','default','ipv6']:
   try:
    data,n,src,kind=curl(url,mode); return {**rec,'status':'ok','data':data,'pages':n,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'source_url':src,'source_kind':kind,'detail':''}
   except Exception as e: errors.append(f'{kind if "kind" in locals() else mode} {url}: {type(e).__name__}: {e}')
  try:
   data,n,src,kind=wget(url); return {**rec,'status':'ok','data':data,'pages':n,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'source_url':src,'source_kind':kind,'detail':''}
  except Exception as e: errors.append(f'wget {url}: {type(e).__name__}: {e}')
  host=urlparse(url).hostname
  for ip in resolved_ips(host):
   try:
    data,n,src,kind=curl_resolve(url,ip); return {**rec,'status':'ok','data':data,'pages':n,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'source_url':src,'source_kind':kind,'detail':''}
   except Exception as e: errors.append(f'resolve {host}={ip}: {type(e).__name__}: {e}')
 return {**rec,'status':'error','data':b'','pages':0,'bytes':0,'sha256':'','source_url':'','source_kind':'','detail':' | '.join(errors)[-16000:]}

results=[]
with cf.ThreadPoolExecutor(max_workers=7) as ex:
 fs={ex.submit(recover,r):r for r in RECORDS}
 for f in cf.as_completed(fs):
  rec=fs[f]
  try:x=f.result()
  except BaseException:
   import traceback
   x={**rec,'status':'error','data':b'','pages':0,'bytes':0,'sha256':'','source_url':'','source_kind':'','detail':'UNHANDLED '+traceback.format_exc()}
  if x['status']=='ok':
   d=OUT/x['path'];d.parent.mkdir(parents=True,exist_ok=True);d.write_bytes(x.pop('data'))
  else:x.pop('data',None)
  results.append(x);print(f"[{x['num']:02d}] {x['status']} pages={x['pages']} bytes={x['bytes']} kind={x['source_kind']} {x['title']}",flush=True)
results.sort(key=lambda x:x['num'])
fields=['num','title','path','urls','status','source_url','source_kind','pages','bytes','sha256','detail']
rows=[]
for x in results:
 y=dict(x);y['urls']=' | '.join(y['urls']);rows.append(y)
with (OUT/'manifest.csv').open('w',encoding='utf-8',newline='') as f:
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
(OUT/'manifest.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
err=[x for x in results if x['status']!='ok'];print(f'SUCCES={len(results)-len(err)} ECHECS={len(err)}',flush=True)
sys.exit(1 if err else 0)
