# Swift Async Testing

A Swift library built on top of swift-testing that provides a DSL for testing async sequences.

## Usage

Test async sequences using the `test` extension:

```swift
import AsyncTesting
import Testing

@Test
func testAsyncSequence() async {
    let sequence = AsyncStream { continuation in
        continuation.yield(1)
        continuation.yield(2)
        continuation.yield(3)
        continuation.finish()
    }

    await sequence.test {
        emit(1)
        emit(2)
        emit(3)
    }
}
```

## License

This project is licensed under the MIT License. See [LICENSE.txt](LICENSE.txt) for details.
