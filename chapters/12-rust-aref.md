## ARef: The “Abstract Reference” for Rust

I understand references, Rc and Arc. But what the heck is ARef and why would I need one?

### 1. The problem: juggling multiple return types  
Imagine you have a function that sometimes:

- Returns a **borrowed** `&str` (no heap allocation)  
- Returns an **owned** `String` you just built  
- Returns a **shared** buffer (e.g. an `Rc<String>`) without copying  

In plain Rust you’d end up with a messy mix:

(Borrowed from the rust docs):
```rust
fn foo(idx: u32) -> ?? {
    if idx == 0 {
        // &str
    } else if idx == 1 {
        // String
    } else {
        // Rc<String>
    }
}
```

What can `??` be? You’d need an `enum` (boilerplate!), or force every caller to deal with **three** different types, or always allocate a new `String` (wasteful).

---

### 2. Enter `ARef<T>`  
`ARef<U>` (from the [reffers] crate) is an **Abstract Reference**. It can **own**, **share**, or **borrow** data—yet always behaves like a simple `&U` when you use it.  

- **Borrowed**: wraps a `&U` (e.g. `&str`)  
- **Owned**: owns a fresh `U` (e.g. `String`)  
- **Shared**: keeps an `Rc<U>` alive  

All of those internally implement `Deref<Target=U>`, so you can do `&*aref` (or `.as_ref()`) to get a `&U`.

---

### 3. How you construct an `ARef`

| Case               | Code                                   | What happens                          |
|--------------------|----------------------------------------|---------------------------------------|
| **Borrowed**       | `"hi!".into()`                         | Uses `From<&str>` → no heap alloc     |
| **Owned**          | `format!("{}!", 42).into()`            | Uses `From<String>` → owns the string |
| **Shared**         | `ARef::new(rc.clone())`                | Holds an `Rc` under the hood          |

And if you ever start with an `ARef<T>` but need an `&U` where `U` is not exactly `T` (e.g. `String → str`), call:

```rust
aref.map(|s| s.as_str())
```

---

### 4. A complete mini-example

```rust
use std::rc::Rc;
use reffers::ARef;

fn idx_to_str(idx: u32, shared: Rc<String>) -> ARef<str> {
    match idx {
        0 => "Go!".into(),                      // Borrowed &str
        1 => ARef::new(shared.clone())
                 .map(|s| s.as_str()),         // Shared Rc<String> → &str
        _ => format!("{}...", idx).into(),     // Owned String → &str
    }
}

fn main() {
    let shared = Rc::new("Ready!".to_string());
    assert_eq!(&*idx_to_str(0, shared.clone()), "Go!");
    assert_eq!(&*idx_to_str(1, shared.clone()), "Ready!");
    assert_eq!(&*idx_to_str(2, shared.clone()), "2...");
}
```

- **Zero allocations** for `idx == 0`  
- **One ref-count bump** (cheap) for `idx == 1`  
- **One allocation** for any other `idx`

---

### 5. Why it matters

- **Clean API**  
  Callers always get back `ARef<U>`. No enums, no generics galore, no boilerplate.

- **Performance**  
  You only allocate or clone when you really need to. Borrow or reuse otherwise.

- **Flexibility**  
  Your function can evolve: add new cases, change caching strategies, etc., without breaking its signature.

---

So as you can see, ARef just makes things easy when you need to return SOME reference to T from a function, but don't know which "type of" reference of T yet, and don't want the caller to bother having to know.

Keep this as a quick reference whenever you find yourself balancing borrowed, owned, and shared data in the same API. With `ARef<T>` you get the best of **all three worlds**—and a lot less boilerplate!
