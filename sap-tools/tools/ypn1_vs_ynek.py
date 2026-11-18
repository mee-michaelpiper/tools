import subprocess,os,sys
S=sys.argv[1]
rows=[l.split('|') for l in open(f'{S}/ypn1.txt')]
rows=[[c.strip() for c in r] for r in rows]
env=dict(os.environ,SAPSYS='MEP')
def q(table,where,fields):
    out=subprocess.run(['dotnet','run','--no-build','--','table',table,where,*fields],capture_output=True,text=True,env=env).stdout
    return [[c.strip() for c in l.split('|')] for l in out.splitlines() if '|' in l]
def chunks(l,n=8):
    for i in range(0,len(l),n): yield l[i:i+n]
knumh={r[1]:r[0] for r in rows}
ypn={}
for c in chunks(list(knumh)):
    for k in q('KONP',' OR '.join(f"KNUMH = '{x}'" for x in c),['KNUMH','KBETR','KPEIN','KMEIN']):
        ypn[knumh[k[0]]]=(float(k[1]),k[2],k[3])
mats=[r[0] for r in rows]
ynek={}
for c in chunks(mats):
    a=q('A662',"KSCHL = 'YNEK' AND DATAB <= '20261111' AND DATBI >= '20261111' AND ( "+' OR '.join(f"MATNR = '{x}'" for x in c)+" )",['MATNR','KNUMH'])
    kk={x[1]:x[0] for x in a}
    if kk:
        for k in q('KONP',' OR '.join(f"KNUMH = '{x}'" for x in kk),['KNUMH','KBETR','KPEIN']):
            ynek[kk[k[0]]]=(float(k[1]),k[2])
names={}
for c in chunks(mats):
    for m in q('MAKT',"SPRAS = 'D' AND ( "+' OR '.join(f"MATNR = '{x}'" for x in c)+" )",['MATNR','MAKTX']): names[m[0]]=m[1]
with open(f'{S}/ypn1_vs_ynek.csv','w') as f:
    f.write('Material;Text;YPN1;PE;ME;YNEK;PE_YNEK;Diff%\n')
    for m in mats:
        p=ypn.get(m); y=ynek.get(m)
        d='' if not(p and y and y[0]) else f"{(p[0]/float(p[1]) - y[0]/float(y[1]))/(y[0]/float(y[1]))*100:.1f}"
        f.write(f"{m.lstrip('0')};{names.get(m,'')};{p[0] if p else ''};{p[1] if p else ''};{p[2] if p else ''};{y[0] if y else ''};{y[1] if y else ''};{d}\n")
print(len(ypn),len(ynek))
