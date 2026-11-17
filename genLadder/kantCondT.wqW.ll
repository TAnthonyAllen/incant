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
  %t2 = call ptr @irAt(ptr %items, i32 2)
  %t2_2 = call ptr @irAt(ptr %t2, i32 2)
  %t2_3 = call ptr @irAt(ptr %t2, i32 3)
  %t3 = call ptr @irAt(ptr %items, i32 3)
  %t3_2 = call ptr @irAt(ptr %t3, i32 2)
  %t3_2_1 = call ptr @irAt(ptr %t3_2, i32 1)
  %t3_2_1_2 = call ptr @irAt(ptr %t3_2_1, i32 2)
  %t3_2_1_3 = call ptr @irAt(ptr %t3_2_1, i32 3)
  %t3_2_2 = call ptr @irAt(ptr %t3_2, i32 2)
  %t3_2_2_2 = call ptr @irAt(ptr %t3_2_2, i32 2)
  %t3_2_2_2_1 = call ptr @irAt(ptr %t3_2_2_2, i32 1)
  %t3_2_2_2_1_2 = call ptr @irAt(ptr %t3_2_2_2_1, i32 2)
  %t3_2_2_2_1_3 = call ptr @irAt(ptr %t3_2_2_2_1, i32 3)
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
  %t3_2_2_2_3 = call ptr @irAt(ptr %t3_2_2_2, i32 3)
  %t3_2_2_2_3_2 = call ptr @irAt(ptr %t3_2_2_2_3, i32 2)
  %t3_2_2_2_3_3 = call ptr @irAt(ptr %t3_2_2_2_3, i32 3)
  %t3_2_2_2_3_3_2 = call ptr @irAt(ptr %t3_2_2_2_3_3, i32 2)
  %t3_2_2_2_3_3_3 = call ptr @irAt(ptr %t3_2_2_2_3_3, i32 3)
  br label %s1
s1:
  %n1 = load i32, ptr @kw_wqW_n
  %m1 = add i32 %n1, 1
  store i32 %m1, ptr @kw_wqW_n
  %vt1_3 = call i32 @irCountOf(ptr %t1_3)
  %r1 = call ptr @irSetCount(ptr %t1_2, i32 %vt1_3)
  store ptr %r1, ptr %last
  %g1 = call i32 @irGoOn()
  %c1 = icmp ne i32 %g1, 0
  br i1 %c1, label %s2, label %done
s2:
  %n2 = load i32, ptr @kw_wqW_n
  %m2 = add i32 %n2, 1
  store i32 %m2, ptr @kw_wqW_n
  %vt2_3 = call i32 @irCountOf(ptr %t2_3)
  %r2 = call ptr @irSetCount(ptr %t2_2, i32 %vt2_3)
  store ptr %r2, ptr %last
  %g2 = call i32 @irGoOn()
  %c2 = icmp ne i32 %g2, 0
  br i1 %c2, label %s3, label %done
s3:
  %n3 = load i32, ptr @kw_wqW_n
  %m3 = add i32 %n3, 1
  store i32 %m3, ptr @kw_wqW_n
  br label %wt3
wt3:
  %vt3_2_1_2 = call i32 @irCountOf(ptr %t3_2_1_2)
  %vt3_2_1_3 = call i32 @irCountOf(ptr %t3_2_1_3)
  %vt3_2_1 = icmp slt i32 %vt3_2_1_2, %vt3_2_1_3
  br i1 %vt3_2_1, label %yt3, label %xt3
yt3:
  %vt3_2_2_2_1_3 = call i32 @irCountOf(ptr %t3_2_2_2_1_3)
  %rt3_2_2_2_1 = call ptr @irSetCount(ptr %t3_2_2_2_1_2, i32 %vt3_2_2_2_1_3)
  store ptr %rt3_2_2_2_1, ptr %last
  %gt3_2_2_2_1 = call i32 @irGoOn()
  %ct3_2_2_2_1 = icmp ne i32 %gt3_2_2_2_1, 0
  br i1 %ct3_2_2_2_1, label %nt3_2_2_2_1, label %done
nt3_2_2_2_1:
  br label %wt3_2_2_2_2
wt3_2_2_2_2:
  %vt3_2_2_2_2_2_1_2 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_1_2)
  %vt3_2_2_2_2_2_1_3 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_1_3)
  %vt3_2_2_2_2_2_1 = icmp slt i32 %vt3_2_2_2_2_2_1_2, %vt3_2_2_2_2_2_1_3
  br i1 %vt3_2_2_2_2_2_1, label %yt3_2_2_2_2, label %xt3_2_2_2_2
yt3_2_2_2_2:
  %vt3_2_2_2_2_2_2_2_1_3_2_2 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_1_3_2_2)
  %vt3_2_2_2_2_2_2_2_1_3_2_3 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_1_3_2_3)
  %vt3_2_2_2_2_2_2_2_1_3_2 = add i32 %vt3_2_2_2_2_2_2_2_1_3_2_2, %vt3_2_2_2_2_2_2_2_1_3_2_3
  %vt3_2_2_2_2_2_2_2_1_3_3 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_1_3_3)
  %vt3_2_2_2_2_2_2_2_1_3 = mul i32 %vt3_2_2_2_2_2_2_2_1_3_2, %vt3_2_2_2_2_2_2_2_1_3_3
  %rt3_2_2_2_2_2_2_2_1 = call ptr @irSetCount(ptr %t3_2_2_2_2_2_2_2_1_2, i32 %vt3_2_2_2_2_2_2_2_1_3)
  store ptr %rt3_2_2_2_2_2_2_2_1, ptr %last
  %gt3_2_2_2_2_2_2_2_1 = call i32 @irGoOn()
  %ct3_2_2_2_2_2_2_2_1 = icmp ne i32 %gt3_2_2_2_2_2_2_2_1, 0
  br i1 %ct3_2_2_2_2_2_2_2_1, label %nt3_2_2_2_2_2_2_2_1, label %done
nt3_2_2_2_2_2_2_2_1:
  %vt3_2_2_2_2_2_2_2_2_3_2 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_2_3_2)
  %vt3_2_2_2_2_2_2_2_2_3_3 = call i32 @irCountOf(ptr %t3_2_2_2_2_2_2_2_2_3_3)
  %vt3_2_2_2_2_2_2_2_2_3 = add i32 %vt3_2_2_2_2_2_2_2_2_3_2, %vt3_2_2_2_2_2_2_2_2_3_3
  %rt3_2_2_2_2_2_2_2_2 = call ptr @irSetCount(ptr %t3_2_2_2_2_2_2_2_2_2, i32 %vt3_2_2_2_2_2_2_2_2_3)
  store ptr %rt3_2_2_2_2_2_2_2_2, ptr %last
  %gt3_2_2_2_2_2_2_2_2 = call i32 @irGoOn()
  %ct3_2_2_2_2_2_2_2_2 = icmp ne i32 %gt3_2_2_2_2_2_2_2_2, 0
  br i1 %ct3_2_2_2_2_2_2_2_2, label %nt3_2_2_2_2_2_2_2_2, label %done
nt3_2_2_2_2_2_2_2_2:
  store ptr %t3_2_2_2_2_2_2_2, ptr %last
  br label %wt3_2_2_2_2
xt3_2_2_2_2:
  store ptr null, ptr %last
  %vt3_2_2_2_3_3_2 = call i32 @irCountOf(ptr %t3_2_2_2_3_3_2)
  %vt3_2_2_2_3_3_3 = call i32 @irCountOf(ptr %t3_2_2_2_3_3_3)
  %vt3_2_2_2_3_3 = add i32 %vt3_2_2_2_3_3_2, %vt3_2_2_2_3_3_3
  %rt3_2_2_2_3 = call ptr @irSetCount(ptr %t3_2_2_2_3_2, i32 %vt3_2_2_2_3_3)
  store ptr %rt3_2_2_2_3, ptr %last
  %gt3_2_2_2_3 = call i32 @irGoOn()
  %ct3_2_2_2_3 = icmp ne i32 %gt3_2_2_2_3, 0
  br i1 %ct3_2_2_2_3, label %nt3_2_2_2_3, label %done
nt3_2_2_2_3:
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
  %f4 = call ptr @irAt(ptr %items, i32 4)
  %r4 = call ptr @testOP(ptr %f4)
  store ptr %r4, ptr %last
  %g4 = call i32 @irGoOn()
  %c4 = icmp ne i32 %g4, 0
  br i1 %c4, label %s5, label %done
s5:
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
