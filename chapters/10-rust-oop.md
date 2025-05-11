# **Rust’s Object-Oriented Programming Approach Compared to C++**

Rust approaches OOP differently, addressing many pitfalls of traditional OOP design, particularly those in C++. Let’s explore how Rust's principles of **safety, simplicity, and explicitness** compare to C++’s traditional OOP model.

---

## **1. Object Construction: Explicitness vs Implicit Complexity**

### **C++ Shortcomings**
In C++, constructors handle object initialization. While convenient, they introduce pitfalls:
1. **Hidden Logic and Complexity**:
   - Constructors in C++ often hide logic, making them opaque and hard to debug. Special rules (e.g., constructor order and virtual functions) increase complexity.
   - Example:
     ```cpp
     class Person {
         virtual void introduce() { std::cout << "I'm a person"; }
         Person() { introduce(); } // Calls base version, not derived.
     };
     class Employee : public Person {
         void introduce() override { std::cout << "I'm an employee"; }
     };
     Employee e; // Output: "I'm a person"
     ```
2. **Half-baked objects**:
   - Missing field initialization in a constructor can result in undefined behavior:
     ```cpp
     class Person {
         int age;
         Person(int a) {} // Forgot to initialize `age`
     };
     Person p(25); // `age` contains garbage.
     ```

### **Rust's Solution**
Rust avoids constructors entirely and uses **explicit initialization** with safety guarantees.
- **Explicit field initialization** ensures all fields are initialized:
  ```rust
  struct Person {
      age: u32,
  }
  let p = Person { age: 25 }; // All fields must be specified.
  ```
- For flexibility, Rust offers **associated functions** like `new()`:
  ```rust
  impl Person {
      fn new(age: u32) -> Self {
          Person { age }
      }
  }
  let p = Person::new(25);
  ```
  **Why `new()` is just a regular function:**
  - Unlike constructors in C++, `new()` is not special or implicit. It is simply a conventionally named function.
  - **Benefits**:
    1. Developers see all the initialization logic explicitly.
    2. Initialization can be customized for different contexts by defining multiple associated functions.
    3. Error handling is straightforward using Rust’s `Result` type:
       ```rust
       impl Person {
           fn new(age: u32) -> Result<Self, String> {
               if age < 0 {
                   Err("Age cannot be negative".to_string())
               } else {
                   Ok(Person { age })
               }
           }
       }
       ```
       Note that returning an error from a C++ constructor is impossible. Constructors don't
       have a return type. The only way is to throw an exception but that adds complexity and
       requires exception handling.
---

## **2. Inheritance vs Composition**

### **C++ Shortcomings**
C++ relies heavily on inheritance for code reuse, but this comes with significant challenges:
1. **Fragile Base Classes**:
   - Changes to base classes can unintentionally break derived classes.
2. **Constructor Chains**:
   - Complex hierarchies can lead to unpredictable behaviors and difficult debugging.
3. **Virtual Function Pitfalls**:
   - Virtual functions called during base class construction behave unexpectedly:
     ```cpp
     class Person {
         virtual void introduce() { std::cout << "I'm a person"; }
         Person() { introduce(); } // Calls base version, not derived.
     };
     class Employee : public Person {
         void introduce() override { std::cout << "I'm an employee"; }
     };
     Employee e; // Output: "I'm a person"
     ```

### **Rust's Approach**
Rust prioritizes **composition over inheritance**, offering **traits** for shared behavior.
- **Trait-based polymorphism**:
  ```rust
  trait Introduce {
      fn introduce(&self);
  }
  struct Person {
      name: String,
  }
  struct Employee {
      person: Person,
      job: String,
  }
  impl Introduce for Person {
      fn introduce(&self) {
          println!("I'm a person named {}", self.name);
      }
  }
  impl Introduce for Employee {
      fn introduce(&self) {
          println!("I'm an employee named {}", self.person.name);
      }
  }
  ```
- **Struct Composition**:
  By embedding one struct within another, Rust avoids fragile hierarchies and ensures behavior is well-defined.

---

## **3. Default Initialization**

### **C++ Shortcomings**
C++ constructors often rely on implicit default initialization, which can lead to **uninitialized variables**:
```cpp
class Person {
    int age; // Uninitialized unless explicitly set.
};
Person p; // `age` contains garbage.
```

### **Rust's Solution**
Rust enforces explicit initialization or uses the **`Default` trait**:
```rust
#[derive(Default)]
struct Person {
    age: u32,
}
let p = Person::default(); // All fields are initialized to defaults.
```
Rust eliminates ambiguity by requiring explicit calls to default initializers.

---

## **4. Error Handling**

### **C++ Shortcomings**
C++ uses exceptions for errors in constructors, creating **hidden failure modes** that must be explicitly caught:
```cpp
class Person {
    Person(int age) {
        if (age < 0) throw std::invalid_argument("Age cannot be negative");
    }
};
```

### **Rust's Solution**
Rust uses `Result` and forces callers to handle errors, making error states explicit:
```rust
impl Person {
    fn new(age: u32) -> Result<Self, String> {
        if age < 0 {
            Err("Age cannot be negative".to_string())
        } else {
            Ok(Person { age })
        }
    }
}
match Person::new(25) {
    Ok(person) => println!("Person created successfully"),
    Err(err) => println!("Error: {}", err),
}
```

---

## **Interesting Facts About Rust's OOP Model**
- Rust’s **traits** combine the best aspects of interfaces and abstract classes, enabling clean polymorphism.
- By avoiding inheritance, Rust sidesteps problems related to inheritance, like the **diamond problem**.

TODO: Insert the traits versus interfaces chapter here, and delete it.

## Understanding `&self`, `Self`, and References in Rust

This is a beginner-friendly section to help you remember how `&self`, `Self`, and references work in Rust. If you've just started exploring traits and methods, this should serve as a handy refresher.

---

## What is `&self`?

In Rust, `&self` is shorthand for `self: &Self`. It's used in method definitions to indicate that the function is a method that takes an **immutable reference** to the instance it's called on.

### Example:

```rust
struct MyType {
    value: i32,
}

impl MyType {
    fn show(&self) {
        println!("Value: {}", self.value);
    }
}
```

Here, `show` takes `&self`, which means it only *reads* from the instance and doesn’t modify it.

---

## What is `Self` (with capital S)?

`Self` refers to the **implementing type** in an `impl` block or a trait.

### Example in an `impl` block:

```rust
struct MyType;

impl MyType {
    fn new() -> Self {
        MyType
    }
}
```

Here, `Self` is `MyType`.

### Example in a trait:

```rust
trait Greeter {
    fn greet(&self);
}
```

When implemented for a type like `String`, `Self` becomes `String`.

```rust
impl Greeter for String {
    fn greet(&self) {
        println!("Hello from '{}'", self);
    }
}
```

---

## How Can You Have References in Function *Definitions*?

Rust lets you **declare** that a function takes a reference, but it doesn’t create the reference at definition time. The **caller** is responsible for passing the reference.

### Example:

```rust
fn print_num(n: &i32) {
    println!("{}", n);
}

fn main() {
    let x = 42;
    print_num(&x); // Caller creates the reference
}
```

The borrow checker ensures that:
- The reference points to valid data.
- It doesn't outlive the original data.
- It respects aliasing and mutability rules.

---

## Summary Table

| Syntax       | Meaning                                                  |
|--------------|----------------------------------------------------------|
| `&self`      | Borrowed immutable reference to the instance             |
| `&mut self`  | Borrowed mutable reference to the instance               |
| `Self`       | Refers to the implementing type (`MyType`, `X<T>`, etc.) |
| `&T`         | Reference to a value of type `T`, passed by the caller   |

---

## Final Tip

Remember: `self` is the instance, `Self` is the type, and `&` means you're borrowing, not owning.


