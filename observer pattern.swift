import Swift

protocol Observable {
	typealias Invocation = (Self) -> ()
	
	mutating func registerObserver(observer: AnyObject, callback : (Self) -> ())
	mutating func removeObserver(observer: AnyObject)

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

	private var observers : [(AnyObject, (Employee) -> ())] = []
	
	mutating func registerObserver(observer: AnyObject, callback: Invocation) {
		removeObserver(observer)
		observers.append((observer, callback))
	}
	
	mutating func removeObserver(observer: AnyObject) {
		self.observers = self.observers.filter { (registeredObserver, _) in
			return registeredObserver === observer
		}
	}

	func postNofitication() {
		for (_, invocation) in observers {
			invocation(self)
		}
	}
	
	init(name: String, currentActivity: String) {
		self.name = name
		self.currentActivity = currentActivity
	}
}

final class Manager {
	let name : String
	
	func checkInOnEmployee(e: Employee) {
		print("\(self.name) is checking in on \(e.name), who's \(e.currentActivity).")
	}
	
	init(name: String) {
		self.name = name
	}
}

var alice = Manager(name: "Alice")
var bob = Employee(name: "Bob", currentActivity: "working on Core Metrics")

bob.registerObserver(alice, callback: alice.checkInOnEmployee)

bob.currentActivity = "watching YouTube"
