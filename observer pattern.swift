import Swift

protocol ObservableType {
    typealias ObserverType : Hashable
    
    mutating func registerObserver(observer: ObserverType, callback: Self -> ())
    mutating func removeObserver(observer: ObserverType)
    func postNotifications(_ : Self)

    var registrar : [ObserverType : Self -> ()] { get set }
}

extension ObservableType {
    mutating func registerObserver(observer: ObserverType, callback: Self -> ()) {
        registrar[observer] = callback
    }
    
    mutating func removeObserver(observer: ObserverType) {
        registrar.removeValueForKey(observer)
    }
    
    func postNotifications(s : Self) {
        for (_, callback) in self.registrar {
            callback(s)
        }
    }
}

protocol Employee : ObservableType {
    var name : String { get }
    
    var currentActivity : String { get set }
}

struct Developer : Employee {
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
