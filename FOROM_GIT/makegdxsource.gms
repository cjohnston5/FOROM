sets p price     /p1*p2/
     a products of group A /a1*a2/
     b products of group B /b1*b2/;
Parameters parA(a,p), parB(b,p);
parA(a,p)=1*ord(p);
parB('b1',p)=2*ord(p);
parB('b2',p)=3*ord(p);
execute_unload 'parA.gdx' parA=mpar;
execute_unload 'parB.gdx' parB=mpar;
