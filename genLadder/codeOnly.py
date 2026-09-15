import sys,re
s=open(sys.argv[1],encoding='utf-8',errors='replace').read()
out=[];i=0;n=len(s)
while i<n:
    c=s[i]
    if c=='"' or c=="'":
        q=c; out.append(c); i+=1
        while i<n:
            if s[i]=='\\': out.append(s[i:i+2]); i+=2; continue
            out.append(s[i])
            if s[i]==q: i+=1; break
            i+=1
        continue
    if c=='/' and i+1<n and s[i+1]=='*':
        j=s.find('*/',i+2); i=(j+2) if j>=0 else n; continue
    if c=='/' and i+1<n and s[i+1]=='/':
        j=s.find('\n',i); i=j if j>=0 else n; continue
    out.append(c); i+=1
t=''.join(out)
t='\n'.join(l.rstrip() for l in t.split('\n'))
t=re.sub(r'\n{2,}','\n',t)
sys.stdout.write(t)
