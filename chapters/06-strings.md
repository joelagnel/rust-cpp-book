## Strings and the Copy Trait
[Back to Table of Contents](#table-of-contents)

In Rust, a `String` does not implement the `Copy` trait because it is a heap-allocated type requiring custom logic for duplication. The `Copy` trait is reserved for simple, fixed-size types that can be duplicated with a bitwise memory copy, such as integers (`i32`, `u64`), floats (`f32`, `f64`), and `bool`.

### Ownership and Passing Strings

Passing a `String` to a function moves its ownership. After the move, the original variable is no longer valid. For example:

```rust
fn take_string(s: String) {
    println!("String received: {}", s);
} // `s` is dropped here

fn main() {
    let my_string = String::from("Hello, Rust!");
    take_string(my_string);
    // println!("{}", my_string); // Compile error: `my_string` is no longer valid
}
```

### Avoiding Ownership Transfer

To prevent moving a `String`, you can either pass a reference or explicitly clone it:

1. **Passing a Reference**:
   ```rust
   fn borrow_string(s: &String) {
       println!("Borrowed string: {}", s);
   }

   fn main() {
       let my_string = String::from("Hello, Rust!");
       borrow_string(&my_string);
       println!("String still valid: {}", my_string);
   }
   ```

2. **Cloning the String**:
   ```rust
   fn take_string(s: String) {
       println!("String received: {}", s);
   }

   fn main() {
       let my_string = String::from("Hello, Rust!");
       take_string(my_string.clone());
       println!("String still valid: {}", my_string);
   }
   ```

### Summary

- The `String` type does not implement `Copy` to ensure efficient memory management.
- Passing a `String` transfers ownership unless you explicitly borrow it or clone it.
- Use references for lightweight access and cloning when independent duplication is required.

### Example Comparison

```rust
fn main() {
    let x = 42; // i32 is Copy
    let y = x;  // Implicit copy
    println!("x: {}, y: {}", x, y);

    let s1 = String::from("hello"); // String is not Copy
    let s2 = s1.clone();            // Explicit clone
    println!("s1: {}, s2: {}", s1, s2);
}
```

\pagebreak
