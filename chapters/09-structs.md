## Structs

Structs in rust are similar to C structs. They are used to group together
related data. In rust, structs can have functions similar to class methods
in C++. Here is a simple example:

```rust
struct Circle {
    radius: i32
}

impl Circle {
    fn draw(&self) {
        println!("Circle drawing {}", self.radius);
    }
}

fn main() {
    let c: Circle = Circle { radius: 5 };
    c.draw();
}
```

The `impl` block is used to define the methods for the `Circle` struct.
The struct definition is itself outside the `impl` block and functions
cannot be defined inside the struct definition.

### Structs and the copy trait

By default, structs do not have the `Copy` trait. This means that when
you assign a struct to another variable, the original struct is moved
to the new variable. This is different from C/C++ where the struct is
copied.

Modifying the code above:

```rust
fn main() {
    let c: Circle = Circle { radius: 5 };
    let c1 = c; // copy? no, move!
    c.draw();
    c1.draw();
}
```
Results in the following error:

```rust
Compiling playground v0.0.1 (/playground)
error[E0382]: borrow of moved value: `c`
  --> src/main.rs:16:5
   |
14 |     let c: Circle = Circle { radius: 5 };
   |         - move occurs because `c` has type `Circle`, which does not implement the `Copy` trait
15 |     let c1 = c; // copy? no, move!
   |              - value moved here
16 |     c.draw();
   |     ^ value borrowed here after move
```

To fix this, we need to get the help of the compiler to implement the `Copy` trait for our struct.

```rust
// Note that Copy trait depends on Clone trait.
#[derive(Copy, Clone)]
struct Circle {
    radius: i32
}
```

Alternatively, if we desire to keep the default move semantics, but add
the ability to `.clone()` the struct, we can do so by implementing just the
`Clone` trait.

```rust
#[derive(Clone)]
struct Circle {
    radius: i32
}

fn main() {
    let c: Circle = Circle { radius: 5 };
    let c1 = c.clone();
    c.draw();
    c1.draw();
}
```