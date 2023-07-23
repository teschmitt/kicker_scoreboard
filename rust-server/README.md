# Kicker Scoreboard Server (Rust implementation)

This project was created with the help of the [esp-idf-template](https://github.com/esp-rs/esp-idf-template) and mirrors the behavior of the [original server](../server/sketch_kicker/) ... just using Rust.

BLE goal server is heavily inspired by [this example](https://github.com/taks/esp32-nimble/blob/develop/examples/ble_server.rs).

## Building

Just follow the [Prereqs section](https://github.com/esp-rs/esp-idf-template#prerequisites) in the esp-idf-template repo and then:

```shell
cargo build
espflash flash target/xtensa-esp32-espidf/debug/kicker-server
espflash monitor
```

or for a more seamless experience:

```shell
cargo run
```

## Dependencies

- [NimBLE Rust wrapper for ESP32](https://github.com/taks/esp32-nimble)

And that's it for now

## Todos

- [x] create GoalSender trait to abstract away method of sending goal events
- [ ] implement MQTT goal monitor
