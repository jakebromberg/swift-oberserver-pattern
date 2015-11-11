protocol ObservableType {
	typealias ObserverType
	typealias SubjectType
	typealias NotificationType

	mutating func registerObserver(observer: ObserverType, callback: SubjectType -> ()) -> NotificationType
	mutating func removeObserver(observer: ObserverType)
}

struct Notification<T> {
	let observer : AnyObject
	let callback : T -> ()
}

struct Emitter<T> : ObservableType {
	private var emitters : [Notification<T>] = []
	
	mutating func registerObserver(observer: AnyObject, callback: T -> ()) -> Notification<T> {
		removeObserver(observer)
		let e = Notification(observer: observer, callback: callback)
		emitters.append(e)
		return e
	}
	
	mutating func removeObserver(observer: AnyObject) {
		emitters = emitters.filter { e in
			return e.observer === observer
		}
	}
	
	func postNotifications(subject: T) {
		for e in emitters {
			e.callback(subject)
		}
	}
}

struct Employee {
	let name : String
	var emitter : Emitter<Employee>
	
	var currentActivity : String {
		didSet {
			emitter.postNotifications(self)
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
var bob = Employee(name: "Bob", emitter: Emitter<Employee>(), currentActivity: "checking email")

bob.emitter.registerObserver(alice, callback: alice.checkInOnEmployee)

bob.currentActivity = "working on Core Metrics"
bob.currentActivity = "watching YouTube"
bob.currentActivity = "eating lunch"
