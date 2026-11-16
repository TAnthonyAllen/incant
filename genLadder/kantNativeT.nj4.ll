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
  %t2 = call ptr @irAt(ptr %items, i32 2)
  %t2_2 = call ptr @irAt(ptr %t2, i32 2)
  %t2_3 = call ptr @irAt(ptr %t2, i32 3)
  %t2_3_2 = call ptr @irAt(ptr %t2_3, i32 2)
  %t2_3_3 = call ptr @irAt(ptr %t2_3, i32 3)
  %t3 = call ptr @irAt(ptr %items, i32 3)
  %t3_2 = call ptr @irAt(ptr %t3, i32 2)
  %t3_3 = call ptr @irAt(ptr %t3, i32 3)
  %t3_3_2 = call ptr @irAt(ptr %t3_3, i32 2)
  %t3_3_3 = call ptr @irAt(ptr %t3_3, i32 3)
  br label %s1
s1:
  %n1 = load i32, ptr @kw_nj4_n
  %m1 = add i32 %n1, 1
  store i32 %m1, ptr @kw_nj4_n
  %vt1_3 = call i32 @irCountOf(ptr %t1_3)
  %r1 = call ptr @irSetCount(ptr %t1_2, i32 %vt1_3)
  store ptr %r1, ptr %last
  %g1 = call i32 @irGoOn()
  %c1 = icmp ne i32 %g1, 0
  br i1 %c1, label %s2, label %done
s2:
  %n2 = load i32, ptr @kw_nj4_n
  %m2 = add i32 %n2, 1
  store i32 %m2, ptr @kw_nj4_n
  %vt2_3_2 = call i32 @irCountOf(ptr %t2_3_2)
  %vt2_3_3 = call i32 @irCountOf(ptr %t2_3_3)
  %vt2_3 = add i32 %vt2_3_2, %vt2_3_3
  %r2 = call ptr @irSetCount(ptr %t2_2, i32 %vt2_3)
  store ptr %r2, ptr %last
  %g2 = call i32 @irGoOn()
  %c2 = icmp ne i32 %g2, 0
  br i1 %c2, label %s3, label %done
s3:
  %n3 = load i32, ptr @kw_nj4_n
  %m3 = add i32 %n3, 1
  store i32 %m3, ptr @kw_nj4_n
  %vt3_3_2 = call i32 @irCountOf(ptr %t3_3_2)
  %vt3_3_3 = call i32 @irCountOf(ptr %t3_3_3)
  %vt3_3 = mul i32 %vt3_3_2, %vt3_3_3
  %r3 = call ptr @irSetCount(ptr %t3_2, i32 %vt3_3)
  store ptr %r3, ptr %last
  %g3 = call i32 @irGoOn()
  %c3 = icmp ne i32 %g3, 0
  br i1 %c3, label %s4, label %done
s4:
  %n4 = load i32, ptr @kw_nj4_n
  %m4 = add i32 %n4, 1
  store i32 %m4, ptr @kw_nj4_n
  %tn4 = load i32, ptr @kw_nj4_t
  %tm4 = add i32 %tn4, 1
  store i32 %tm4, ptr @kw_nj4_t
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
