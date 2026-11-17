declare ptr @testOP(ptr)
declare ptr @irAt(ptr, i32)
declare i32 @irGoOn()
declare ptr @irSeqEnd(ptr, ptr)
@kw_wqW_n = global i32 0
declare i32 @irCountOf(ptr)
declare double @irNumberOf(ptr)
declare ptr @irSetCount(ptr, i32)
declare ptr @irSetNumber(ptr, double)
@kw_wqW_t = global i32 0
define ptr @kw_wqW(ptr %a) {
entry:
  %last = alloca ptr
  store ptr null, ptr %last
  %items = call ptr @irAt(ptr %a, i32 2)
  %t1 = call ptr @irAt(ptr %items, i32 1)
  %t1_2 = call ptr @irAt(ptr %t1, i32 2)
  %t1_3 = call ptr @irAt(ptr %t1, i32 3)
  %Fi = bitcast ptr %t1_2 to ptr
  %vt1_3 = call i32 @irCountOf(ptr %t1_3)
  %t2 = call ptr @irAt(ptr %items, i32 2)
  %t2_2 = call ptr @irAt(ptr %t2, i32 2)
  %t2_3 = call ptr @irAt(ptr %t2, i32 3)
  %Fs = bitcast ptr %t2_2 to ptr
  %vt2_3 = call i32 @irCountOf(ptr %t2_3)
  %t3 = call ptr @irAt(ptr %items, i32 3)
  %t3_2 = call ptr @irAt(ptr %t3, i32 2)
  %t3_2_1 = call ptr @irAt(ptr %t3_2, i32 1)
  %t3_2_1_2 = call ptr @irAt(ptr %t3_2_1, i32 2)
  %t3_2_1_3 = call ptr @irAt(ptr %t3_2_1, i32 3)
  %vt3_2_1_3 = call i32 @irCountOf(ptr %t3_2_1_3)
  %t3_2_2 = call ptr @irAt(ptr %t3_2, i32 2)
  %t3_2_2_2 = call ptr @irAt(ptr %t3_2_2, i32 2)
  %t3_2_2_2_1 = call ptr @irAt(ptr %t3_2_2_2, i32 1)
  %t3_2_2_2_1_2 = call ptr @irAt(ptr %t3_2_2_2_1, i32 2)
  %t3_2_2_2_1_3 = call ptr @irAt(ptr %t3_2_2_2_1, i32 3)
  %vt3_2_2_2_1_3 = call i32 @irCountOf(ptr %t3_2_2_2_1_3)
  %t3_2_2_2_2 = call ptr @irAt(ptr %t3_2_2_2, i32 2)
  %t3_2_2_2_2_2 = call ptr @irAt(ptr %t3_2_2_2_2, i32 2)
  %t3_2_2_2_2_2_1 = call ptr @irAt(ptr %t3_2_2_2_2_2, i32 1)
  %t3_2_2_2_2_2_1_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_1, i32 2)
  %t3_2_2_2_2_2_1_3 = call ptr @irAt(ptr %t3_2_2_2_2_2_1, i32 3)
  %t3_2_2_2_2_2_2 = call ptr @irAt(ptr %t3_2_2_2_2_2, i32 2)
  %t3_2_2_2_2_2_2_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2, i32 2)
  %t3_2_2_2_2_2_2_2_1 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2, i32 1)
  %t3_2_2_2_2_2_2_2_1_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_1, i32 2)
  %t3_2_2_2_2_2_2_2_1_3 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_1, i32 3)
  %t3_2_2_2_2_2_2_2_1_3_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_1_3, i32 2)
  %t3_2_2_2_2_2_2_2_1_3_3 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_1_3, i32 3)
  %t3_2_2_2_2_2_2_2_1_3_2_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_1_3_2, i32 2)
  %t3_2_2_2_2_2_2_2_1_3_2_3 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_1_3_2, i32 3)
  %t3_2_2_2_2_2_2_2_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2, i32 2)
  %t3_2_2_2_2_2_2_2_2_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_2, i32 2)
  %t3_2_2_2_2_2_2_2_2_3 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_2, i32 3)
  %t3_2_2_2_2_2_2_2_2_3_2 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_2_3, i32 2)
  %t3_2_2_2_2_2_2_2_2_3_3 = call ptr @irAt(ptr %t3_2_2_2_2_2_2_2_2_3, i32 3)
  %vt3_2_2_2_2_2_2_2_2_3_3 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_2_3_3)
  %t3_2_2_2_3 = call ptr @irAt(ptr %t3_2_2_2, i32 3)
  %t3_2_2_2_3_2 = call ptr @irAt(ptr %t3_2_2_2_3, i32 2)
  %t3_2_2_2_3_3 = call ptr @irAt(ptr %t3_2_2_2_3, i32 3)
  %t3_2_2_2_3_3_2 = call ptr @irAt(ptr %t3_2_2_2_3_3, i32 2)
  %t3_2_2_2_3_3_3 = call ptr @irAt(ptr %t3_2_2_2_3_3, i32 3)
  %vt3_2_2_2_3_3_3 = call i32 @irCountOf(ptr %t3_2_2_2_3_3_3)
  %Si = alloca i32
  %Di = alloca i1
  store i1 0, ptr %Di
  %LI_i = call i32 @irCountOf(ptr %Fi)
  store i32 %LI_i, ptr %Si
  %Ss = alloca i32
  %Ds = alloca i1
  store i1 0, ptr %Ds
  %LI_s = call i32 @irCountOf(ptr %Fs)
  store i32 %LI_s, ptr %Ss
  br label %s1
s1:
  %n1 = load i32, ptr @kw_wqW_n
  %m1 = add i32 %n1, 1
  store i32 %m1, ptr @kw_wqW_n
  store i32 %vt1_3, ptr %Si
  store i1 1, ptr %Di
  store ptr %t1_2, ptr %last
  br label %s2
s2:
  %n2 = load i32, ptr @kw_wqW_n
  %m2 = add i32 %n2, 1
  store i32 %m2, ptr @kw_wqW_n
  store i32 %vt2_3, ptr %Ss
  store i1 1, ptr %Ds
  store ptr %t2_2, ptr %last
  br label %s3
s3:
  %n3 = load i32, ptr @kw_wqW_n
  %m3 = add i32 %n3, 1
  store i32 %m3, ptr @kw_wqW_n
  br label %wt3
wt3:
  %vt3_2_1_2 = load i32, ptr %Si
  %vt3_2_1 = icmp slt i32 %vt3_2_1_2, %vt3_2_1_3
  br i1 %vt3_2_1, label %yt3, label %xt3
yt3:
  %rt3_2_2_2_1 = call ptr @irSetCount(ptr %t3_2_2_2_1_2, i32 %vt3_2_2_2_1_3)
  store ptr %rt3_2_2_2_1, ptr %last
  %gt3_2_2_2_1 = call i32 @irGoOn()
  %ct3_2_2_2_1 = icmp ne i32 %gt3_2_2_2_1, 0
  br i1 %ct3_2_2_2_1, label %nt3_2_2_2_1, label %back
nt3_2_2_2_1:
  br label %wt3_2_2_2_2
wt3_2_2_2_2:
  %vt3_2_2_2_2_2_1_2 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_1_2)
  %vt3_2_2_2_2_2_1_3 = load i32, ptr %Si
  %vt3_2_2_2_2_2_1 = icmp slt i32 %vt3_2_2_2_2_2_1_2, %vt3_2_2_2_2_2_1_3
  br i1 %vt3_2_2_2_2_2_1, label %yt3_2_2_2_2, label %xt3_2_2_2_2
yt3_2_2_2_2:
  %vt3_2_2_2_2_2_2_2_1_3_2_2 = load i32, ptr %Ss
  %vt3_2_2_2_2_2_2_2_1_3_2_3 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_1_3_2_3)
  %vt3_2_2_2_2_2_2_2_1_3_2 = add i32 %vt3_2_2_2_2_2_2_2_1_3_2_2, %vt3_2_2_2_2_2_2_2_1_3_2_3
  %vt3_2_2_2_2_2_2_2_1_3_3 = load i32, ptr %Si
  %vt3_2_2_2_2_2_2_2_1_3 = mul i32 %vt3_2_2_2_2_2_2_2_1_3_2, %vt3_2_2_2_2_2_2_2_1_3_3
  store i32 %vt3_2_2_2_2_2_2_2_1_3, ptr %Ss
  store i1 1, ptr %Ds
  store ptr %t3_2_2_2_2_2_2_2_1_2, ptr %last
  %vt3_2_2_2_2_2_2_2_2_3_2 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_2_3_2)
  %vt3_2_2_2_2_2_2_2_2_3 = add i32 %vt3_2_2_2_2_2_2_2_2_3_2, %vt3_2_2_2_2_2_2_2_2_3_3
  %rt3_2_2_2_2_2_2_2_2 = call ptr @irSetCount(ptr %t3_2_2_2_2_2_2_2_2_2, i32 %vt3_2_2_2_2_2_2_2_2_3)
  store ptr %rt3_2_2_2_2_2_2_2_2, ptr %last
  %gt3_2_2_2_2_2_2_2_2 = call i32 @irGoOn()
  %ct3_2_2_2_2_2_2_2_2 = icmp ne i32 %gt3_2_2_2_2_2_2_2_2, 0
  br i1 %ct3_2_2_2_2_2_2_2_2, label %nt3_2_2_2_2_2_2_2_2, label %back
nt3_2_2_2_2_2_2_2_2:
  store ptr %t3_2_2_2_2_2_2_2, ptr %last
  br label %wt3_2_2_2_2
xt3_2_2_2_2:
  store ptr null, ptr %last
  %vt3_2_2_2_3_3_2 = load i32, ptr %Si
  %vt3_2_2_2_3_3 = add i32 %vt3_2_2_2_3_3_2, %vt3_2_2_2_3_3_3
  store i32 %vt3_2_2_2_3_3, ptr %Si
  store i1 1, ptr %Di
  store ptr %t3_2_2_2_3_2, ptr %last
  store ptr %t3_2_2_2, ptr %last
  br label %wt3
xt3:
  store ptr null, ptr %last
  br label %s4
s4:
  %n4 = load i32, ptr @kw_wqW_n
  %m4 = add i32 %n4, 1
  store i32 %m4, ptr @kw_wqW_n
  %tn4 = load i32, ptr @kw_wqW_t
  %tm4 = add i32 %tn4, 1
  store i32 %tm4, ptr @kw_wqW_t
  %P4_i = load i1, ptr %Di
  br i1 %P4_i, label %K4_i, label %J4_i
K4_i:
  %Q4_i = load i32, ptr %Si
  %R4_i = call ptr @irSetCount(ptr %Fi, i32 %Q4_i)
  store i1 0, ptr %Di
  br label %J4_i
J4_i:
  %P4_s = load i1, ptr %Ds
  br i1 %P4_s, label %K4_s, label %J4_s
K4_s:
  %Q4_s = load i32, ptr %Ss
  %R4_s = call ptr @irSetCount(ptr %Fs, i32 %Q4_s)
  store i1 0, ptr %Ds
  br label %J4_s
J4_s:
  %f4 = call ptr @irAt(ptr %items, i32 4)
  %r4 = call ptr @testOP(ptr %f4)
  store ptr %r4, ptr %last
  %g4 = call i32 @irGoOn()
  %c4 = icmp ne i32 %g4, 0
  br i1 %c4, label %q4, label %done
q4:
  %L4_i = call i32 @irCountOf(ptr %Fi)
  store i32 %L4_i, ptr %Si
  %L4_s = call i32 @irCountOf(ptr %Fs)
  store i32 %L4_s, ptr %Ss
  br label %s5
s5:
  br label %back
back:
  %PB_i = load i1, ptr %Di
  br i1 %PB_i, label %KB_i, label %JB_i
KB_i:
  %QB_i = load i32, ptr %Si
  %RB_i = call ptr @irSetCount(ptr %Fi, i32 %QB_i)
  store i1 0, ptr %Di
  br label %JB_i
JB_i:
  %PB_s = load i1, ptr %Ds
  br i1 %PB_s, label %KB_s, label %JB_s
KB_s:
  %QB_s = load i32, ptr %Ss
  %RB_s = call ptr @irSetCount(ptr %Fs, i32 %QB_s)
  store i1 0, ptr %Ds
  br label %JB_s
JB_s:
  br label %done
done:
  %v = load ptr, ptr %last
  %e = call ptr @irSeqEnd(ptr %items, ptr %v)
  ret ptr %e
}
define i32 @kw_wqW_ran(ptr %a) {
entry:
  %n = load i32, ptr @kw_wqW_n
  ret i32 %n
}
define i32 @kw_wqW_tops(ptr %a) {
entry:
  %n = load i32, ptr @kw_wqW_t
  ret i32 %n
}
