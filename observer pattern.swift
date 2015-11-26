import Swift

protocol ObservablePrototypePublic {
	typealias ObserverType
	
	mutating func registerObserver(observer: ObserverType, callback: Self -> ())
	mutating func removeObserver(observer: ObserverType)
	
	func postNotifications(_ : Self)
}

protocol ObservablePrototypeInternal {
	typealias RegistrationType : Hashable
	var registrar : [RegistrationType : Self -> ()] { get set }
}

extension ObservablePrototypePublic where Self : ObservablePrototypeInternal {
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

typealias ObservableType = protocol<ObservablePrototypePublic, ObservablePrototypeInternal>

protocol Employee {
	var name : String { get }
	
	var activity : String { get set }
}

struct Developer : Employee, ObservableType {
	let name : String
	var activity : String {
		didSet {
			postNotifications(self)
		}
	}
	
	internal var registrar : [ObjectIdentifier : Developer -> ()] = [:]
}

final class Manager {
	let name : String
	
	func micromanage(e: Employee) {
		print("\(self.name) is checking in on \(e.name), who's \(e.activity).")
	}
	
	init(name: String) {
		self.name = name
	}
}

let alice = Manager(name: "Alice")

var bob = Developer(name: "Bob", activity: "checking email", registrar: [:])
bob.registerObserver(ObjectIdentifier(alice), callback: alice.micromanage)

bob.activity = "working on Core Metrics"
bob.activity = "watching YouTube"
bob.activity = "eating lunch"
bob.activity = "Nerfing around"
