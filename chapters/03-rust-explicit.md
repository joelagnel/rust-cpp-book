## Rust is Explicit about Programmer Intentions (Ex: Mutability is Explicit)

[Back to Table of Contents](#table-of-contents)

In Rust, variables are immutable by default, and mutability must be explicitly declared.
This contrasts with C, where mutability is implicit, and `const` must be used to enforce
immutability.

### Example

```rust
let mut x = 42; // Explicitly mutable
x += 1;
println!("x is now {}", x);

let y = 42; // Immutable by default
// y += 1; // Compile-time error
```

### C Equivalent

```c
int x = 42;
x += 1; // Mutability is implicit

const int y = 42;
// y += 1; // Compile-time error in C
```

Rust�s design ensures that less safe operations require explicit syntax, aligning with
its philosophy of safety by design.

## Explicit References When Passing Data (even between scopes let alone functions)

In Rust, transferring data between scopes often requires explicit references. Unlike C or C++, Rust has strict ownership rules that prevent data from being "stolen" (move semantics) by inner scopes or inadvertently modified.

### Example

```rust
fn main() {
    let mut v = vec![1, 2, 3];
    // The inner scope has an explicit read-only reference to the entire vector `v`,
    // so it can safely iterate over the vector.
    for x in &v {
        // v[0] = 3; // Uncommenting this fails as v is borrowed as read-only ref
        println!("{}", x);
    }
    // v[0] = 3; // Uncommenting this p asses as v is mutable in outer scope
    println!("Vector is still accessible: {:?}", v);
}
    println!("{}", x);
}
println!("Vector is still accessible: {:?}", v);
```

\pagebreak
