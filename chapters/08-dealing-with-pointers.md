## Dealing with Pointers

### The dereference operator (`*`)

The dereference operator is used to access the data value pointed to by a reference (a pointer).

```rust
let mut x = 42;
let ptr = &mut x;
println!("Value: {}", *ptr); // 42
```

Coming from C/C++, the dereference operator is a bit confusing. Because the
following code also gives the same output:

```rust
let mut x = 42;
let ptr = &mut x;
println!("Value: {}", ptr); // 42
```

This is because of a feature called auto-dereferencing. The compiler will
automatically dereference the pointer since it knows the intention is to access
the value of the pointer.

#### Why then do you need the `*` operator?

One reason is manipulation of the data. For example, if you want to increment
the value of the pointer, you need to use the `*` operator.

```rust
let mut x = 42;
let ptr = &mut x;
/* not using a star gives "error[E0368]: binary assignment
   operation `+=` cannot be applied to type &mut {integer}" */
*ptr += 1;
println!("Value: {}", x); // 43
```

Auto-dereference is not applicable to all types, but many types such as
`Box` which implement the `Deref` trait support it.

### The rust unique pointer: Box

The `Box` type is a smart pointer that allocates memory on the heap and
deallocates it when the `Box` goes out of scope.

```rust
let x = Box::new(42);
println!("Value: {}", *x); // 42
```

Much like smart pointers in C++, memory allocated on the heap is automatically deallocated when the `Box` goes out of scope.

The `Box` type is actually equivalent to a unique pointer in C++.


```rust
// In C++ this would be:
// std::unique_ptr<int> x = std::make_unique<int>(42);
let x = Box::new(42);

// In C++ this would be:
// std::unique_ptr<int> boxed_y = std::move(boxed_x);
let y = x; // x is moved to y, x is now invalid

println!("Value: {}", x); // error: borrow of moved value: x
```
At any given time, there can only be one unique owner of the data
represented by a `Box`.
When you assign a `Box` to another variable, the original `Box`
is moved to the new variable.

When you create a copy of the `Box`, the location of the data
is also duplicated essentially creating two unique owners of
different data.

The following example illustrates this:
```rust
let mut x = Box::new(42);
let mut y = x.clone();

*y += 1;
println!("Value: {}", *y); // 43
println!("Value: {}", *x); // 42
```
We will see later that when cloning Rust's equivalent of C++'s
shared pointers, however, the data is not duplicated but a new
reference to the same data is created.

### Sharted pointers in Rust
TBD

### How to allocate arbitrary sized memory on the heap
TBD

### Raw pointers
TBD

### Pointer casting
TBD
