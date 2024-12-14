# Rust for C and C++ programmers

## Table of Contents
- [Rust is Explicit about Programmer Intentions](#rust-is-explicit-about-programmer-intentions-ex-mutability-is-explicit)
- [Explicit References When Passing Data](#explicit-references-when-passing-data-even-between-scopes-let-alone-functions)
- [Ownership, Lifetimes and Cloning](#ownership-lifetimes-and-cloning)
- [Arrays vs. Vectors](#arrays-vs-vectors)
- [Buffer Overflow Protection](#buffer-overflow-protection)
- [Strings and the Copy Trait](#strings-and-the-copy-trait)
- [Slices as Fat Pointers](#slices-as-fat-pointers)
- [Traits in Rust vs. Interfaces in C++](#traits-in-rust-vs-interfaces-in-c)

If you are a C or C++ programmer looking to explore Rust, you might find some of its concepts both familiar and distinctively novel. Rust emphasizes safety, explicitness, and modern programming paradigms, often in ways that differ significantly from C or C++. Here, we'll walk through key concepts with examples to help one make the transition. Note that there are many excellent articles in this spirit, however this is my own that I wrote during my journey, which helps someone like me (a kernel or low-level systems programmer). It is expected that the reader is already familiar with some basic rust syntax.

## Rust is Explicit about Programmer Intentions (Ex: Mutability is Explicit)

[Back to Table of Contents](#table-of-contents)

In Rust, variables are immutable by default, and mutability must be explicitly declared. This contrasts with C, where mutability is implicit, and `const` must be used to enforce immutability.

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

Rust’s design ensures that less safe operations require explicit syntax, aligning with its philosophy of safety by design.

## Explicit References When Passing Data (even between scopes let alone functions)

[Back to Table of Contents](#table-of-contents)

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

## Ownership, Lifetimes and Cloning
[Back to Table of Contents](#table-of-contents)

When passing objects to functions, Rust’s ownership model ensures that ownership must be explicitly managed. For types that **do not** implement the `Copy` trait, you need to either pass a reference or explicitly clone the object.

### Example:  Passing Vectors implies move semantic as Vector doesn't have Copy trait

```rust
fn print_vector(v: Vec<i32>) {
    println!("{:?}", v);
}

let v = vec![1, 2, 3];
print_vector(v); // Ownership is moved
// println!("{:?}", v); // Compile-time error: `v` no longer accessible

let v = vec![1, 2, 3];
print_vector(v.clone()); // Clone explicitly
println!("{:?}", v); // `v` is still accessible
```

#### Comparison with other languages

C++ to its credit also has move semantics, but the std::move has to be specified otherwise the entire vector is copied. This is obviously less efficient. Rust with its focus on efficiency assumes std::move as the right thing to do.

```cpp
std::vector<int> v = {1, 2, 3};
printVector(std::move(v)); // Ownership moved
// v is now in an unspecified state.
```

But Java is worse, mutable vectors are passed implicitly which though efficient is prone to ownership issues

```java
List<Integer> list = Arrays.asList(1, 2, 3);
modifyList(list);
// `list` is still accessible after the function and potentially modified.
```

Note that an array in Rust (as opposed to a Vector) does result in an implicit Copy, much like C++, when passing arrays to functions. This is because elements in an Array are typically allocated in the stack and arrays are fixed size whose size is available at compile time. The compiler then decides to do a full copy when copying these. This happens only if the array's elements have a type with the `Copy` trait, such as \`i32\`. It is possible to avoid this by passing references to the array if a copy is not desired.

### Cloning vs Copying

In Rust, `clone` and `copy` are distinct mechanisms for duplicating values:

1. **Copy Trait**:
   - For simple, stack-allocated types (e.g., integers, floats, `bool`), `Copy` provides implicit, cheap duplication by copying memory.
   - Example:

```rust
fn main() {
    let a = 42;
    let b = a; // `a` is still valid
    println!("a: {}, b: {}", a, b);
}
```

2. **Clone Trait**:
   - For complex types like `String` or `Vec`, `Clone` requires an explicit `.clone()` call and allows custom duplication logic.
   - Example:

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1.clone();
    println!("s1: {}, s2: {}", s1, s2);
}
```

| **Aspect**   | **Copy**                  | **Clone**                        |
| ------------ | ------------------------- | -------------------------------- |
| **Behavior** | Implicit, cheap           | Explicit, customizable           |
| **Use Case** | Simple, lightweight types | Complex, resource-managing types |

#### When to Use which

- Use `Copy` for small, fixed-size types like numbers.
- Use `Clone` for heap-allocated or resource-heavy types when deep copies are needed.

### Lifetime annotations with a practical example

[Back to Table of Contents](#table-of-contents)

Rust's lifetime annotations provide a way to explicitly indicate how references relate to each other in terms of their lifetimes, ensuring safe memory access.

Consider the following practical example:

```rust
struct Account(String);
struct Order<'a> {
    lock: &'a Account,
    // Presumably other fields too
}

fn order_example<'a>() -> Order<'a> {
    let tris = Account("tris".into());
    Order { lock: &tris }
}
```

#### Explanation of the issue

`Order<'a>` indicates that the Order struct has a reference to an Account with the same lifetime `'a`, ensuring that the Account outlives the Order struct to prevent dangling references. In the function `order_example<'a>`, which returns an `Order<'a>`, the reference `&tris` in `Order { lock: &tris }` becomes invalid because tris is dropped at the end of the function scope. Rust enforces this by throwing a compile-time error: cannot return reference to local variable. Lifetimes are crucial because they help the Rust compiler guarantee that references do not outlive the data they point to. In this case, returning a reference to a local variable like tris is unsafe because it gets deallocated when the function exits.

#### Fixing the Example:

To fix this issue, the `Account` object must have a longer lifetime, such as being allocated on the heap or being part of a higher scope:

```rust
fn order_example<'a>(account: &'a Account) -> Order<'a> {
    Order { lock: account }
}

fn main() {
    let account = Account("tris".into());
    let order = order_example(&account);
    // Now both `account` and `order` have compatible lifetimes.
}
```

This adjustment ensures that the `account` outlives the `order`, adhering to Rust's strict ownership and borrowing rules.

## Arrays vs. Vectors

[Back to Table of Contents](#table-of-contents)

As mentioned earlier, and to be repetitive so that you memorize this, Rust distinguishes between fixed-size arrays (on the stack) and dynamically sized vectors (on the heap). Arrays implement the `Copy` trait if their elements do, while vectors do not.

### Example

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

## Buffer Overflow Protection

[Back to Table of Contents](#table-of-contents)

Rust eliminates buffer overflow vulnerabilities by enforcing bounds checks at runtime for dynamic indices.

### Example

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

## Slices as Fat Pointers

[Back to Table of Contents](#table-of-contents)

Rust’s slices provide a lightweight way to reference a subset of an array or vector. Slices are fat pointers, storing metadata alongside the pointer to the underlying array's memory, in the space allocated for the slice.

### Example

```rust
let arr = [1, 2, 3, 4, 5];
let slice = &arr[1..4]; // Slice from index 1 to 3
println!("Slice: {:?}", slice);
```

Slices ensure that the original array remains unchanged while providing a safe, flexible view of the data.

### Why Explicit References when creating a slice?

The explicit `&` ensures that the array isn’t modified, avoiding potential data races or unexpected behavior while the slice variable is alive. Further, the slice is a reference to the array or a part of it.

---

## Traits in Rust vs. Interfaces in C++

[Back to Table of Contents](#table-of-contents)

Rust’s traits and C++’s interfaces (often implemented via pure virtual classes) serve a similar purpose: enabling polymorphism and defining shared behavior. However, the implementation and usage of these concepts differ significantly.

### Rust Traits Example

```rust
trait Drawable {
    fn draw(&self);
}

struct Circle;
impl Drawable for Circle {
    fn draw(&self) {
        println!("Drawing a Circle");
    }
}

struct Square;
impl Drawable for Square {
    fn draw(&self) {
        println!("Drawing a Square");
    }
}

fn render(object: &dyn Drawable) {
    object.draw();
}

fn main() {
    let circle = Circle;
    let square = Square;

    render(&circle);
    render(&square);
}
```

For the C developer, the `struct Circle;` and `struct Square;` are called "empty structs" or "unit structs" in Rust, like` struct Circle { }` in C++. The semicolon at the end indicates it's a unit struct with no body.

This code shows how Rust uses traits to define shared behavior (`Drawable`) and dynamic dispatch to call the appropriate method implementation.

### C++ Interfaces Example

```cpp
#include <iostream>

class Drawable {
public:
    virtual void draw() const = 0; // Pure virtual function
    virtual ~Drawable() {} // Virtual destructor
};

class Circle : public Drawable {
public:
    void draw() const override {
        std::cout << "Drawing a Circle";
    }
};

class Square : public Drawable {
public:
    void draw() const override {
        std::cout << "Drawing a Square";
    }
};

void render(const Drawable& object) {
    object.draw();
}

int main() {
    Circle circle;
    Square square;

    render(circle);
    render(square);
}
```

### Other Key Differences in Rust traits versus C++ interfaces

#### Flexibility

Rust traits can be implemented for types retroactively (e.g., implementing a trait for a type that is defined by a library ). For instance, consider a type `ExternalType` that is defined by an external library. You can simply implement `greet` for them in your code.

##### Rust Example

```rust
trait Greet {
    fn greet(&self);
}

// Imagine this type is from an external library you can't modify
struct ExternalType;

impl Greet for ExternalType {
    fn greet(&self) {
        println!("Hello from an external type!");
    }
}

fn main() {
    let ext = ExternalType;
    ext.greet(); // Works because we implemented the Greet trait
}
```

In contrast, C++ requires creating wrappers to do the same thing, limiting flexibility:

##### C++ Example

```cpp
#include <iostream>

class Greet {
public:
    virtual void greet() const = 0;
};

// External class, cannot modify it
class ExternalType {
    // No native support for interfaces
};

class ExternalTypeWrapper : public ExternalType, public Greet {
public:
    void greet() const override {
        std::cout << "Hello from an external type!" << std::endl;
    }
};

int main() {
    ExternalTypeWrapper ext;
    ext.greet();
}
```

While Rust allows retroactive implementation through traits, C++ needs additional boilerplate.

#### Functions that accept "trait objects" and their automatic memory management

It is possible to write a generic function in rust that accepts objects with certain traits (similar to how a C++ function might accept an object which is derived from an abstract base class.

Extending our earlier example, in Rust:

```rust
fn render(object: &dyn Drawable) {
    object.draw();
}
```

And in C++:

```cpp
void render(const Drawable& object) {
    object.draw();
}
```

These functions accept both Circle and Rectangles as they both have `draw()`.

BUT, with Rust, we have automatic garbage collection of these dynamic dispatch objects. Rust’s ownership model ensures that dynamically dispatched objects (e.g., `&dyn Drawable`) are properly managed, reducing risks of memory leaks. C++ on the other hand requires explicit handling (e.g., virtual destructors) to manage lifetimes. See the full example of this below.

##### Rust Example

```rust
trait Drawable {
    fn draw(&self);
}

struct Circle;
impl Drawable for Circle {
    fn draw(&self) {
        println!("Drawing a Circle");
    }
}

fn render(object: &dyn Drawable) {
    object.draw();
}

fn main() {
    let circle = Circle;
    render(&circle);
}
```

##### C++ Example

```cpp
#include <iostream>

class Drawable {
public:
    virtual void draw() const = 0;
    virtual ~Drawable() {}
};

class Circle : public Drawable {
public:
    void draw() const override {
        std::cout << "Drawing a Circle";
    }
};

void render(const Drawable& object) {
    object.draw();
}

int main() {
    Circle circle;
    render(circle);
}
```

Rust’s trait system provides a safer and more flexible approach to polymorphism, making it a robust alternative for systems programming.

---

Rust introduces a paradigm shift for C programmers by prioritizing safety and explicitness. While this might seem restrictive initially, these features significantly reduce bugs and undefined behaviors, making Rust an excellent choice for robust and maintainable systems programming.