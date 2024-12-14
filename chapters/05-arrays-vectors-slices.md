## Collections

### Arrays vs. Vectors

[Back to Table of Contents](#table-of-contents)

As mentioned earlier, and to be repetitive so that you memorize this, Rust distinguishes between fixed-size arrays (on the stack) and dynamically sized vectors (on the heap). Arrays implement the `Copy` trait if their elements do, while vectors do not.

#### Example
```rust
let arr = [1, 2, 3];
for x in arr {
    println!("{}", x);
} // Arrays are `Copy` by default

let v = vec![1, 2, 3];
for x in &v { // Use a reference for vectors
    println!("{}", x);
}
```

### Buffer Overflow Protection

[Back to Table of Contents](#table-of-contents)

Rust eliminates buffer overflow vulnerabilities by enforcing bounds checks at runtime for dynamic indices.

#### Example

```rust
let v = vec![1, 2, 3];
let index = 4; // Dynamic index
// This will panic at runtime:
// let value = v[index];
```

In C, such access would lead to undefined behavior:

```c
int arr[] = {1, 2, 3};
int value = arr[4]; // Undefined behavior
```

While Rust does allow for unchecked access using unsafe blocks, these are explicitly marked and should be used sparingly.

### Slices as Fat Pointers

[Back to Table of Contents](#table-of-contents)

Rust�s slices provide a lightweight way to reference a subset of an array or vector. Slices are fat pointers, storing metadata alongside the pointer to the underlying array's memory, in the space allocated for the slice.

#### Example

```rust
let arr = [1, 2, 3, 4, 5];
let slice = &arr[1..4]; // Slice from index 1 to 3
println!("Slice: {:?}", slice);
```

Slices ensure that the original array remains unchanged while providing a safe, flexible view of the data.

### Why Explicit References when creating a slice?

The explicit `&` ensures that the array isn�t modified, avoiding potential data races or unexpected behavior while the slice variable is alive. Further, the slice is a reference to the array or a part of it.

---

\pagebreak
