declare ptr @testOP(ptr)
declare ptr @irAt(ptr, i32)
declare i32 @irGoOn()
declare ptr @irSeqEnd(ptr, ptr)
@kw_kwr_n = global i32 0
define ptr @kw_kwr(ptr %a) {
entry:
  %last = alloca ptr
  store ptr null, ptr %last
  %items = call ptr @irAt(ptr %a, i32 2)
  br label %s1
s1:
  %n1 = load i32, ptr @kw_kwr_n
  %m1 = add i32 %n1, 1
  store i32 %m1, ptr @kw_kwr_n
  %f1 = call ptr @irAt(ptr %items, i32 1)
  %r1 = call ptr @testOP(ptr %f1)
  store ptr %r1, ptr %last
  %g1 = call i32 @irGoOn()
  %c1 = icmp ne i32 %g1, 0
  br i1 %c1, label %s2, label %done
s2:
  %n2 = load i32, ptr @kw_kwr_n
  %m2 = add i32 %n2, 1
  store i32 %m2, ptr @kw_kwr_n
  %f2 = call ptr @irAt(ptr %items, i32 2)
  %r2 = call ptr @testOP(ptr %f2)
  store ptr %r2, ptr %last
  %g2 = call i32 @irGoOn()
  %c2 = icmp ne i32 %g2, 0
  br i1 %c2, label %s3, label %done
s3:
  %n3 = load i32, ptr @kw_kwr_n
  %m3 = add i32 %n3, 1
  store i32 %m3, ptr @kw_kwr_n
  %f3 = call ptr @irAt(ptr %items, i32 3)
  %r3 = call ptr @testOP(ptr %f3)
  store ptr %r3, ptr %last
  %g3 = call i32 @irGoOn()
  %c3 = icmp ne i32 %g3, 0
  br i1 %c3, label %s4, label %done
s4:
  br label %done
done:
  %v = load ptr, ptr %last
  %e = call ptr @irSeqEnd(ptr %items, ptr %v)
  ret ptr %e
}
define i32 @kw_kwr_ran(ptr %a) {
entry:
  %n = load i32, ptr @kw_kwr_n
  ret i32 %n
}
