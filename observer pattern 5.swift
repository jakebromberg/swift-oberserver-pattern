protocol ObservableType {
    typealias ObserverType
    typealias ObserverRegistrationType
    
    var registrar : [ObserverRegistrationType] { get set }
    
    mutating func registerObserver(observer: ObserverType, callback: Self -> ())
    mutating func removeObserver(observer: ObserverType)
    func postNotifications(subject: Self)
}

struct ObserverRegistration<T> {
    let observer : AnyObject
    let callback : T -> ()
}

extension ObservableType where ObserverRegistrationType == ObserverRegistration<Self> {
    mutating func registerObserver(observer: AnyObject, callback: Self -> ()) {
        removeObserver(observer)
        let e = ObserverRegistration(observer: observer, callback: callback)
        registrar.append(e)
    }
    
    mutating func removeObserver(observer: AnyObject) {
        registrar = registrar.filter { e in
            return e.observer === observer
        }
    }
    
    func postNotifications(subject: Self) {
        for e in registrar {
            e.callback(subject)
        }
    }
}

extension ObservableType where ObserverType : Equatable, ObserverRegistrationType == (ObserverType, (Self) -> ())  {
    mutating func registerObserver(observer: ObserverType, callback: Self -> ()) {
        removeObserver(observer)
        registrar.append((observer, callback))
    }
    
    mutating func removeObserver(observer: ObserverType) {
        registrar = registrar.filter { (myObserver, _) in
            return myObserver == observer
        }
    }
    
    func postNotifications(subject: Self) {
        for (_, callback) in registrar {
            callback(subject)
        }
    }
}

protocol Employee : ObservableType {
    var name : String { get }

    var currentActivity : String { get set }
}

extension Employee {
    
}

class FTE : ObservableType {
    let name : String
    var registrar : [ObserverRegistration<FTE>]
    
    var currentActivity : String {
        didSet {
            postNotifications(self)
        }
    }
    
    init (name : String, registrar : [ObserverRegistration<FTE>], currentActivity : String) {
        self.name = name
        self.registrar = registrar
        self.currentActivity = currentActivity
    }
}

struct Contractor : Employee {
    typealias ObserverType = String
    
    let name : String
    var registrar : [(String, (Contractor) -> ())]
    
    var currentActivity : String {
        didSet {
            postNotifications(self)
        }
    }
}

final class Manager {
    let name : String
    
    func checkInOnEmployee(e: FTE) {
        print("\(self.name) is checking in on \(e.name), who's \(e.currentActivity).")
    }

    func checkInOnEmployee(e: Contractor) {
        print("\(self.name) is checking in on \(e.name), who's \(e.currentActivity).")
    }

    init(name: String) {
        self.name = name
    }
}

var bob = FTE(name: "Bob", registrar: [], currentActivity: "checking email")

let alice = Manager(name: "Alice")
bob.registerObserver(alice, callback: alice.checkInOnEmployee)

bob.currentActivity = "working on Core Metrics"
bob.currentActivity = "watching YouTube"
bob.currentActivity = "eating lunch"

var caroline = Contractor(name: "Caroline", registrar: [], currentActivity: "refactoring tickets")
caroline.registerObserver(alice.name, callback: alice.checkInOnEmployee)

caroline.currentActivity = "billing hours"