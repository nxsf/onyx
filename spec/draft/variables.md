# Variables

## Declaration

Can be `decl let`; it would require `def let`, `impl let` or simply `def let`.
In traits, `let x` is implicitly `def let undefstor x`, which is a error.
So it requires either `decl let x` or `let static x`.

```nx
# A) Restricting an lvalue assumes it's a reference,
# e.g. `x : T` === `x : T&r`.
# Does not work on rvalues, e.g. `not 42 :? SInt32&`.
# Well, declaring a varible could've used just `T`.

let x : T

# B) Restriction always requires exact type, e.g. `x : T&`.

let x : SInt32
let (x, foo: y) : FBin64, bar: z : SInt32 = ((0.1, foo: 0.2), bar: 1)
let x, y = [1, 2]

final x, y = [1, 2]
let x, y = <1, 2>
get x, y = (1, 2)

let a: x, get y: b = (b: 2, a: 1)
a: x, y: b = strukt # Must have `.a : T` and `.b : T` methods

# Assignability is preserved,
# but type restriction is not
let x: a : T, (let) (require alias or index!) b (: U)
let x, final y === let (x, final y) !== let ((x, final y))
let ((x, final y)) = ((1, 2)) # OK

# let res, err = (err: 0, res: 1) # Nope
let res: r, err: @ = (err: 0, res: 1) # OK, `r` and `err`

foo(alias: T) === foo(alias: : T) !== foo(arg : T) === foo(arg: arg : T)
```

## Definition

A.k.a. implementation.
Can not safely make use of undefined variables.
Can not safely take address of an undefined variable.
Definition means assigning a meaningful value to a variable,
however sometimes it's not required (see instance variables).
Can unsafely assign to an `uninitialized` value.

## Storage

In traits, variables can be declared with undefined storage.
Other way, it's implicit depending on the containing object (instance for classes, static otherwise).
If SMT feature is enabled, operations on non-local variables are fragile.

### Static

Static variables always have defined memory, they can not be moved.
Static variables are not inherited upon extension or derivation.
Static variables are `def` by default, thus requiring a value.
Can have an undefined variable, but there is no guarantee that
it would be defined at the moment of accessing it?
Theoretically, a compiler could infer the actual definition state from
the code flow (i.e. the order of function calls)?

### Instance

Instance variables are implicitly `decl` if not having a value.
An undefined instance variable must be defined in an initializer.
A pointer to an instance variable has instance storage,
which is coerced upon exiting the instance scope by the caller
(which depends on the storage of the callee object).

### Local

Can not return a pointer to local variable.
Local variable operations are always threadsafe.
Local variable is implicitly `decl let` if no value is given.
`let x = 2` is implciitly `def let x = 2`.
Can only move a local variable.

## Assignability

Variables declared with `let` can be re-assigned after definition.
`final` variables can not.
From the caller's point of view, variables declared with `get`
are not assignable from the outer scope.
However, `get` vars are assignable within the object itself.
It is achieved with getter method visibility overloading.
Ditto to `set`.
Basically, `let` is combination of `get` and `set`.x

## Lifetime

Instance variable lifetime spans to the object's.
Local variable lifetime spans to the containing function's.
When assigning to a defined variable, the old object is finalized.
Can do a push-assign; `<=<` is defined for all variables.
Only class instances have lifetime.

## Lval & Rval

A reference is lval; anything else is rval.
Lval can be implicitly cast to rval.
The dereference operator turns a pointer (rval or lval) into lval.
Can only dereference a pointer with defined storage, returning a reference with the same storage.
Taking an address of a reference returns a pointer to the original variable.

```nx
alias T = SInt32 # For brevity

(let i: T = 42 : T) : T&lrw         # `i` itself
(final p = &i : T*lrw) : (T*lrw)&lr # Pointer to `i`

&p : (T*lrw)*lr  # Pointer to `p`
*p : T&lrw       # Reference to `i`
&*p : T*lrw      # Pointer to `i`
*&p : (T*lrw)&lr # Reference to `p`

# **p # Panic! Can not reference a reference
# &&p # Panic! Can not take an address of an rval

(final pp: (T*lrw)*lr = &p : (T*lrw)*lr) : ((T*lrw)*lr)&lr # Pointer to `p`

*pp : (T*lrw)&lr # Reference to `p`
**pp : T&lrw     # Reference to `i`
&pp : ((T*lrw)*lr)*lr # Pointer to `pp`

# ***pp # Panic! Can not reference a reference
# &&pp  # Panic! Can not take an address of an rval
```

## Moving

Moving a ref turns it into an nref.
Only local variables can be safely moved.
Others can be unsafely moved.
There is no separate type for moved objects (e.g. no `(<- T)`).

```nx
x = <- y
x <- y # Shortcut
```

## Swapping

## Assigning

Only refs to defined variables can be assigned to.
Also variables definitions itself are assignments (`let x = 42`).
A simple assignment to a ref returns itself (the ref).
A `x=` method can be defined, and it may return not a ref.

`obj.x = v` lookup:

  1. `(obj).x=(v)`
  1. `((obj).x : T&) = (v)`

When seeing `obj.x += v` expression, the lookup as follows.

  1. `(obj).x+=(v)`
  1. `((obj).x : T).+=(v)`
  1. `(obj).x=((((obj).x) : T).+(v))`
  1. `((obj).x : T&) = (((obj).x : T).+(v))`

## Visibility

## Passing

When passing to a function or a `return`, `break` statement; i.e. moving from the scope.
The variable is copied then, calling `initialize(var : T&cr)`.
If there is no copy-initializer implemented, panics.

```nx
class Foo
  let x: SInt32
  let (x, y): FBin64
  let x, y = tuple # Auto destruction?
```

Can move a local variable instead, or unsafely move a non-local variable.

```nx
@[Trivial]
class Foo
  let x: SInt32
end

final foo = Foo(x: 42)
# final x <- foo.x # Panic! Can not safely move an instance variable
final x = unsafe! <- foo.x # OK
```

## References

```nx
def foo : T
  return (copy : T) # Would work
  # return (ref : T&) # No
  return *ref # OK, same as passing a copy of ref'ed var
end

def bar : T&
  # return (copy : T) # Nope
  return (ref : T&) # OK
  return Ref(copy) # OK
  # return *ref # Nope
end

def baz(arg : T);

baz(copy) # OK
# baz(ref) # Nope
baz(*ref) # OK

def qux(arg : T&);

# qux(copy) # Nope
qux(ref) # OK
#qux(*ref) # Nope
qux(Ref(copy)) # OK
```

Implementing variables creates methods with according reference return types:

```nx
def let x : T;
  def x : T&rw;

def get x : T;
  def x : T&r;
  private def x : T&rw;

def set x : T;
  def x : T&w;
  private def x : T&rw;

def final x : T;
  def x : T&r;
```

Ways to create references:

```nx
let i = 42
final r2 = *&i
final r1 = Ref(i)
# final r3 : Ref = i # No, unlike in C++
```

If a function accepts a read-only reference, then a concrete type may be passed to it. It does not work if function accepts a writeable reference.

```nx
def foo(x : $int&);
foo(42) # OK

def bar(x : $int&w);
# bar(42) # Panic!
```
