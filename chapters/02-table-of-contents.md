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

\pagebreak
