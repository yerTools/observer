import gleam/int
import gleam/io
import observer
import observer/reactive
import observer/stateful
import observer/topic

//pub fn main() {
pub fn run_all_observer_examples() {
  io.println("Running examples...")
  run_example("Simple Observer", simple_observer)
  run_example("Simple Observer with State", simple_observer_with_state)
  run_example("Reactive Observer", reactive_observer)
  run_example("Single topic-based Observer", single_topic)
  run_example("Multiple topic-based Observer", multiple_topics)
}

fn run_example(name: String, example: fn() -> Nil) {
  io.println("")
  io.println("Running example: " <> name)
  io.println("================")
  io.println("")
  example()
  io.println("")
  io.println("================")
}

/// A simple obeserver implementation.
/// This example demonstrates the basic usage of the observer library.
/// It is an easy way to use publishers and subscribers to handle events.
/// 
/// Outputs the following:
/// ```text
/// [1] | Received an event with value: 2
/// [2] | Received an event with value: 2
/// [1] | Received an event with value: 3
/// ```
fn simple_observer() {
  // Creates a new hub for distributing events.
  use hub <- observer.new()

  // Notifies all subscrivers of the hub that an event has occurred.
  observer.notify(hub, 1)

  // You can forward the hub to other functions or components.
  {
    // Using syntactic sugar for handling the callback.
    use value <- observer.subscribe(hub)

    // This function gets called when the hub receives an event.
    io.println("[1] | Received an event with value: " <> int.to_string(value))
  }

  // You can also subscribe using a normal callback function.
  // This also returns an unsubscribe function.
  let unsubscribe =
    observer.subscribe(hub, fn(value) {
      io.println("[2] | Received an event with value: " <> int.to_string(value))
    })

  // Notifies all subscribers of the hub that an event has occurred with the value `2`.
  // These notifications occur in parallel but notify waits for all of them to complete.
  observer.notify(hub, 2)

  // Unsubscribe if you no longer need to receive events.
  unsubscribe()

  // Notify again to demonstrate that the unsubscribe function works.
  observer.notify(hub, 3)
}

/// A simple stateful observer implementation.
/// This is like the previous example, but it uses a stateful observer.
/// 
/// Outputs the following:
/// ```text
/// Current state: initial state
/// Current state: test value
/// [1] | Received an event with value: test value
/// Current state: test value
/// [1] | Received an event with value: third event
/// [2] | Received an event with value: third event
/// [1] | Received an event with value: last one
/// ```
fn simple_observer_with_state() {
  // Creates a new hub for distributing events with an initial state.
  use hub <- stateful.new("initial state")

  // Gets the current state.
  let current_state = stateful.state(hub)
  io.println("Current state: " <> current_state)

  // Notifies all subscrivers of the hub that an event has occurred.
  stateful.notify(hub, "test value")

  // See that the state has changed.
  let current_state = stateful.state(hub)
  io.println("Current state: " <> current_state)

  // You can forward the hub to other functions or components.
  {
    // Using syntactic sugar for handling the callback.
    // With the second argument you can specify whether the callback should be called with the current state.
    use value <- stateful.subscribe(hub, True)

    // This function gets called when the hub receives an event.
    // In this case, it prints the current state, because the second argument was `True`.
    io.println("[1] | Received an event with value: " <> value)
  }

  // You can also subscribe using a normal callback function.
  // This also returns a tuple with the current state and an unsubscribe function.
  // The second argument specifies that the callback should not be called with the current state.
  let #(current_state, unsubscribe) =
    stateful.subscribe(hub, False, fn(value) {
      io.println("[2] | Received an event with value: " <> value)
    })

  // See that the state is still the same.
  io.println("Current state: " <> current_state)

  // Notifies all subscribers of the hub that an event has occurred with the value `"third event"`.
  // These notifications occur in parallel but notify waits for all of them to complete.
  stateful.notify(hub, "third event")

  // Unsubscribe if you no longer need to receive events.
  unsubscribe()

  // Notify again to demonstrate that the unsubscribe function works.
  stateful.notify(hub, "last one")
}

/// A simple reactive observer implementation.
/// This can be used to bradcast things that constantly change like the current time to clients.
/// Another use case would be to breadcast database updates to listeners.
/// 
/// Outputs the following:
/// ```text
/// [A] | Current time: 2024-05-21T16:30:00Z
/// [B] | Current time: 2024-05-21T16:30:00Z
/// [C] | Current time: 2024-05-21T16:30:00Z
/// [A] | Current time: 2024-05-21T16:30:00Z
/// [C] | Current time: 2024-05-21T16:30:00Z
/// ```
fn reactive_observer() {
  // This is a mockup of the current time function.
  // In a real application, you would use a real time function.
  let now = fn() { "2024-05-21T16:30:00Z" }

  // Creates a new hub for distributing events with a current time function.
  use time_hub <- reactive.new(now)

  // Subscribes to the hub to get notified when the current time changes.
  let unsubscribe_a =
    reactive.subscribe(time_hub, fn(value) {
      io.println("[A] | Current time: " <> value)
    })

  // This is another subscription to the hub.
  let unsubscribe_b =
    reactive.subscribe(time_hub, fn(value) {
      io.println("[B] | Current time: " <> value)
    })

  // Just another client.
  let unsubscribe_c =
    reactive.subscribe(time_hub, fn(value) {
      io.println("[C] | Current time: " <> value)
    })

  // Notifies all subscribers of the hub that the current time has changed.
  // This will call the provided function when the hub was created and broadcasts the return value.
  reactive.notify(time_hub)

  // Unsubscribes from the hub.
  unsubscribe_b()

  // Notifies all subscribers again.
  // If a real time function is used, the current time will be updated.
  reactive.notify(time_hub)

  // Unsubscribe all subscribers.
  unsubscribe_c()
  unsubscribe_a()
}

/// A simple topic-based observer implementation.
/// Topics can be used to organize and filter events.
/// 
/// Outputs the following:
/// ```text
/// [A] | Received an event with value: Hello A and C!
/// [C] | Received an event with value: Hello A and C!
/// [A] | Received an event with value: Hello all!
/// [B] | Received an event with value: Hello all!
/// [C] | Received an event with value: Hello all!
/// [A] | Received an event with value: Hello AB!
/// [B] | Received an event with value: Hello AB!
/// [A] | Received an event with value: Hello A, AB, B, C and all!
/// [B] | Received an event with value: Hello A, AB, B, C and all!
/// [C] | Received an event with value: Hello A, AB, B, C and all!
/// ```
fn single_topic() {
  use hub <- topic.new()

  // Creates a listener for the topics `"a"`, `"ab"` and `"*"`. 
  let unsubscribe_a =
    topic.subscribe(hub, ["a", "ab", "*"], fn(value) {
      io.println("[A] | Received an event with value: " <> value)
    })

  // Creates a listener for the topics `"b"`, `"ab"` and `"*"`.
  let unsubscribe_b =
    topic.subscribe(hub, ["b", "ab", "*"], fn(value) {
      io.println("[B] | Received an event with value: " <> value)
    })

  // Creates a listener for the topics `"c"` and `"*"`.
  let unsubscribe_c =
    topic.subscribe(hub, ["c", "*"], fn(value) {
      io.println("[C] | Received an event with value: " <> value)
    })

  // Notifies listeners with the topics `"a"` and `"c"`.
  topic.notify(hub, ["a", "c"], "Hello A and C!")

  // Notifies listeners with the topic `"*"`.
  topic.notify(hub, ["*"], "Hello all!")

  // Notifies listeners with the topic `"ab"`.
  topic.notify(hub, ["ab"], "Hello AB!")

  // Notifies listeners with the topics `"a"`, `"ab"`, `"b"`, `"c"` and `"*"`.
  topic.notify(hub, ["a", "ab", "b", "c", "*"], "Hello A, AB, B, C and all!")

  // Unsubscribe all listeners.
  unsubscribe_a()
  unsubscribe_b()
  unsubscribe_c()
}

/// Example of using multiple topics.
/// This can be used for advanced filtering and grouping of events.
/// A possible example would be to propagate database changes to listeners.
/// In this case the first topic would be the table name and the second topics could be the column names.
/// 
/// Outputs the following:
/// ```text
/// [User: name, age] | Received an event with value: John Doe
/// [User: name, age, email] | Received an event with value: John Doe
/// [User: name, age, email] | Received an event with value: john.doe@example.com
/// [User: name, age] | Received an event with value: Hello World!
/// [User: name, age, email] | Received an event with value: Hello World!
/// ```
fn multiple_topics() {
  use hub <- topic.new2()

  // Creates a listener for the `"user"` table and the columns `"name"` and `"age"`.
  let unsubscribe_user_name_age =
    topic.subscribe2(hub, ["user"], ["name", "age", "*"], fn(value) {
      io.println("[User: name, age] | Received an event with value: " <> value)
    })

  // Creates a listener for the `"user"` table and the column `"name"`, `"age"` and `"email"`.
  let unsubscribe_user_details =
    topic.subscribe2(hub, ["user"], ["name", "age", "email", "*"], fn(value) {
      io.println(
        "[User: name, age, email] | Received an event with value: " <> value,
      )
    })

  // Update the user name
  topic.notify2(hub, ["user"], ["name"], "John Doe")

  // Update the user email
  topic.notify2(hub, ["user"], ["email"], "john.doe@example.com")

  // Add a new user
  topic.notify2(hub, ["user"], ["*"], "Hello World!")

  unsubscribe_user_name_age()
  unsubscribe_user_details()
}
