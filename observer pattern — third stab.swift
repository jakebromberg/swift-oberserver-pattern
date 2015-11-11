// Attempting mixins with a protocol extension

protocol ObservableType {
	typealias ObserverType
	typealias NotificationType
	
	var notifications : [NotificationType] { get set }
	
	mutating func registerObserver(observer: ObserverType, callback: Self -> ())
	mutating func removeObserver(observer: ObserverType)
	func postNotifications(subject: Self)
}

extension ObservableType where NotificationType == Notification<Self> {
	mutating func registerObserver(observer: AnyObject, callback: Self -> ()) {
		removeObserver(observer)
		let e = Notification(observer: observer, callback: callback)
		notifications.append(e)
	}
	
	mutating func removeObserver(observer: AnyObject) {
		notifications = notifications.filter { e in
			return e.observer === observer
		}
	}
	
	func postNotifications(subject: Self) {
		for e in notifications {
			e.callback(subject)
		}
	}
}

struct Notification<T> {
	let observer : AnyObject
	let callback : T -> ()
}

struct Employee : ObservableType {
	let name : String
	var notifications : [Notification<Employee>]
	
	var currentActivity : String {
		didSet {
			postNotifications(self)
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
var bob = Employee(name: "Bob", notifications: [], currentActivity: "checking email")

bob.registerObserver(alice, callback: alice.checkInOnEmployee)

bob.currentActivity = "working on Core Metrics"
bob.currentActivity = "watching YouTube"
bob.currentActivity = "eating lunch"
