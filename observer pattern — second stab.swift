protocol ObservableType {
	typealias ObserverType
	typealias EmitterType
	
	mutating func registerObserver(observer: ObserverType, callback: Self -> ()) -> EmitterType
	mutating func removeObserver(observer: ObserverType)
}

struct Emitter<T> {
	let observer : AnyObject
	let callback : T -> ()
}

struct Employee : ObservableType {
	let name : String
	
	var currentActivity : String {
		didSet {
			notifyObservers()
		}
	}
	
	private var emitters : [Emitter<Employee>] = []
	
	mutating func registerObserver(observer: AnyObject, callback: Employee -> ()) -> Emitter<Employee> {
		removeObserver(observer)
		let e = Emitter(observer: observer, callback: callback)
		emitters.append(e)
		return e
	}
	
	mutating func removeObserver(observer: AnyObject) {
		emitters = emitters.filter { e in
			return e.observer === observer
		}
	}
	
	func notifyObservers() {
		for e in emitters {
			e.callback(self)
		}
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
var bob = Employee(name: "Bob", currentActivity: "checking email", emitters: [])

bob.registerObserver(alice, callback: alice.checkInOnEmployee)

bob.currentActivity = "working on Core Metrics"
bob.currentActivity = "watching YouTube"
bob.currentActivity = "eating lunch"
