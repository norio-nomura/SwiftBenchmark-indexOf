# SwiftBenchmark-indexOf

### `swiftc -emit-sil -O`にはSwift標準ライブラリの中身も出力される

---

[ここ](https://github.com/katokichisoft/SimpleGaplessPlayer/blob/master/HKLAVGaplessPlayer/misc/HKLStdLibUtils.swift)でこんなコードをみた。
```swift
extension Array {
    /**
    Returns the lowest index whose corresponding array value matches a given condition.

    :discussion: Starting at index 0, each element of the array is passed as the 1st parameter of condition closure until a match is found or the end of the array is reached. Objects are considered equal if the closure returns true.

    :param: condition A closure for finding the target object in the array

    :returns: The lowest index whose corresponding array value matches a given condition. If none of the objects in the array matches the condition, returns nil.

    :refer: http://stackoverflow.com/a/24105493
    */
    func indexOf(condition: T -> Bool) -> Int? {
        for (idx, element) in enumerate(self) {
            if condition(element) {
                return idx
            }
        }
        return nil
    }
}
```

同じ機能を`lazy()`とか使って書いてみた。

```swift
func v1_index_of<C : CollectionType where C.Generator.Element : Equatable>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
    return find(lazy(domain).map(condition), true)
}
```

うんシンプル。でもどっちを使うべきだろう？で[ベンチマーク](Benchmark/Benchmark.swift)

> <unknown>:0: Test Case '-[Benchmark.Benchmark testPerformance_v1]' measured [Time, seconds] average: 1.557,…

> <unknown>:0: Test Case '-[Benchmark.Benchmark testPerformance_v4]' measured [Time, seconds] average: 2.403,…

**おおよそ1.6倍くらいオリジナルが遅い。**

**やっぱ時代はFunctionalなのか！？**で、Swiftがどんなコードを出力してるのか気になったので、こんなコード

```swift
#!/usr/bin/env xcrun swift -i
import Foundation

func v1_index_of<C : CollectionType where C.Generator.Element : Equatable>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
  return find(lazy(domain).map(condition), true)
}

func v2_index_of<C : CollectionType>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
  for (idx, element) in enumerate(domain) {
    if condition(element) {
      return idx as? C.Index
    }
  }
  return nil
}

let a = [1,2,3]
let c = {(e: Int) -> Bool in e == 1}
let result1 = v1_index_of(a, c)
let result2 = v2_index_of(a, c)
```

を、以前書いた[swift-demangle-filter.py](https://gist.github.com/norio-nomura/121ef3eacbc6dda87dad)に通す。

`swift-demangle-filter.py -g indexof.swift -o indexof.asm`

[indexof.asm](https://gist.github.com/norio-nomura/7c76756f9827d16d40a1)

うーん、、**Swiftのアセンブリ出力は難しい。**　もうちょっと簡単な方法はないか？と`swiftc`の`-emit-sil`を試す。

`swift-demangle-filter.py -emit-sil indexof.swift -o indexof.sil`

[indexof.sil](https://gist.github.com/norio-nomura/f95c5921484da4a55242)

うーん、少し分かりやすくなったかな。あ、最適化オプション-O付け忘れてた。

`swift-demangle-filter.py -emit-sil -O indexof.swift -o indexof-O.sil`

[indexof-O.sil](https://gist.github.com/norio-nomura/e30c5450acfbc0bbf9d9)

あれ？なんか出力がやたら長くない？

```
// Swift.find <A : Swift.CollectionType>(A, A.Generator.Element) -> Swift.Optional<A.Index>
sil public_external Swift.find <A : Swift.CollectionType>(A, A.Generator.Element) -> A.Index? : $@thin <C where C : CollectionType, C.Generator : GeneratorType, C.Generator.Element : Equatable, C.Index : ForwardIndexType, C.Index.Distance : _SignedIntegerType, C.Index.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out Optional<C.Index>, @in C, @in C.Generator.Element) -> () {
  bb0(%0 : $*Optional<C.Index>, %1 : $*C, %2 : $*C.Generator.Element):
  %3 = alloc_stack $RangeGenerator<C.Index>       // users: %10, %16, %38, %51, %55, %61
  // function_ref Swift.Range.generate <A : Swift.ForwardIndexType>(Swift.Range<A>)() -> Swift.RangeGenerator<A>
  %4 = function_ref Swift.Range.generate <A : Swift.ForwardIndexType>(Swift.Range<A>)() -> Swift.RangeGenerator<A> : $@cc(method) @thin <τ_0_0 where τ_0_0 : ForwardIndexType, τ_0_0.Distance : _SignedIntegerType, τ_0_0.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out RangeGenerator<τ_0_0>, @in Range<τ_0_0>) -> () // user: %10
  %5 = alloc_stack $Range<C.Index>                // users: %9, %10, %12
  // function_ref Swift.indices <A : Swift.CollectionType>(A) -> Swift.Range<A.Index>
  %6 = function_ref Swift.indices <A : Swift.CollectionType>(A) -> Swift.Range<A.Index> : $@thin <τ_0_0 where τ_0_0 : CollectionType, τ_0_0.Generator : GeneratorType, τ_0_0.Index : ForwardIndexType, τ_0_0.Index.Distance : _SignedIntegerType, τ_0_0.Index.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out Range<τ_0_0.Index>, @in τ_0_0) -> () // user: %9
  %7 = alloc_stack $C                             // users: %8, %9, %11
  copy_addr %1 to [initialization] %7#1 : $*C     // id: %8
  %9 = apply %6<C, C.Generator, C.Generator.Element, C.Index, C.Index.Distance, C.Index.Distance.IntegerLiteralType, C.Index._DisabledRangeIndex, C._Element>(%5#1, %7#1) : $@thin <τ_0_0 where τ_0_0 : CollectionType, τ_0_0.Generator : GeneratorType, τ_0_0.Index : ForwardIndexType, τ_0_0.Index.Distance : _SignedIntegerType, τ_0_0.Index.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out Range<τ_0_0.Index>, @in τ_0_0) -> ()
  %10 = apply %4<C.Index, C.Index.Distance, C.Index.Distance.IntegerLiteralType, C.Index._DisabledRangeIndex>(%3#1, %5#1) : $@cc(method) @thin <τ_0_0 where τ_0_0 : ForwardIndexType, τ_0_0.Distance : _SignedIntegerType, τ_0_0.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out RangeGenerator<τ_0_0>, @in Range<τ_0_0>) -> ()
  dealloc_stack %7#0 : $*@local_storage C         // id: %11
  dealloc_stack %5#0 : $*@local_storage Range<C.Index> // id: %12
  %13 = alloc_stack $Optional<C.Index>            // users: %16, %17, %21, %37, %50, %55, %56
  // function_ref Swift.RangeGenerator.next <A : Swift.ForwardIndexType>(inout Swift.RangeGenerator<A>)() -> Swift.Optional<A>
  %14 = function_ref Swift.RangeGenerator.next <A : Swift.ForwardIndexType>(inout Swift.RangeGenerator<A>)() -> A? : $@cc(method) @thin <τ_0_0 where τ_0_0 : ForwardIndexType, τ_0_0.Distance : _SignedIntegerType, τ_0_0.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out Optional<τ_0_0>, @inout RangeGenerator<τ_0_0>) -> () // users: %16, %55
  // function_ref Swift._doesOptionalHaveValue <A>(inout Swift.Optional<A>) -> Builtin.Int1
  %15 = function_ref Swift._doesOptionalHaveValue <A>(inout A?) -> Builtin.Int1 : $@thin <τ_0_0> (@inout Optional<τ_0_0>) -> Builtin.Int1 // users: %17, %56
  %16 = apply %14<C.Index, C.Index.Distance, C.Index.Distance.IntegerLiteralType, C.Index._DisabledRangeIndex>(%13#1, %3#1) : $@cc(method) @thin <τ_0_0 where τ_0_0 : ForwardIndexType, τ_0_0.Distance : _SignedIntegerType, τ_0_0.Distance.IntegerLiteralType : _BuiltinIntegerLiteralConvertible> (@out Optional<τ_0_0>, @inout RangeGenerator<τ_0_0>) -> ()
  %17 = apply [transparent] %15<C.Index>(%13#1) : $@thin <τ_0_0> (@inout Optional<τ_0_0>) -> Builtin.Int1 // user: %18
  cond_br %17, bb1, bb2                           // id: %18

  bb1:                                              // Preds: bb0 bb4
```

これって、**Swift標準ライブラリの中身も[出力](https://gist.github.com/norio-nomura/e30c5450acfbc0bbf9d9#file-indexof-o-sil-L684-L764)されてる！**

ふむふむ、なるほど。で`find()`の実装を参考にしたらこうなった。

```swift
func v2_1_index_of<C : CollectionType where C.Generator.Element : Equatable>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
  for idx in indices(domain) {
    if condition(domain[idx]) {
      return idx
    }
  }
  return nil
}
```

で、ベンチマークは

> <unknown>:0: Test Case '-[Benchmark.Benchmark testPerformance_v1]' measured [Time, seconds] average: 1.557,…

> <unknown>:0: Test Case '-[Benchmark.Benchmark testPerformance_v2_1]' measured [Time, seconds] average: 1.057,…

> <unknown>:0: Test Case '-[Benchmark.Benchmark testPerformance_v4]' measured [Time, seconds] average: 2.403,…

**おお！`lazy()`版より速くなった！**

# まとめ

**`swiftc -emit-sil -O`にはSwift標準ライブラリの中身も出力されるので、暇な人は読んでみよう！**

---

[@norio_nomura](https:/twitter.com/norio_nomura)
