import Swift

protocol Observable {
	typealias Observer : Hashable
	typealias Invocation = (Self) -> ()
	var observers : [Observer : Invocation] { get set }

	func postNofitication()
}

struct Employee : Observable {
	typealias Invocation = (Employee) -> ()
	let name : String
	
	var currentActivity : String {
		didSet {
			postNofitication()
		}
	}

	var observers : [Manager : Invocation]
	
	func postNofitication() {
		for (_, invocation) in observers {
			invocation(self)
		}
	}
}

final class Manager : Hashable {
	func callback(e: Employee) {
		print("\(e.name) is \(e.currentActivity)")
	}
	
	var hashValue : Int {
		let pointer = unsafeAddressOf(self)
		return pointer.hashValue
	}
}

func ==(lhs: Manager, rhs: Manager) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

var alice = Manager()
let obs = [alice : alice.callback]
var bob = Employee(name: "Bob", currentActivity: "working on Core Metrics", observers: obs)

bob.currentActivity = "watching YouTube"
