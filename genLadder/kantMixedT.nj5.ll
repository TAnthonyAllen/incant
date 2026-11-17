declare ptr @testOP(ptr)
declare ptr @irAt(ptr, i32)
declare i32 @irGoOn()
declare ptr @irSeqEnd(ptr, ptr)
@kw_nj5_n = global i32 0
declare i32 @irCountOf(ptr)
declare double @irNumberOf(ptr)
declare ptr @irSetCount(ptr, i32)
declare ptr @irSetNumber(ptr, double)
@kw_nj5_t = global i32 0
define ptr @kw_nj5(ptr %a) {
entry:
  %last = alloca ptr
  store ptr null, ptr %last
  %items = call ptr @irAt(ptr %a, i32 2)
  %t1 = call ptr @irAt(ptr %items, i32 1)
  %t1_2 = call ptr @irAt(ptr %t1, i32 2)
  %t1_3 = call ptr @irAt(ptr %t1, i32 3)
  %Fa5 = bitcast ptr %t1_2 to ptr
  %vt1_3 = call double @irNumberOf(ptr %t1_3)
  %t2 = call ptr @irAt(ptr %items, i32 2)
  %t2_2 = call ptr @irAt(ptr %t2, i32 2)
  %t2_3 = call ptr @irAt(ptr %t2, i32 3)
  %Fb5 = bitcast ptr %t2_2 to ptr
  %t2_3_2 = call ptr @irAt(ptr %t2_3, i32 2)
  %t2_3_3 = call ptr @irAt(ptr %t2_3, i32 3)
  %vt2_3_3 = call i32 @irCountOf(ptr %t2_3_3)
  %Sa5 = alloca double
  %Da5 = alloca i1
  store i1 0, ptr %Da5
  %LI_a5 = call double @irNumberOf(ptr %Fa5)
  store double %LI_a5, ptr %Sa5
  %Sb5 = alloca double
  %Db5 = alloca i1
  store i1 0, ptr %Db5
  %LI_b5 = call double @irNumberOf(ptr %Fb5)
  store double %LI_b5, ptr %Sb5
  br label %s1
s1:
  %n1 = load i32, ptr @kw_nj5_n
  %m1 = add i32 %n1, 1
  store i32 %m1, ptr @kw_nj5_n
  store double %vt1_3, ptr %Sa5
  store i1 1, ptr %Da5
  store ptr %t1_2, ptr %last
  br label %s2
s2:
  %n2 = load i32, ptr @kw_nj5_n
  %m2 = add i32 %n2, 1
  store i32 %m2, ptr @kw_nj5_n
  %vt2_3_2 = load double, ptr %Sa5
  %wt2_3_3 = sitofp i32 %vt2_3_3 to double
  %vt2_3 = fadd double %vt2_3_2, %wt2_3_3
  store double %vt2_3, ptr %Sb5
  store i1 1, ptr %Db5
  store ptr %t2_2, ptr %last
  br label %s3
s3:
  %n3 = load i32, ptr @kw_nj5_n
  %m3 = add i32 %n3, 1
  store i32 %m3, ptr @kw_nj5_n
  %tn3 = load i32, ptr @kw_nj5_t
  %tm3 = add i32 %tn3, 1
  store i32 %tm3, ptr @kw_nj5_t
  %P3_a5 = load i1, ptr %Da5
  br i1 %P3_a5, label %K3_a5, label %J3_a5
K3_a5:
  %Q3_a5 = load double, ptr %Sa5
  %R3_a5 = call ptr @irSetNumber(ptr %Fa5, double %Q3_a5)
  store i1 0, ptr %Da5
  br label %J3_a5
J3_a5:
  %P3_b5 = load i1, ptr %Db5
  br i1 %P3_b5, label %K3_b5, label %J3_b5
K3_b5:
  %Q3_b5 = load double, ptr %Sb5
  %R3_b5 = call ptr @irSetNumber(ptr %Fb5, double %Q3_b5)
  store i1 0, ptr %Db5
  br label %J3_b5
J3_b5:
  %f3 = call ptr @irAt(ptr %items, i32 3)
  %r3 = call ptr @testOP(ptr %f3)
  store ptr %r3, ptr %last
  %g3 = call i32 @irGoOn()
  %c3 = icmp ne i32 %g3, 0
  br i1 %c3, label %q3, label %done
q3:
  %L3_a5 = call double @irNumberOf(ptr %Fa5)
  store double %L3_a5, ptr %Sa5
  %L3_b5 = call double @irNumberOf(ptr %Fb5)
  store double %L3_b5, ptr %Sb5
  br label %s4
s4:
  br label %back
back:
  %PB_a5 = load i1, ptr %Da5
  br i1 %PB_a5, label %KB_a5, label %JB_a5
KB_a5:
  %QB_a5 = load double, ptr %Sa5
  %RB_a5 = call ptr @irSetNumber(ptr %Fa5, double %QB_a5)
  store i1 0, ptr %Da5
  br label %JB_a5
JB_a5:
  %PB_b5 = load i1, ptr %Db5
  br i1 %PB_b5, label %KB_b5, label %JB_b5
KB_b5:
  %QB_b5 = load double, ptr %Sb5
  %RB_b5 = call ptr @irSetNumber(ptr %Fb5, double %QB_b5)
  store i1 0, ptr %Db5
  br label %JB_b5
JB_b5:
  br label %done
done:
  %v = load ptr, ptr %last
  %e = call ptr @irSeqEnd(ptr %items, ptr %v)
  ret ptr %e
}
define i32 @kw_nj5_ran(ptr %a) {
entry:
  %n = load i32, ptr @kw_nj5_n
  ret i32 %n
}
define i32 @kw_nj5_tops(ptr %a) {
entry:
  %n = load i32, ptr @kw_nj5_t
  ret i32 %n
}
