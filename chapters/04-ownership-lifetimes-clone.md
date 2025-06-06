## Ownership, Lifetimes and Cloning
When passing objects to functions, Rust's ownership model ensures that ownership must be explicitly managed. For types that **do not** implement the `Copy` trait, you need to either pass a reference or explicitly clone the object.

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

Note that an array in Rust (as opposed to a Vector) does result in an implicit Copy, much like C++, when passing arrays to functions. This is because elements in an Array are typically allocated in the stack and arrays are fixed size whose size is available at compile time. The compiler then decides to do a full copy when copying these. This happens only if the array's elements have a type with the `Copy` trait, such as `i32`. It is possible to avoid this by passing references to the array if a copy is not desired.

### Another example: Mutable references also don't have Copy trait

There can only be one mutable reference (AKA mutable borrow) on an object at a time. So naturally, assigning one mutable reference to another should invalidate the first one. This is exactly why a mutable reference does not have the `Copy` trait and implies move semantics, I believe this only moves the "pointer" to a new "pointer". The data being moved in this case is the pointer.

For example, the following code will not compile due to the same reason as above.

```rust
fn main() {
    let mut x = 42;
    let ptr2 = &mut x;  // create mutable ref
    let y = ptr2;       // mutable ref moved

    println!("{} {}", y, ptr2);
}
```

Results in the following error:
```rust
error[E0382]: borrow of moved value: `ptr2`
 --> src/main.rs:4:26
  |
2 |     let mut x = 42; let ptr2 = &mut x; let y = ptr2;
  |                         ----                   ---- value moved here
  |                         |
  |                         move occurs because `ptr2` has type `&mut i32`, which does not implement the `Copy` trait
3 |
4 |     println!("{} {}", y, ptr2);
  |                          ^^^^ value borrowed here after move
```

On the other hand, immutable references do have the `Copy` trait! This is because it is safe to have multiple immutable references to the same data.

### Mutable borrows lock out copying

In rust, mutable borrows lock out copying. This is because mutable borrows are exclusive, meaning that once a mutable reference is created, the original value cannot be accessed or copied until the mutable reference goes out of scope. This ensures that the mutable reference is the only way to access the value, preventing data races and ensuring memory safety.

Consider the following example:
```rust
fn main() {
    let mut x = 42;     // x is an i32 which has Copy trait
    x += 1;
    let ptr2 = &mut x;  // mutable borrow means..
    let y = x;          // ..x is inaccessible event for copying

    println!("{} {} {}", x, y, ptr2);
}
```

This results in the following error:
```rust
error[E0503]: cannot use `x` because it was mutably borrowed
 --> src/main.rs:5:13
  |
4 |     let ptr2 = &mut x;  // create mutable ref
  |                ------ `x` is borrowed here
5 |     let y = x;       // mutable ref moved
  |             ^ use of borrowed `x`
6 |
7 |     println!("{} {} {}", x, y, ptr2);
  |                                ---- borrow later used here
```

If ptr2 is not a mutable reference, then the code would compile fine.

Note that this only applies to references, a mutable variable on its own can be copied while it is still in scope.

For example, the following code compiles fine:
```rust
fn main() {
    let mut x = 42;
    let y = x;
    println!("{} {}", x, y);
}
```
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

To summarize, the following table shows which types have the `Copy` trait:

| Type       | Copy Trait | Comment |
| ---------- | ---------- | ------- |
| `i32`      | Yes        |         |
| `mut i32`  | Yes        |         |
| `&i32`     | Yes        |         |
| `&mut i32` | No         | Also locks out access to original variable |
| `[i32; 3]` | Yes        | Array has trait of type of its elements |
| `Vec<i32>` | No         | Because its heap allocated and not fixed size |
| `String`   | No         | Because its heap allocated and not fixed size |

### Mutable ref while alive prevents creation of immutable refs

This is kind of obvious as a mutable ref prevents any access to the underlying data other than when going through the mutable ref. That includes creation of additional refs (even immutable ones).

Immutable refs on the other hand, have no problem being copied into new immutable refs (The immutable ref type itself implements the copy trait allowing its pointer to be copied). However, new mutable refs cannot be created until all immutable refs go out of scope.

### Mutable Aliasing: C++ vs. Rust (with Assembly Code)

Mutable aliasing is a concept where multiple references to the same mutable object can lead to unpredictable results. Rust's **borrow checker** prevents aliasing at compile time, enabling aggressive optimizations. This article compares how C++ and Rust handle mutable aliasing in two scenarios: a general memory aliasing example and a specific case involving vector mutations.

---
#### Scenario 1: General Mutable Aliasing

##### C++ Code

```cpp
void store(const int& source, int& dest) {
    dest = 42;  // Overwrite first
    dest = source;  // Assign source to dest
}
```

In C++, the `store` function allows aliasing, meaning `source` and `dest` could refer to the same memory location. Due to this, the compiler cannot optimize out redundant operations because it cannot guarantee the absence of aliasing.

##### Rust Code

```rust
pub fn store(source: &i32, dest: &mut i32) {
    *dest = 42;  // Overwrite first
    *dest = *source;  // Assign source to dest
}
```

In Rust, the **borrow checker** ensures `source` and `dest` cannot alias. This allows the compiler to optimize out redundant operations, leaving only the necessary instructions.

##### Assembly Outputs: General Mutable Aliasing

###### C++ Assembly Output (Clang, `-O3`)

```asm
store(int const&, int&):
    mov dword ptr [rsi], 42  ; Store 42 into dest
    mov eax, dword ptr [rdi] ; Load value from source
    mov dword ptr [rsi], eax ; Store source into dest
    ret                      ; Return
```

Here, the redundant store (`dest = 42`) cannot be optimized out because `source` and `dest` may alias.

###### Rust Assembly Output (`rustc`, `-C opt-level=3`)

```asm
example::store:
    mov eax, dword ptr [rdi] ; Load value from source
    mov dword ptr [rsi], eax ; Store source into dest
    ret                      ; Return
```

In Rust, the first store (`dest = 42`) is **optimized out** because the compiler knows `source` and `dest` cannot alias.

---

#### Scenario 2: Aliasing in Vector Mutations

##### C++ Code: Mutable Aliasing Allowed

```cpp
#include <vector>

void push_int_twice(std::vector<int>& v, const int& n) {
    v.push_back(n);
    v.push_back(n);
}

int main() {
    std::vector<int> my_vector = {0};
    const int& my_int_reference = my_vector[0];
    push_int_twice(my_vector, my_int_reference);
    return 0;
}
```

In C++, this code compiles and runs but risks **undefined behavior**. When `v.push_back(n)` is called, the vector may reallocate its storage, invalidating the reference `my_int_reference`.

##### Rust Code: Borrow Checker Prevents Aliasing

```rust
fn push_int_twice(v: &mut Vec<i32>, n: &i32) {
    v.push(*n);
    v.push(*n);
}

fn main() {
    let mut my_vector = vec![0];
    let my_int_reference = &my_vector[0];
    push_int_twice(&mut my_vector, my_int_reference); // Error!
}
```

In Rust, this code **does not compile**. Rust's **borrow checker** ensures safety by preventing simultaneous mutable and immutable borrows of `my_vector`.

---

##### Rust Compiler Error

```plaintext
error[E0502]: cannot borrow `my_vector` as mutable because it is also borrowed as immutable
  --> src/main.rs:12:20
   |
11 |     let my_int_reference = &my_vector[0];
   |                            ----------------- immutable borrow occurs here
12 |     push_int_twice(&mut my_vector, my_int_reference);
   |                    ^^^^^^^^^^^^^^ mutable borrow occurs here
13 | }
   | - immutable borrow later used here
```

The compiler detects that `my_vector` is immutably borrowed by `my_int_reference` and refuses to allow a mutable borrow (`&mut my_vector`) in `push_int_twice`.

##### Why This Matters: Undefined Behavior in C++

In C++, the same code runs without errors but introduces subtle bugs:
1. The call to `v.push_back(n)` may reallocate the vector's storage.
2. Reallocation invalidates all existing references, including `my_int_reference`.
3. Subsequent usage of `my_int_reference` results in **undefined behavior**.

Rust eliminates this class of bugs at compile time by ensuring:
- Mutable and immutable borrows cannot coexist.
- References to elements in a vector remain valid during mutation.


This comparison highlights how Rust's **borrow checker** eliminates aliasing issues at compile time, guaranteeing both safety and performance. In contrast, C++ allows mutable aliasing but requires developers to manually ensure references remain valid. Rust's approach prevents subtle, hard-to-debug runtime errors while enabling aggressive optimizations for safe, predictable code.


#### Scenario 3: Mutable Aliasing in Parallel Loops

##### C++ Code: Mutable Aliasing in `std::for_each`

```cpp
#include <vector>
#include <algorithm>

int main() {
    std::vector<int> my_vector = {1, 2, 3, 4};
    int sum = 0;

    std::for_each(my_vector.begin(), my_vector.end(), [&sum](int& x) {
        sum += x;  // Mutable aliasing of `sum`
        x *= 2;    // Simultaneously mutates `x`
    });

    return sum;  // Undefined behavior may occur in parallel execution
}
```

In C++:
- The lambda function passed to `std::for_each` creates a mutable alias to `sum`.
- Simultaneously, it mutates the elements of the vector (`x`).
- This behavior works fine in sequential execution but leads to **race conditions** or undefined behavior in **parallel execution** contexts, such as `std::for_each(std::execution::par)`.

---

##### Rust Code: Borrow Checker Prevents Unsafe Aliasing

```rust
use rayon::prelude::*;

fn main() {
    let mut my_vector = vec![1, 2, 3, 4];
    let mut sum = 0;

    my_vector
        .par_iter_mut()
        .for_each(|x| {
            sum += *x; // Compiler error: Cannot mutably borrow `sum` and `my_vector` simultaneously
            *x *= 2;   // Mutates the vector
        });

    println!("Sum: {}", sum);
}
```

**Rust Compiler Error:**
```plaintext
error[E0503]: cannot use `sum` because it was mutably borrowed
 --> src/main.rs:9:13
  |
8 |     my_vector
  |     --------- mutable borrow occurs here
9 |             sum += *x; // Compiler prevents aliasing
  |             ^^^^^^^^^ use of `sum` after mutable borrow
10 |             *x *= 2;
  |             -------- mutable borrow later used here
```

In Rust:
- The **borrow checker** prevents simultaneous mutable aliasing of `sum` and the elements of `my_vector`.
- The compiler enforces thread safety by disallowing operations that could lead to race conditions or undefined behavior.

---

##### Why Rust Avoids Aliasing in Parallel Loops

C++ allows mutable aliasing, meaning `sum` and `x` can be aliased and mutated simultaneously. If the loop is parallelized using `std::for_each(std::execution::par)`, this results in **race conditions** and undefined behavior.

Rust's approach ensures:
1. **No data races**: The borrow checker prevents mutable aliasing between `sum` and `my_vector`. It also prevents multiple threads mutating sum at the same time which could cause the "lost update" problem.
2. **Thread safety**: Parallel iterators (`par_iter_mut`) enforce safe, isolated access to vector elements.

Rust's borrow checker ensures that code is **safe and race-free** in parallel contexts. By disallowing mutable aliasing, Rust prevents subtle, hard-to-debug bugs that might appear in parallelized C++ code. This guarantees that parallel loops in Rust are both safe and efficient.

### References Prevent Moving

Rust has strict rules about references to ensure memory safety, particularly when dealing with borrowing and moving objects. This section contrasts **C++** and **Rust** with two examples to demonstrate how Rust's rules prevent invalid memory access.

---

#### 1. Borrowing Prevents Moving (String View Example)

**C++ Example:**

```cpp
#include <string>
#include <string_view>
#include <iostream>

int main() {
    std::string s1 = "abcde";
    std::string_view my_view = s1; // Borrow the string as a view
    std::string s2 = std::move(s1); // Move `s1` to `s2`
    std::cout << my_view << std::endl; // Access my_view
}
```

In C++:
- After moving `s1` to `s2`, the `std::string_view my_view` becomes invalid because it points to the memory of `s1`, which is now in an undefined state.
- This causes **undefined behavior** when `my_view` is accessed, even though the code does compile!

---

**Rust Example:**

```rust
fn main() {
    let s1 = "abcde".to_string();
    let my_view = s1.as_str(); // Borrow the string
    let s2 = s1;               // Move `s1` to `s2`
    dbg!(my_view);             // Attempt to access `my_view`
}
```

**Compiler Error:**
```plaintext
error[E0505]: cannot move out of `s1` because it is borrowed
 --> src/main.rs:5:14
  |
4 |     let my_view = s1.as_str(); // Borrow of `s1` occurs here
  |                    ---------- borrow of `s1` occurs here
5 |     let s2 = s1;              // Move out of `s1` occurs here
  |              ^^ move out of `s1` occurs here
6 |     dbg!(my_view);            // Borrow later used here
  |          ------- borrow later used here
```

In Rust:
- The borrow checker ensures `s1` cannot be moved while it is still borrowed by `my_view`.
- This prevents accessing invalid memory and guarantees safety.

---

#### 2. Moving Behind a Mutable Reference Is Not Allowed

**C++ Example:**

```cpp
#include <string>
#include <iostream>

void f(std::string& s1) {
    std::string s2 = std::move(s1); // Move `s1` to `s2`
    std::cout << s2 << std::endl;   // Use `s2`
}

int main() {
    std::string s1 = "foo";
    f(s1);                          // Pass `s1` by reference
    std::cout << s1 << std::endl;   // Use `s1` after it has been moved
}
```

In C++:
- `std::move(s1)` moves the contents of `s1` to `s2`. After this, `s1` is in an undefined state, but the program still attempts to use it.
- This can lead to undefined behavior.

---

**Rust Example:**

```rust
fn f(s1: &mut String) {
    let s2 = *s1;         // Attempt to move `s1` through a mutable reference
    dbg!(s2);
}

fn main() {
    let mut s1 = "foo".to_string();
    f(&mut s1);          // Pass `s1` as a mutable reference
    dbg!(s1);
}
```

**Compiler Error:**
```plaintext
error[E0507]: cannot move out of `*s1` which is behind a mutable reference
 --> src/main.rs:2:14
  |
2 |     let s2 = *s1;         // Attempt to move `s1` through a mutable reference
  |              ^^^ move occurs because `*s1` has type `String`, which does not implement the `Copy` trait
```

In Rust:
- The compiler prevents moving `s1` through a mutable reference, as it would leave the referenced value in an undefined state.
- This ensures `s1` remains valid for further use after the function call.

---

#### Key Takeaways

- **C++**: Allows unsafe operations like moving an object that is still borrowed, leading to undefined behavior.
- **Rust**: Enforces strict rules with its borrow checker, ensuring references remain valid and preventing accidental moves behind references.
- Rust's approach guarantees memory safety and prevents hard-to-debug runtime errors.

### Lifetime annotations with a practical example

Rust's lifetime annotations provide a way to explicitly indicate how references relate to each other in terms of their lifetimes, ensuring safe memory access. This avoids dangling references.

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

\pagebreak
