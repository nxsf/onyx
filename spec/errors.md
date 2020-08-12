## Errors

A machine-level function may accept a pointer to a backtrace as its first argument implicitly. The first member of a backtrace object must be a pointer to its `write` function implementation, which must accept exactly three `String*sr`, `UInt32` and `UInt32` arguments.

Exceptions are expected to have runtime cost only when there a backtrace to write to. Even when compiling with "each function has a pointer to a backtrace" in mind, then checking if the pointer is null is just a single tick.

```nx
incompl struct Backtrace
  alias Loc = Struct<path: String*sr, row: UInt32, col: UInt32>
  private final rtti : Undef
  decl write(: *Loc)
  decl each(block: :: B) forall B : => |(*Loc)|
  decl size : Size
end

struct MyBacktrace<S : %z>
  final stack = unsafe! uninitialized mut Loc[S]
  get size = 0z

  derive Backtrace
    impl write(loc : *Loc)
      let i = fragile! size ^+= 1
      unless (i == S) fragile! stack[i] = loc
    end

    impl each(block: :: B) forall B : => |(*Loc)|
      size.times => B(*(unsafe! stack.get!(&)))
    end
  end
end

final bt = MyBacktrace<32>()

try with bt
  do_smth() # Passes `&bt` implicitly
catch (e : T)
  bt.each => |(f, r, c)| do
    Std.out << "At %s:%u32:%u32\n" % (f, r, c)
  end
implicit_catch(e)
  # Implicitly write all BT to the parent bt
  if parent_bt
    bt.each => parent_bt->write(**&)
  end

  # Transfer control, return `e`
  throw(e)
end
```

TODO: Although it is possible to throw a type instance, a good practice is to throw actual instances; even if they're zeros-sized.
It should not affect the performance in case of a well-written compiler.
