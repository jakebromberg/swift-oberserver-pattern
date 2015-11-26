import Swift

protocol ObservablePrototypePublic {
	typealias ObserverType
	
	mutating func registerObserver(observer: ObserverType, callback: Self -> ())
	mutating func removeObserver(observer: ObserverType)
	
	func postNotifications(_ : Self)
}

protocol ObservablePrototypePrivate {
	typealias RegistrationType : Hashable
	var registrar : [RegistrationType : Self -> ()] { get set }
}

extension ObservablePrototypePublic where Self : ObservablePrototypePrivate {
	mutating func registerObserver(observer: RegistrationType, callback: Self -> ()) {
		registrar[observer] = callback
	}
	
	mutating func removeObserver(observer: RegistrationType) {
		registrar.removeValueForKey(observer)
	}
	
	func postNotifications(s : Self) {
		for (_, callback) in self.registrar {
			callback(s)
		}
	}
}

typealias ObservableType = protocol<ObservablePrototypePublic, ObservablePrototypePrivate>

protocol Employee {
	var name : String { get }
	
	var currentActivity : String { get set }
}

struct Developer : Employee, ObservableType {
	let name : String
	var registrar : [ObjectIdentifier : Developer -> ()]
	
	var currentActivity : String {
		didSet {
			postNotifications(self)
		}
	}
}

final class Manager {
	let name : String
	
	func checkInOnEmployee<E : Employee>(e: E) {
		print("\(self.name) is checking in on \(e.name), who's \(e.currentActivity).")
	}
	
	init(name: String) {
		self.name = name
	}
}

let alice = Manager(name: "Alice")

var bob = Developer(name: "Bob", registrar: [:], currentActivity: "checking email")
bob.registerObserver(ObjectIdentifier(alice), callback: alice.checkInOnEmployee)

bob.currentActivity = "working on Core Metrics"
bob.currentActivity = "watching YouTube"
bob.currentActivity = "eating lunch"
bob.currentActivity = "Nerfing around"
