declare ptr @testOP(ptr)
declare ptr @irAt(ptr, i32)
declare i32 @irGoOn()
declare ptr @irSeqEnd(ptr, ptr)
@kw_nj4_n = global i32 0
declare i32 @irCountOf(ptr)
declare double @irNumberOf(ptr)
declare ptr @irSetCount(ptr, i32)
declare ptr @irSetNumber(ptr, double)
@kw_nj4_t = global i32 0
define ptr @kw_nj4(ptr %a) {
entry:
  %last = alloca ptr
  store ptr null, ptr %last
  %items = call ptr @irAt(ptr %a, i32 2)
  %t1 = call ptr @irAt(ptr %items, i32 1)
  %t1_2 = call ptr @irAt(ptr %t1, i32 2)
  %t1_3 = call ptr @irAt(ptr %t1, i32 3)
  %Fa4 = bitcast ptr %t1_2 to ptr
  %vt1_3 = call i32 @irCountOf(ptr %t1_3)
  %t2 = call ptr @irAt(ptr %items, i32 2)
  %t2_2 = call ptr @irAt(ptr %t2, i32 2)
  %t2_3 = call ptr @irAt(ptr %t2, i32 3)
  %Fb4 = bitcast ptr %t2_2 to ptr
  %t2_3_2 = call ptr @irAt(ptr %t2_3, i32 2)
  %t2_3_3 = call ptr @irAt(ptr %t2_3, i32 3)
  %vt2_3_3 = call i32 @irCountOf(ptr %t2_3_3)
  %t3 = call ptr @irAt(ptr %items, i32 3)
  %t3_2 = call ptr @irAt(ptr %t3, i32 2)
  %t3_3 = call ptr @irAt(ptr %t3, i32 3)
  %Fc4 = bitcast ptr %t3_2 to ptr
  %t3_3_2 = call ptr @irAt(ptr %t3_3, i32 2)
  %t3_3_3 = call ptr @irAt(ptr %t3_3, i32 3)
  %vt3_3_3 = call i32 @irCountOf(ptr %t3_3_3)
  %Sa4 = alloca i32
  %Da4 = alloca i1
  store i1 0, ptr %Da4
  %LI_a4 = call i32 @irCountOf(ptr %Fa4)
  store i32 %LI_a4, ptr %Sa4
  %Sb4 = alloca i32
  %Db4 = alloca i1
  store i1 0, ptr %Db4
  %LI_b4 = call i32 @irCountOf(ptr %Fb4)
  store i32 %LI_b4, ptr %Sb4
  %Sc4 = alloca i32
  %Dc4 = alloca i1
  store i1 0, ptr %Dc4
  %LI_c4 = call i32 @irCountOf(ptr %Fc4)
  store i32 %LI_c4, ptr %Sc4
  br label %s1
s1:
  %n1 = load i32, ptr @kw_nj4_n
  %m1 = add i32 %n1, 1
  store i32 %m1, ptr @kw_nj4_n
  store i32 %vt1_3, ptr %Sa4
  store i1 1, ptr %Da4
  store ptr %t1_2, ptr %last
  br label %s2
s2:
  %n2 = load i32, ptr @kw_nj4_n
  %m2 = add i32 %n2, 1
  store i32 %m2, ptr @kw_nj4_n
  %vt2_3_2 = load i32, ptr %Sa4
  %vt2_3 = add i32 %vt2_3_2, %vt2_3_3
  store i32 %vt2_3, ptr %Sb4
  store i1 1, ptr %Db4
  store ptr %t2_2, ptr %last
  br label %s3
s3:
  %n3 = load i32, ptr @kw_nj4_n
  %m3 = add i32 %n3, 1
  store i32 %m3, ptr @kw_nj4_n
  %vt3_3_2 = load i32, ptr %Sb4
  %vt3_3 = mul i32 %vt3_3_2, %vt3_3_3
  store i32 %vt3_3, ptr %Sc4
  store i1 1, ptr %Dc4
  store ptr %t3_2, ptr %last
  br label %s4
s4:
  %n4 = load i32, ptr @kw_nj4_n
  %m4 = add i32 %n4, 1
  store i32 %m4, ptr @kw_nj4_n
  %tn4 = load i32, ptr @kw_nj4_t
  %tm4 = add i32 %tn4, 1
  store i32 %tm4, ptr @kw_nj4_t
  %P4_a4 = load i1, ptr %Da4
  br i1 %P4_a4, label %K4_a4, label %J4_a4
K4_a4:
  %Q4_a4 = load i32, ptr %Sa4
  %R4_a4 = call ptr @irSetCount(ptr %Fa4, i32 %Q4_a4)
  store i1 0, ptr %Da4
  br label %J4_a4
J4_a4:
  %P4_b4 = load i1, ptr %Db4
  br i1 %P4_b4, label %K4_b4, label %J4_b4
K4_b4:
  %Q4_b4 = load i32, ptr %Sb4
  %R4_b4 = call ptr @irSetCount(ptr %Fb4, i32 %Q4_b4)
  store i1 0, ptr %Db4
  br label %J4_b4
J4_b4:
  %P4_c4 = load i1, ptr %Dc4
  br i1 %P4_c4, label %K4_c4, label %J4_c4
K4_c4:
  %Q4_c4 = load i32, ptr %Sc4
  %R4_c4 = call ptr @irSetCount(ptr %Fc4, i32 %Q4_c4)
  store i1 0, ptr %Dc4
  br label %J4_c4
J4_c4:
  %f4 = call ptr @irAt(ptr %items, i32 4)
  %r4 = call ptr @testOP(ptr %f4)
  store ptr %r4, ptr %last
  %g4 = call i32 @irGoOn()
  %c4 = icmp ne i32 %g4, 0
  br i1 %c4, label %q4, label %done
q4:
  %L4_a4 = call i32 @irCountOf(ptr %Fa4)
  store i32 %L4_a4, ptr %Sa4
  %L4_b4 = call i32 @irCountOf(ptr %Fb4)
  store i32 %L4_b4, ptr %Sb4
  %L4_c4 = call i32 @irCountOf(ptr %Fc4)
  store i32 %L4_c4, ptr %Sc4
  br label %s5
s5:
  br label %back
back:
  %PB_a4 = load i1, ptr %Da4
  br i1 %PB_a4, label %KB_a4, label %JB_a4
KB_a4:
  %QB_a4 = load i32, ptr %Sa4
  %RB_a4 = call ptr @irSetCount(ptr %Fa4, i32 %QB_a4)
  store i1 0, ptr %Da4
  br label %JB_a4
JB_a4:
  %PB_b4 = load i1, ptr %Db4
  br i1 %PB_b4, label %KB_b4, label %JB_b4
KB_b4:
  %QB_b4 = load i32, ptr %Sb4
  %RB_b4 = call ptr @irSetCount(ptr %Fb4, i32 %QB_b4)
  store i1 0, ptr %Db4
  br label %JB_b4
JB_b4:
  %PB_c4 = load i1, ptr %Dc4
  br i1 %PB_c4, label %KB_c4, label %JB_c4
KB_c4:
  %QB_c4 = load i32, ptr %Sc4
  %RB_c4 = call ptr @irSetCount(ptr %Fc4, i32 %QB_c4)
  store i1 0, ptr %Dc4
  br label %JB_c4
JB_c4:
  br label %done
done:
  %v = load ptr, ptr %last
  %e = call ptr @irSeqEnd(ptr %items, ptr %v)
  ret ptr %e
}
define i32 @kw_nj4_ran(ptr %a) {
entry:
  %n = load i32, ptr @kw_nj4_n
  ret i32 %n
}
define i32 @kw_nj4_tops(ptr %a) {
entry:
  %n = load i32, ptr @kw_nj4_t
  ret i32 %n
}
