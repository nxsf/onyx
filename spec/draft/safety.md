# Safety

Fragile is a defined behavior ONLY in non-multithreaded context.
Otherwise it becomes undefined leading to data races and corrupted memory.
